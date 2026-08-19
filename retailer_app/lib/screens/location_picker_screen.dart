import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPickerResult {
  final String formattedAddress;
  final String areaTitle;
  final String buildingNumber;
  final String landmark;
  final String addressType;
  final double latitude;
  final double longitude;
  final String? pincode;
  final String? city;

  LocationPickerResult({
    required this.formattedAddress,
    required this.areaTitle,
    required this.buildingNumber,
    required this.landmark,
    required this.addressType,
    required this.latitude,
    required this.longitude,
    this.pincode,
    this.city,
  });

  String get fullAddress {
    final parts = <String>[];
    if (buildingNumber.trim().isNotEmpty) parts.add(buildingNumber.trim());
    if (landmark.trim().isNotEmpty) parts.add(landmark.trim());
    if (formattedAddress.trim().isNotEmpty && formattedAddress != buildingNumber) {
      parts.add(formattedAddress.trim());
    }
    return parts.join(', ');
  }
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late LatLng _currentCenter;

  bool _isLocatingDevice = false;
  bool _isReverseGeocoding = false;
  bool _isMapMoving = false;

  String _areaTitle = 'Locating area...';
  String _formattedAddress = 'Fetching exact address...';
  String _pincode = '';
  String _city = '';

  final TextEditingController _buildingCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedAddressType = 'Shop'; // 'Shop', 'Warehouse', 'Home', 'Other'

  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  late AnimationController _pinAnimController;
  late Animation<double> _pinJumpAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Default to provided coordinates or Bangalore center
    final lat = widget.initialLat ?? 12.9716;
    final lng = widget.initialLng ?? 77.5946;
    _currentCenter = LatLng(lat, lng);

    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _formattedAddress = widget.initialAddress!;
      _areaTitle = widget.initialAddress!.split(',').first.trim();
    }

    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinJumpAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOutQuad),
    );

    // Auto-detect exact device GPS on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentDeviceLocation(showErrorDialog: false);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _buildingCtrl.dispose();
    _landmarkCtrl.dispose();
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    _pinAnimController.dispose();
    super.dispose();
  }

  /// Request GPS permission and fetch exact device location
  Future<void> _getCurrentDeviceLocation({bool showErrorDialog = true}) async {
    setState(() => _isLocatingDevice = true);
    HapticFeedback.mediumImpact();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showErrorDialog && mounted) {
          _showLocationServiceDialog();
        }
        setState(() => _isLocatingDevice = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showErrorDialog && mounted) {
            _showSnackBar('Location permission is required to detect your exact shop location.');
          }
          setState(() => _isLocatingDevice = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (showErrorDialog && mounted) {
          _showPermissionDeniedForeverDialog();
        }
        setState(() => _isLocatingDevice = false);
        return;
      }

      // Fetch high accuracy GPS position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      _currentCenter = newCenter;
      _mapController.move(newCenter, 17.0);

      _pinAnimController.forward().then((_) => _pinAnimController.reverse());
      _reverseGeocode(newCenter);
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      if (showErrorDialog && mounted) {
        _showSnackBar('Could not fetch GPS location. Please select on map.');
      }
    } finally {
      if (mounted) setState(() => _isLocatingDevice = false);
    }
  }

  /// Convert coordinates to a readable human address
  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _isReverseGeocoding = true;
      _areaTitle = 'Resolving location...';
      _formattedAddress = 'Fetching address details...';
    });

    try {
      // 1. Try native geocoding first
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      ).timeout(const Duration(seconds: 4));

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final area = p.subLocality?.isNotEmpty == true
            ? p.subLocality!
            : (p.locality?.isNotEmpty == true ? p.locality! : (p.name ?? 'Selected Area'));
        
        final parts = <String>[];
        if (p.street?.isNotEmpty == true && p.street != p.name) parts.add(p.street!);
        if (p.subLocality?.isNotEmpty == true) parts.add(p.subLocality!);
        if (p.locality?.isNotEmpty == true) parts.add(p.locality!);
        if (p.administrativeArea?.isNotEmpty == true) parts.add(p.administrativeArea!);
        if (p.postalCode?.isNotEmpty == true) parts.add(p.postalCode!);

        if (mounted) {
          setState(() {
            _areaTitle = area;
            _formattedAddress = parts.isNotEmpty ? parts.join(', ') : 'Near ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
            _pincode = p.postalCode ?? '';
            _city = p.locality ?? p.subAdministrativeArea ?? '';
            _isReverseGeocoding = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fallback to OpenStreetMap reverse geocoding API
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'ZoneSupplyRetailerApp/1.0',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        final displayName = data['display_name'] as String? ?? '';

        final suburb = address?['suburb'] ?? address?['neighbourhood'] ?? address?['road'] ?? address?['city_district'] ?? 'Selected Area';
        final city = address?['city'] ?? address?['town'] ?? address?['state_district'] ?? '';
        final postcode = address?['postcode'] ?? '';

        if (mounted) {
          setState(() {
            _areaTitle = suburb.toString();
            _formattedAddress = displayName.isNotEmpty ? displayName : 'Location at ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
            _pincode = postcode.toString();
            _city = city.toString();
            _isReverseGeocoding = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Final fallback
    if (mounted) {
      setState(() {
        _areaTitle = 'Pinned Location';
        _formattedAddress = 'GPS Coordinates: ${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        _isReverseGeocoding = false;
      });
    }
  }

  /// Search places via OpenStreetMap Nominatim
  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&countrycodes=in',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'ZoneSupplyRetailerApp/1.0',
      }).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(data);
            _showSearchResults = _searchResults.isNotEmpty;
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSelectSearchResult(Map<String, dynamic> result) {
    FocusScope.of(context).unfocus();
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');

    if (lat != null && lon != null) {
      final newCenter = LatLng(lat, lon);
      _currentCenter = newCenter;
      _mapController.move(newCenter, 17.0);

      setState(() {
        _showSearchResults = false;
        _searchCtrl.clear();
      });

      _reverseGeocode(newCenter);
    }
  }

  void _confirmAndReturn() {
    HapticFeedback.heavyImpact();

    final result = LocationPickerResult(
      formattedAddress: _formattedAddress,
      areaTitle: _areaTitle,
      buildingNumber: _buildingCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim(),
      addressType: _selectedAddressType,
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      pincode: _pincode.isNotEmpty ? _pincode : null,
      city: _city.isNotEmpty ? _city : null,
    );

    Navigator.pop(context, result);
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enable Location Service', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Please turn on GPS/Location services on your device to accurately pinpoint your delivery address.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2874F0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: Text('Open Settings', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Location Permission Blocked', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Location access is permanently disabled for Zone Store. Please enable it in App Settings.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2874F0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: Text('App Settings', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF212121),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Full Screen Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.5,
              maxZoom: 19.0,
              minZoom: 5.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  _currentCenter = position.center!;
                  if (!_isMapMoving) {
                    setState(() => _isMapMoving = true);
                    _pinAnimController.forward();
                  }

                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 600), () {
                    if (mounted) {
                      setState(() => _isMapMoving = false);
                      _pinAnimController.reverse();
                      _reverseGeocode(_currentCenter);
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zonesupply.retailer_app',
                maxZoom: 19,
              ),
            ],
          ),

          // 2. Center Fixed Animated Flipkart Pin Marker
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pinJumpAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _pinJumpAnimation.value - 24), // Center of pin point
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Speech bubble indicating location
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF212121),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isMapMoving
                                      ? 'Pinning location...'
                                      : 'Order will be delivered here',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Glowing Pin Icon
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2874F0).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFFE53935),
                                size: 42,
                              ),
                              const Positioned(
                                top: 12,
                                child: Icon(
                                  Icons.store_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),

                          // Marker point dot shadow
                          Container(
                            width: 8,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. Top Floating Search Bar & Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF212121)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Search for area, landmark, street...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                              _searchPlaces(val);
                            });
                          },
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _searchResults = [];
                              _showSearchResults = false;
                            });
                          },
                        )
                      else if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2874F0)),
                          ),
                        ),
                    ],
                  ),
                ),

                // Search Autocomplete Results Dropdown
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = _searchResults[idx];
                        final displayName = item['display_name'] ?? '';
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Color(0xFF2874F0), size: 20),
                          title: Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onTap: () => _onSelectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. Floating "Use Current Location / GPS" Button (Flipkart Style)
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.44 + 10,
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _isLocatingDevice ? null : () => _getCurrentDeviceLocation(showErrorDialog: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2874F0).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLocatingDevice)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2874F0)),
                        )
                      else
                        const Icon(Icons.my_location_rounded, color: Color(0xFF2874F0), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _isLocatingDevice ? 'Locating...' : 'Use Current Location',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF2874F0),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Flipkart-Style Bottom Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(18, 14, 18, MediaQuery.of(context).padding.bottom + 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                  const SizedBox(height: 12),

                  // Location Banner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF2874F0), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _areaTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF212121),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (_isReverseGeocoding)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2874F0)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formattedAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF878787),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Inputs: Building / Shop Number & Landmark
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: _buildingCtrl,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Shop / House / Flat No. *',
                            labelStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                            hintText: 'e.g. Shop No. 12, G.F.',
                            hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2874F0), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: _landmarkCtrl,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Nearby Landmark',
                            labelStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                            hintText: 'e.g. Near City Bank',
                            hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2874F0), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Save Address As Chips (Shop, Warehouse, Home, Other)
                  Row(
                    children: [
                      Text(
                        'Save as: ',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF878787)),
                      ),
                      const SizedBox(width: 4),
                      _buildTypeChip('Shop', Icons.store_rounded),
                      const SizedBox(width: 6),
                      _buildTypeChip('Warehouse', Icons.warehouse_rounded),
                      const SizedBox(width: 6),
                      _buildTypeChip('Home', Icons.home_rounded),
                      const SizedBox(width: 6),
                      _buildTypeChip('Other', Icons.location_on_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Primary Confirmation Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isReverseGeocoding ? null : _confirmAndReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2874F0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Confirm Location & Delivery Address',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    final isSelected = _selectedAddressType == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedAddressType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2874F0).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2874F0) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFF2874F0) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2874F0) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
