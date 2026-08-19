import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../services/delivery_service.dart';

class StopDetailScreen extends StatefulWidget {
  final String batchId;
  final Map<String, dynamic> stop;
  final bool isPickupConfirmed;

  const StopDetailScreen({
    super.key,
    required this.batchId,
    required this.stop,
    required this.isPickupConfirmed,
  });

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  List<Offset> _sigPoints = [];
  bool _photoCaptured = false;
  bool _confirmingDelivery = false;
  String? _geofenceError;
  bool _paymentConfirmed = false;

  @override
  void initState() {
    super.initState();
    final paymentMethod = widget.stop['paymentMethod']?.toString().toUpperCase() ?? 'COD';
    if (paymentMethod == 'ONLINE') {
      _paymentConfirmed = true;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Radius of Earth in km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<void> _submitDelivery(String status, {String? issueReason, String? otp}) async {
    setState(() {
      _confirmingDelivery = true;
      _geofenceError = null;
    });

    try {
      final rLat = double.tryParse(widget.stop['latitude']?.toString() ?? '0') ?? 0;
      final rLng = double.tryParse(widget.stop['longitude']?.toString() ?? '0') ?? 0;

      // Geofence check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied. GPS coordinates required.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distanceKm = _calculateDistance(position.latitude, position.longitude, rLat, rLng);
      final distanceMeters = distanceKm * 1000;

      if (distanceMeters > 500) {
        setState(() {
          _geofenceError = 'You are ${distanceMeters.toStringAsFixed(0)}m away from ${widget.stop['retailerName']}. You must be within 500m to confirm delivery.';
          _confirmingDelivery = false;
        });
        return;
      }

      if (!mounted) return;

      // Geofence pass -> confirm POD
      await context.read<DeliveryService>().confirmPOD(
        batchId: widget.batchId,
        orderId: widget.stop['id'],
        lat: position.latitude,
        lng: position.longitude,
        status: status,
        issueReason: issueReason,
        signatureData: _sigPoints.isNotEmpty ? 'signature_captured' : null,
        photoData: _photoCaptured ? 'photo_captured' : null,
        otp: otp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'delivered' ? '🎉 Order Delivered!' : '⚠️ Order marked failed'),
            backgroundColor: status == 'delivered' ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _geofenceError = 'Geofence Check Failed: $e';
        _confirmingDelivery = false;
      });
      rethrow;
    } finally {
      setState(() => _confirmingDelivery = false);
    }
  }

