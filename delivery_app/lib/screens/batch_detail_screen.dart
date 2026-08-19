import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'dart:async';
import '../services/delivery_service.dart';
import 'stop_detail_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;
  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  bool _checkingGeofence = false;
  String? _geofenceError;

  bool _isRealDuty = false;
  StreamSubscription<Position>? _gpsSubscription;
  double _realLat = 0.0;
  double _realLng = 0.0;
  final MapController _mapController = MapController();
  bool _isSimulating = false;
  Timer? _simTimer;
  double _simLat = 0.0;
  double _simLng = 0.0;
  double _simProgress = 0.0;
  String _nextStopName = '';
  int _simStep = 0;
  final int _totalSteps = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryService>().fetchBatchDetails(widget.batchId);
    });
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

  Future<void> _handlePickup(Map<String, dynamic> batch) async {
    setState(() {
      _checkingGeofence = true;
      _geofenceError = null;
    });

    try {
      final wholesaler = batch['wholesaler'];
      final wLat = double.tryParse(wholesaler['latitude']?.toString() ?? '0') ?? 0;
      final wLng = double.tryParse(wholesaler['longitude']?.toString() ?? '0') ?? 0;

      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied. Please enable GPS permissions.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distanceKm = _calculateDistance(position.latitude, position.longitude, wLat, wLng);
      final distanceMeters = distanceKm * 1000;

      if (distanceMeters > 500) {
        setState(() {
          _geofenceError = 'You are ${distanceMeters.toStringAsFixed(0)}m away from ${wholesaler['businessName']}. You must be within 500m to confirm pickup.';
          _checkingGeofence = false;
        });
        return;
      }

      if (!mounted) return;

      // Geofence success -> mark picked up
      await context.read<DeliveryService>().markPickedUp(widget.batchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📦 Batch Picked Up Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _geofenceError = 'Geofence Check Failed: $e';
        _checkingGeofence = false;
      });
    } finally {
      setState(() => _checkingGeofence = false);
    }
  }

  void _bypassGeofence() async {
    await context.read<DeliveryService>().markPickedUp(widget.batchId);
    setState(() {
      _geofenceError = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚡ Wholesaler pickup confirmed (Geofence Bypassed)'), backgroundColor: Colors.amber),
      );
    }
  }

  void _toggleRealDuty(Map<String, dynamic> batch) {
    if (_isRealDuty) {
      _stopRealDuty();
    } else {
      _startRealDuty(batch);
    }
  }

  Future<void> _startRealDuty(Map<String, dynamic> batch) async {
    _stopSimulation();

    setState(() {
      _checkingGeofence = true;
      _geofenceError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('GPS permission denied. Location streaming requires GPS permissions.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _realLat = position.latitude;
        _realLng = position.longitude;
        _isRealDuty = true;
        _checkingGeofence = false;
      });

      if (!mounted) return;
      // Mark in transit on backend
      await context.read<DeliveryService>().markInTransit(widget.batchId);

      _gpsSubscription?.cancel();
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) async {
        if (!mounted) return;
        setState(() {
          _realLat = pos.latitude;
          _realLng = pos.longitude;
        });

        // Center map on real agent position
        _mapController.move(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);

        try {
          await context.read<DeliveryService>().updateLocation(
            pos.latitude,
            pos.longitude,
            batchId: widget.batchId,
          );
        } catch (e) {
          debugPrint('Failed to send real-world location: $e');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚴 Real-World Duty Mode Started! Tracking GPS...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _geofenceError = 'Duty Mode Start Failed: $e';
        _checkingGeofence = false;
        _isRealDuty = false;
      });
    }
  }

  void _stopRealDuty() {
    _gpsSubscription?.cancel();
    setState(() {
      _isRealDuty = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛑 Real-World Duty Mode Stopped.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSimulation(Map<String, dynamic> batch) {
    if (_isSimulating) {
      _stopSimulation();
    } else {
      _startSimulation(batch);
    }
  }

  void _startSimulation(Map<String, dynamic> batch) {
    final stopsList = batch['orders'] as List? ?? [];
    final nextStop = stopsList.firstWhere(
      (s) => (s['deliveryStatus'] as String? ?? 'pending') == 'pending',
      orElse: () => null,
    );

    if (nextStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All stops completed. Nothing to simulate!'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final wholesaler = batch['wholesaler'] as Map<String, dynamic>? ?? {};
    final wLat = double.tryParse(wholesaler['latitude']?.toString() ?? '0') ?? 0.0;
    final wLng = double.tryParse(wholesaler['longitude']?.toString() ?? '0') ?? 0.0;

    final destLat = double.tryParse(nextStop['latitude']?.toString() ?? '0') ?? 0.0;
    final destLng = double.tryParse(nextStop['longitude']?.toString() ?? '0') ?? 0.0;

    setState(() {
      _isSimulating = true;
      _nextStopName = nextStop['retailerName'] ?? 'Retailer';
      _simStep = 0;
      _simProgress = 0.0;
      if (_simLat == 0.0 || _simLng == 0.0) {
        _simLat = wLat;
        _simLng = wLng;
      }
    });

    final startLat = _simLat;
    final startLng = _simLng;

    // Mark batch + all orders as IN_TRANSIT ("Out for Delivery") — service handles mock/real internally
    context.read<DeliveryService>().markInTransit(widget.batchId);

    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _simStep++;
        _simProgress = _simStep / _totalSteps;
        if (_simProgress >= 1.0) {
          _simProgress = 1.0;
          _simLat = destLat;
          _simLng = destLng;
          _isSimulating = false;
          timer.cancel();
          _showArrivalNotification();
        } else {
          _simLat = startLat + (destLat - startLat) * _simProgress;
          _simLng = startLng + (destLng - startLng) * _simProgress;
        }
      });

      // Center map on simulated position
      _mapController.move(LatLng(_simLat, _simLng), _mapController.camera.zoom);

      try {
        await context.read<DeliveryService>().updateLocation(
          _simLat,
          _simLng,
          batchId: widget.batchId,
        );
      } catch (e) {
        debugPrint('Failed to send simulation location update: $e');
      }
    });
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    setState(() {
      _isSimulating = false;
    });
  }

  void _showArrivalNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Arrived at $_nextStopName! You can now verify delivery.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildGpsSimulatorCard(Map<String, dynamic> batch) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E6FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2874F0).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Color(0xFF2874F0), size: 20),
              const SizedBox(width: 8),
              Text(
                _isRealDuty ? 'REAL-WORLD DUTY TRACKING' : 'GPS ROUTE SIMULATOR',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2874F0),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_isSimulating || _isRealDuty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isRealDuty ? 'REAL GPS LIVE' : 'SIM LIVE',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2ECC71),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isRealDuty
                ? 'Streaming your real-world GPS coordinates to the retailer app live.'
                : _isSimulating
                    ? 'Simulating transit to: $_nextStopName'
                    : 'Choose your delivery mode: Simulate route movement or start real-world GPS tracking.',
            style: GoogleFonts.inter(
              color: const Color(0xFF212121),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isSimulating) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _simProgress,
              backgroundColor: Colors.grey.shade100,
              color: const Color(0xFF2874F0),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // Simulation Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSimulating ? Colors.red.shade50 : const Color(0xFF2874F0),
                    foregroundColor: _isSimulating ? Colors.red : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: _isRealDuty ? null : () => _toggleSimulation(batch),
                  icon: Icon(_isSimulating ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 16),
                  label: Text(
                    _isSimulating ? 'Stop Sim' : 'Simulation',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Real-World Duty Button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRealDuty ? Colors.red.shade50 : const Color(0xFF388E3C),
                    foregroundColor: _isRealDuty ? Colors.red : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: _isSimulating ? null : () => _toggleRealDuty(batch),
                  icon: Icon(_isRealDuty ? Icons.portable_wifi_off_rounded : Icons.wifi_tethering_rounded, size: 16),
                  label: Text(
                    _isRealDuty ? 'Stop Duty' : 'Go On Duty',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchRouteMap(Map<String, dynamic> batch) {
    final wholesaler = batch['wholesaler'] as Map<String, dynamic>? ?? {};
    final wLat = double.tryParse(wholesaler['latitude']?.toString() ?? '0') ?? 12.9105;
    final wLng = double.tryParse(wholesaler['longitude']?.toString() ?? '0') ?? 77.6450;
    final wPoint = LatLng(wLat, wLng);

    final stopsList = batch['orders'] as List? ?? [];
    
    // Create list of stop points
    final List<LatLng> points = [wPoint];
    final List<Marker> markers = [
      // Wholesaler marker (blue)
      Marker(
        point: wPoint,
        width: 40,
        height: 40,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2874F0),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
        ),
      ),
    ];

    for (int i = 0; i < stopsList.length; i++) {
      final stop = stopsList[i];
      final sLat = double.tryParse(stop['latitude']?.toString() ?? '0') ?? 0.0;
      final sLng = double.tryParse(stop['longitude']?.toString() ?? '0') ?? 0.0;
      if (sLat != 0.0 && sLng != 0.0) {
        final stopPoint = LatLng(sLat, sLng);
        points.add(stopPoint);
        
        final deliveryStatus = stop['deliveryStatus'] as String? ?? 'pending';
        final isDelivered = deliveryStatus == 'delivered';
        final isFailed = deliveryStatus == 'failed';
        
        Color stopBgColor = const Color(0xFFFF9800); // Orange for pending
        if (isDelivered) {
          stopBgColor = const Color(0xFF2ECC71); // Green
        } else if (isFailed) {
          stopBgColor = const Color(0xFFE74C3C); // Red
        }

        markers.add(
          Marker(
            point: stopPoint,
            width: 32,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                color: stopBgColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Agent live position marker
    LatLng? agentPoint;
    if (_isSimulating && _simLat != 0.0 && _simLng != 0.0) {
      agentPoint = LatLng(_simLat, _simLng);
    } else if (_isRealDuty && _realLat != 0.0 && _realLng != 0.0) {
      agentPoint = LatLng(_realLat, _realLng);
    }

    if (agentPoint != null) {
      markers.add(
        Marker(
          point: agentPoint,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    // Determine initial center
    final centerPoint = agentPoint ?? wPoint;

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: 14.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.zonesupply.delivery',
            ),
            if (points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 3,
                    color: const Color(0xFF2874F0).withAlpha(180),
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DeliveryService>();
    final batch = ds.getBatchDetails(widget.batchId);
    if (batch.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Batch Details',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2874F0)),
        ),
      );
    }
    final status = batch['status'] as String? ?? 'created';
    final wholesaler = batch['wholesaler'];
    final stopsList = batch['orders'] as List? ?? [];

    String statusText = 'Waiting for Pickup';
    Color statusColor = const Color(0xFFF1C40F);
    if (status == 'picked_up') {
      statusText = 'Picked Up';
      statusColor = const Color(0xFF2874F0);
    } else if (status == 'in_transit') {
      statusText = 'Out for Delivery';
      statusColor = const Color(0xFFFF9800);
    } else if (status == 'completed') {
      statusText = 'Completed';
      statusColor = const Color(0xFF2ECC71);
    }

    final displayId = widget.batchId.length > 6
        ? widget.batchId.substring(widget.batchId.length - 6).toUpperCase()
        : widget.batchId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          'Batch #$displayId',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Wholesaler Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PICKUP POINT',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF878787),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  wholesaler['businessName'] ?? 'Wholesaler',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wholesaler['address'] ?? '-',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Call Wholesaler Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2874F0)),
                          foregroundColor: const Color(0xFF2874F0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling Wholesaler: ${wholesaler['phone']}'),
                              backgroundColor: const Color(0xFF2874F0),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: Text(
                          'Call Wholesaler',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                if (status == 'created') ...[
                  const SizedBox(height: 12),
                  // Confirm Pickup Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC200),
                        foregroundColor: const Color(0xFF212121),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _checkingGeofence ? null : () => _handlePickup(batch),
                      icon: _checkingGeofence
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF212121)))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        'Confirm Wholesaler Pickup',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                  if (_geofenceError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
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
                            onPressed: _bypassGeofence,
                            icon: const Icon(Icons.offline_bolt_rounded, size: 14),
                            label: const Text('Bypass Geofence (Dev Tool)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          // Route sequence map
          _buildBatchRouteMap(batch),

          if (status == 'picked_up' || status == 'in_transit') ...[
            _buildGpsSimulatorCard(batch),
          ],
          const SizedBox(height: 10),
          // Retailer Stops Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  'DELIVERY SEQUENCE Stops',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF878787),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${stopsList.length} Retailer Stops',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF878787),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Stops List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: stopsList.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final stop = stopsList[idx];
                final deliveryStatus = stop['deliveryStatus'] as String? ?? 'pending';
                
                Color statusChipColor = Colors.grey;
                String statusLabel = 'PENDING';
                if (deliveryStatus == 'delivered') {
                  statusChipColor = const Color(0xFF2ECC71);
                  statusLabel = 'DELIVERED';
                } else if (deliveryStatus == 'failed') {
                  statusChipColor = const Color(0xFFE74C3C);
                  statusLabel = 'FAILED';
                }

                return GestureDetector(
                  onTap: () {
                    // Stop detail flow
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StopDetailScreen(
                          batchId: widget.batchId,
                          stop: stop,
                          isPickupConfirmed: status != 'created',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stop count circle
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF2874F0).withValues(alpha: 0.1),
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2874F0),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Retailer detail
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop['retailerName'] ?? 'Retailer',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF212121),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${stop['totalAmount']}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF212121),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stop['address'] ?? '-',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Delivery details status tag + call button
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusChipColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: GoogleFonts.inter(
                                        color: statusChipColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Call Retailer Button
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.grey.shade100,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF212121)),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Calling Retailer: ${stop['phone']}'),
                                            backgroundColor: const Color(0xFF2874F0),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