  void _bypassGeofence(String status, {String? issueReason, String? otp}) async {
    try {
      await context.read<DeliveryService>().confirmPOD(
        batchId: widget.batchId,
        orderId: widget.stop['id'],
        lat: 0.0,
        lng: 0.0,
        status: status,
        issueReason: issueReason,
        signatureData: _sigPoints.isNotEmpty ? 'signature_captured' : null,
        photoData: _photoCaptured ? 'photo_captured' : null,
        otp: otp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ Delivery confirmed (Geofence Bypassed)'), backgroundColor: Colors.amber),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOtpVerificationDialog() {
    final expectedOtp = widget.stop['deliveryOtp'] ?? ((widget.stop['id'].toString().hashCode % 9000) + 1000).toString();
    final TextEditingController otpCtrl = TextEditingController();
    String? localError;
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF2874F0)),
              const SizedBox(width: 8),
              Text(
                'Delivery OTP Verification',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask the retailer for the 4-digit delivery verification OTP displayed on their order screen.',
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 11, height: 1.35),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: false,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0000',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade300, letterSpacing: 6),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2874F0), width: 1.5),
                  ),
                ),
              ),
              if (localError != null) ...[
                const SizedBox(height: 12),
                Text(
                  localError!,
                  style: GoogleFonts.inter(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2874F0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      final val = otpCtrl.text.trim();
                      if (val.length != 4) {
                        setDialogState(() {
                          localError = 'Please enter a valid 4-digit OTP.';
                        });
                        return;
                      }

                      setDialogState(() {
                        loading = true;
                        localError = null;
                      });

                      // Double check locally if mock mode, or let the backend verify
                      final useMock = DeliveryService.useMockData;
                      if (useMock && val != expectedOtp.toString()) {
                        setDialogState(() {
                          localError = 'Invalid OTP code. Please check with the retailer.';
                          loading = false;
                        });
                        return;
                      }

                      try {
                        // Submit delivery
                        await _submitDelivery('delivered', otp: val);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext); // Close dialog on success
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            localError = e.toString().replaceAll('Exception: ', '').replaceAll('BadRequestException: ', '');
                            loading = false;
                          });
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Verify & Deliver',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpiQrBottomSheet(double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              'UPI Scan & Pay QR Code',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF212121)),
            ),
            const SizedBox(height: 4),
            Text(
              'Amount to pay: ₹$amount',
              style: GoogleFonts.inter(color: const Color(0xFF388E3C), fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            
            // Styled simulated QR Code using custom paint
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: CustomPaint(
                painter: QrCodePainter(),
              ),
            ),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2874F0), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Supports BHIM, Google Pay, PhonePe, Paytm, UPI',
                  style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2874F0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _paymentConfirmed = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 UPI payment verified! Cash collection completed.'), backgroundColor: Colors.green),
                  );
                },
                child: Text(
                  'Verify UPI Payment Succeeded',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExceptionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final issues = [
          'Retailer not available',
          'Goods damaged',
          'Quantity mismatch',
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report Exception',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF212121)),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a reason for delivery failure:',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...issues.map((issue) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade100),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _submitDelivery('failed', issueReason: issue);
                  },
                  child: Text(
                    issue,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final retailerName = widget.stop['retailerName'] ?? 'Retailer';
    final address = widget.stop['address'] ?? '-';
    final amount = widget.stop['totalAmount'];
    final deliveryStatus = widget.stop['deliveryStatus'] as String? ?? 'pending';

    final podReady = _photoCaptured || _sigPoints.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          'Stop Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Retailer Stop Meta Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RETAILER STOP',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF878787),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '₹$amount',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF388E3C),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    retailerName,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF212121),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const Divider(height: 24),
                  // Navigation & Call actions
                  Row(
                    children: [
                      // Navigate Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2874F0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Navigating via Google Maps deep link...'),
                                backgroundColor: Color(0xFF2874F0),
                              ),
                            );
                          },
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text(
                            'Navigate',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Call button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF212121)),
                          foregroundColor: const Color(0xFF212121),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling Retailer: ${widget.stop['phone']}'),
                              backgroundColor: const Color(0xFF2874F0),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: Text(
                          'Call',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Verification Card (Flipkart style)
            () {
              final paymentMethod = widget.stop['paymentMethod']?.toString().toUpperCase() ?? 'COD';
              final isCod = paymentMethod == 'COD';
              
              if (isCod) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4), // HSL Yellow/Amber
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFF59D)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_rounded, color: Color(0xFFE65100), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CASH ON DELIVERY (COD)',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE65100),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Amount to Collect:',
                        style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹$amount',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE65100),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2874F0)),
                              foregroundColor: const Color(0xFF2874F0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showUpiQrBottomSheet(double.tryParse(amount.toString()) ?? 0),
                            icon: const Icon(Icons.qr_code_rounded, size: 14),
                            label: Text(
                              'Show UPI QR',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      CheckboxListTile(
                        value: _paymentConfirmed,
                        onChanged: (val) {
                          setState(() {
                            _paymentConfirmed = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFF388E3C),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Confirm Cash / UPI Received',
                          style: GoogleFonts.inter(
                            color: _paymentConfirmed ? const Color(0xFF388E3C) : const Color(0xFF212121),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          'Must collect cash or UPI scan before delivering.',
                          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Light green background
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF388E3C), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PREPAID ORDER (ONLINE)',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Payment of ₹$amount was completed online. Do not collect any cash.',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            }(),
            const SizedBox(height: 16),

            if (!widget.isPickupConfirmed) ...[
              // Pickup Warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Warning: You must confirm wholesaler pickup before completing retailer deliveries.',
                        style: GoogleFonts.inter(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (deliveryStatus == 'pending') ...[
              Text(
                'PROOF OF DELIVERY (POD)',
                style: GoogleFonts.inter(
                  color: const Color(0xFF878787),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              
              // Camera Proof Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Photo Proof',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF212121)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _photoCaptured
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                // Mock cargo delivery photo
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=600&auto=format&fit=crop',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Captured: Mock Cargo Box',
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 9),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, color: Colors.grey.shade400, size: 36),
                                  const SizedBox(height: 6),
                                  Text(
                                    'No photo captured yet',
                                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: const Color(0xFF212121),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() => _photoCaptured = !_photoCaptured);
                        },
                        icon: Icon(_photoCaptured ? Icons.delete_outline : Icons.camera_alt, size: 16),
                        label: Text(
                          _photoCaptured ? 'Remove Photo' : 'Capture Proof Photo',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Signature Pad Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Retailer Digital Signature',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF212121)),
                        ),
                        if (_sigPoints.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                            onPressed: () {
                              setState(() => _sigPoints.clear());
                            },
                            child: Text(
                              'Clear',
                              style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SignaturePad(
                          onChanged: (pts) {
                            setState(() {
                              _sigPoints = List.from(pts);
                            });
                          },
                          points: _sigPoints,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_geofenceError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _geofenceError!,
                              style: GoogleFonts.inter(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => _bypassGeofence('delivered'),
                        icon: const Icon(Icons.offline_bolt_rounded, size: 14),
                        label: const Text('Bypass Geofence (Dev Tool)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              // Actions buttons
              Row(
                children: [
                  // Exception Report
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: !widget.isPickupConfirmed ? null : _showExceptionModal,
                        child: Text(
                          'Issue',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Complete Delivery
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (podReady && _paymentConfirmed) ? const Color(0xFFFFC200) : Colors.grey.shade300,
                          foregroundColor: const Color(0xFF212121),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: (!podReady || !_paymentConfirmed || !widget.isPickupConfirmed || _confirmingDelivery)
                            ? null
                            : _showOtpVerificationDialog,
                        child: _confirmingDelivery
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF212121)))
                            : Text(
                                'Mark Delivered',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Delivery Complete Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    Icon(
                      deliveryStatus == 'delivered' ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: deliveryStatus == 'delivered' ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      deliveryStatus == 'delivered' ? 'DELIVERY COMPLETED' : 'DELIVERY FAILED',
                      style: GoogleFonts.inter(
                        color: deliveryStatus == 'delivered' ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (widget.stop['issueReason'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${widget.stop['issueReason']}',
                        style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2874F0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Batch',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SignaturePad extends StatefulWidget {
  final ValueChanged<List<Offset>> onChanged;
  final List<Offset> points;
  const SignaturePad({super.key, required this.onChanged, required this.points});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.globalPosition);
        final pts = List<Offset>.from(widget.points)..add(localPos);
        widget.onChanged(pts);
      },
      onPanEnd: (_) {
        final pts = List<Offset>.from(widget.points)..add(Offset.infinite);
        widget.onChanged(pts);
      },
      child: CustomPaint(
        painter: SignaturePainter(points: widget.points),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2874F0)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;

    // Draw finder patterns (top-left, top-right, bottom-left)
    _drawFinderPattern(canvas, const Offset(0, 0), 45, paint);
    _drawFinderPattern(canvas, Offset(size.width - 45, 0), 45, paint);
    _drawFinderPattern(canvas, Offset(0, size.height - 45), 45, paint);

    // Draw random simulated data pixels
    final rand = Random(42); // Seeded random for consistent look
    const numCells = 21;
    final cellSize = size.width / numCells;

    for (int r = 0; r < numCells; r++) {
      for (int c = 0; c < numCells; c++) {
        // Skip finder patterns
        if ((r < 7 && c < 7) || (r < 7 && c >= numCells - 7) || (r >= numCells - 7 && c < 7)) {
          continue;
        }
        // Randomly draw a pixel
        if (rand.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, Offset offset, double size, Paint paint) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, size, size), paint);
    // Inner white square
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final margin = size / 7;
    canvas.drawRect(
      Rect.fromLTWH(offset.dx + margin, offset.dy + margin, size - margin * 2, size - margin * 2),
      whitePaint,
    );
    // Center square
    final centerMargin = margin * 2;
    canvas.drawRect(
      Rect.fromLTWH(offset.dx + centerMargin, offset.dy + centerMargin, size - centerMargin * 2, size - centerMargin * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
