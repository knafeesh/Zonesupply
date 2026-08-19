import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List _orders = [];
  bool _loading = true;
  String _error = '';
  String _searchQuery = '';
  String _selectedSort = 'Latest';
  
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _ticker;

  final Set<String> _expandedOrderIds = {};

  // Store live tracking information for each order
  final Map<String, Map<String, dynamic>> _orderTracking = {};
  final Map<String, int> _mockTrackingStepCount = {};
  int _trackingTimerTick = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
    // Live countdown refresh ticker + agent live location fetcher
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _trackingTimerTick++;
        if (_trackingTimerTick % 5 == 0) {
          _refreshExpandedTracking();
        }
        setState(() {});
      }
    });
  }

  void _refreshExpandedTracking() {
    for (final orderId in _expandedOrderIds) {
      final order = _orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
      if (order != null) {
        final status = (order['status'] as String? ?? '').toUpperCase();
        if (status == 'DISPATCHED' || status == 'IN_TRANSIT' || status == 'CONSOLIDATED') {
          _fetchTrackingForOrder(orderId);
        }
      }
    }
  }

  Future<void> _fetchTrackingForOrder(String orderId) async {
    try {
      final res = await ApiService.get('/orders/$orderId/tracking');
      if (mounted) {
        setState(() {
          _orderTracking[orderId] = Map<String, dynamic>.from(res);
        });
      }
    } catch (_) {
      if (mounted) {
        final order = _orders.firstWhere((o) => o['id'].toString() == orderId, orElse: () => null);
        if (order != null) {
          final status = (order['status'] as String? ?? '').toUpperCase();
          if (status == 'DISPATCHED' || status == 'IN_TRANSIT' || status == 'CONSOLIDATED') {
            final steps = _mockTrackingStepCount[orderId] ?? 0;
            final nextStep = steps + 1;
            _mockTrackingStepCount[orderId] = nextStep;

            final maxSteps = 10;
            final progress = (nextStep / maxSteps).clamp(0.0, 1.0);
            final distanceKm = 4.5 * (1.0 - progress);

            setState(() {
              _orderTracking[orderId] = {
                'status': status,
                'batchStatus': status == 'DISPATCHED' ? 'picked_up' : 'created',
                'agent': {
                  'name': 'Injmam Ul-Haque (Mock)',
                  'phone': '+91 88776 65544',
                },
                'distanceKm': distanceKm > 0.05 ? distanceKm : 0.05,
                'location': {
                  'latitude': 12.9105 + (12.9140 - 12.9105) * progress,
                  'longitude': 77.6450 + (77.6410 - 77.6450) * progress,
                  'timestamp': DateTime.now().toIso8601String(),
                },
              };
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await ApiService.get('/orders/my') as List? ?? [];
      if (mounted) {
        setState(() {
          _orders = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  int _getStatusStep(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 1;
      case 'CONFIRMED':
      case 'CONSOLIDATED':
        return 2;
      case 'DISPATCHED':
        return 3;
      case 'IN_TRANSIT':
        return 4;
      case 'DELIVERED':
        return 5;
      default:
        return 1;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CONFIRMED':
      case 'CONSOLIDATED':
        return 'Processing';
      case 'DISPATCHED':
        return 'Shipped';
      case 'IN_TRANSIT':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CONFIRMED':
      case 'CONSOLIDATED':
        return const Color(0xFFF1C40F); // Yellow for Processing
      case 'DISPATCHED':
        return const Color(0xFF2874F0); // Blue for Shipped
      case 'IN_TRANSIT':
        return const Color(0xFFE67E22); // Orange for Out for Delivery
      case 'DELIVERED':
        return const Color(0xFF2ECC71); // Green for Delivered
      case 'CANCELLED':
        return const Color(0xFFE74C3C); // Red for Cancelled
      default:
        return Colors.grey;
    }
  }

  String _getSmartDeliveryETA(Map<String, dynamic> o) {
    final status = (o['status'] as String? ?? 'PENDING').toUpperCase();
    if (status == 'DELIVERED') {
      final updatedAtStr = o['updatedAt'] as String?;
      final date = updatedAtStr != null ? DateTime.parse(updatedAtStr).toLocal() : DateTime.now();
      return 'Delivered on ${DateFormat('dd MMM yyyy').format(date)}';
    }
    if (status == 'CANCELLED') {
      return 'Order Cancelled';
    }
    
    final createdAtStr = o['createdAt'] as String?;
    if (createdAtStr == null) return 'Arriving Tomorrow';
    
    final created = DateTime.parse(createdAtStr).toLocal();
    final difference = DateTime.now().difference(created).inDays;
    
    if (difference >= 3) {
      return 'Delayed by 1 Day';
    } else if (status == 'PENDING') {
      return '2 Days Remaining';
    } else if (status == 'CONFIRMED' || status == 'CONSOLIDATED') {
      return 'Arriving Tomorrow';
    } else if (status == 'DISPATCHED' || status == 'IN_TRANSIT') {
      return 'Today 6–8 PM';
    }
    
    return 'Arriving Tomorrow';
  }

  String _getPoolingCountdown() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 18, 0, 0);
    if (now.isAfter(target)) {
      target = target.add(const Duration(days: 1));
    }
    final diff = target.difference(now);
    
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Filter into groups
    final active = _orders.where((o) {
      final status = (o['status'] as String? ?? 'PENDING').toUpperCase();
      return status != 'DELIVERED' && status != 'CANCELLED';
    }).toList();

    final delivered = _orders.where((o) {
      final status = (o['status'] as String? ?? 'PENDING').toUpperCase();
      return status == 'DELIVERED';
    }).toList();

    final cancelled = _orders.where((o) {
      final status = (o['status'] as String? ?? 'PENDING').toUpperCase();
      return status == 'CANCELLED';
    }).toList();

    final List returns = [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF212121), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.inter(
            color: const Color(0xFF212121),
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search & Sort bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF212121)),
                          decoration: const InputDecoration(
                            hintText: 'Search by Order ID or Product',
                            hintStyle: TextStyle(color: Color(0xFF878787), fontSize: 12),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF878787), size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sort dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          style: GoogleFonts.inter(color: const Color(0xFF212121), fontSize: 12, fontWeight: FontWeight.w700),
                          icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF2874F0), size: 18),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSort = val);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'Latest', child: Text('Latest')),
                            DropdownMenuItem(value: 'Delivery Time', child: Text('ETA')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2874F0),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF2874F0),
                unselectedLabelColor: const Color(0xFF878787),
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                dividerColor: Colors.grey.shade200,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Delivered'),
                  Tab(text: 'Returns'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2874F0)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(active, emptyMsg: 'No active orders processing.'),
                _buildOrdersList(delivered, emptyMsg: 'No delivered orders found in your history.'),
                _buildOrdersList(returns, emptyMsg: 'No returns requested.'),
                _buildOrdersList(cancelled, emptyMsg: 'No cancelled orders found.'),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List list, {required String emptyMsg}) {
    // Filter and Sort
    final filtered = list.where((o) {
      if (_searchQuery.isEmpty) return true;
      final shortId = (o['id'] as String?)?.substring(0, 8).toUpperCase() ?? '';
      final matchesId = shortId.contains(_searchQuery.toUpperCase());
      
      var matchesProduct = false;
      if (o['items'] != null) {
        for (final item in o['items']) {
          final pName = (item['product']?['name'] as String? ?? '').toLowerCase();
          if (pName.contains(_searchQuery.toLowerCase())) {
            matchesProduct = true;
            break;
          }
        }
      }
      return matchesId || matchesProduct;
    }).toList();

    if (_selectedSort == 'Latest') {
      filtered.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
    } else {
      filtered.sort((a, b) {
        final aStep = _getStatusStep(a['status']?.toString() ?? '');
        final bStep = _getStatusStep(b['status']?.toString() ?? '');
        return aStep.compareTo(bStep);
      });
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, color: Color(0xFFDCDCDC), size: 64),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2874F0),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final o = filtered[i];
          final oId = o['id'].toString();
          final shortId = oId.substring(0, 8).toUpperCase();
          final status = (o['status'] as String? ?? 'PENDING').toUpperCase();
          final isExpanded = _expandedOrderIds.contains(oId);

          // Get items: parent orders have items on childOrders, single-seller orders have direct items
          final directItems = o['items'] as List? ?? [];
          final childOrders = o['childOrders'] as List? ?? [];
          final itemsList = directItems.isNotEmpty
              ? directItems
              : childOrders.expand((c) => (c['items'] as List? ?? [])).toList();
          
          final firstItem = itemsList.isNotEmpty ? itemsList[0] : null;
          final firstProduct = firstItem != null ? firstItem['product'] : null;
          
          final productName = firstProduct != null ? firstProduct['name'] ?? 'Wholesale Order' : 'Wholesale Order';
          final firstImageUrl = firstProduct != null ? firstProduct['imageUrl'] : null;
          
          final totalQty = itemsList.fold<int>(0, (sum, item) {
            return sum + (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1);
          });
          final unit = firstProduct != null ? firstProduct['unit'] ?? 'units' : 'units';

          final dateStr = o['createdAt'] != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(o['createdAt']).toLocal())
              : '';

          final currentStep = _getStatusStep(status);
          final statusColor = _getStatusColor(status);
          final statusDisplay = _getStatusDisplay(status);
          final etaText = _getSmartDeliveryETA(o);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: ID, Chip & Date
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #$shortId',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF212121),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 10),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusDisplay.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // Middle Row: Product Info & Thumbnail
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: firstImageUrl != null && firstImageUrl.toString().isNotEmpty
                              ? Image.network(
                                  firstImageUrl.toString().startsWith('/')
                                      ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$firstImageUrl'
                                      : firstImageUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24),
                                )
                              : const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Product meta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: $totalQty $unit ${itemsList.length > 1 ? "(+${itemsList.length - 1} more items)" : ""}',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Color(0xFF878787), size: 13),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    o['deliveryAddress'] ?? o['deliveryZone'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Amount
                      Text(
                        '₹${o['totalAmount']}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF212121),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // Smart ETA Banner
                  Row(
                    children: [
                      Icon(
                        status == 'CANCELLED' ? Icons.cancel_outlined : Icons.schedule_rounded,
                        color: status == 'CANCELLED' ? Colors.red : const Color(0xFF2874F0),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        etaText,
                        style: GoogleFonts.inter(
                          color: status == 'CANCELLED' ? Colors.red : const Color(0xFF2874F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (status == 'PENDING') ...[
                        const Spacer(),
                        const Icon(Icons.hourglass_empty_rounded, color: Color(0xFFFF9F00), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Pooling: ${_getPoolingCountdown()}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF9F00),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Expanded timeline progress
                  if (isExpanded && status != 'CANCELLED') ...[
                    const Divider(height: 28, thickness: 0.5),
                    _buildTimelineTracker(currentStep),
                    _buildLiveTrackingInfo(o),
                  ],

                  // Action Buttons
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (status != 'CANCELLED')
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isExpanded ? const Color(0xFF2874F0) : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                foregroundColor: isExpanded ? const Color(0xFF2874F0) : const Color(0xFF212121),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedOrderIds.remove(oId);
                                  } else {
                                    _expandedOrderIds.add(oId);
                                    _fetchTrackingForOrder(oId);
                                  }
                                });
                              },
                              child: Text(
                                isExpanded ? 'Hide Status' : 'Track Order',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      if (status != 'CANCELLED') const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: const Color(0xFF212121),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _showOrderDetailsPopup(o),
                            child: Text(
                              'View Details',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveTrackingInfo(Map<String, dynamic> o) {
    final orderId = o['id'].toString();
    final track = _orderTracking[orderId];
    if (track == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF2874F0)),
          ),
        ),
      );
    }

    final agent = track['agent'];
    final distanceKm = track['distanceKm'];
    final location = track['location'];

    if (agent == null && location == null) {
      return const SizedBox.shrink();
    }

    // Parse agent lat/lng
    final agentLat = location != null
        ? double.tryParse(location['latitude']?.toString() ?? '') ?? 12.9105
        : 12.9105;
    final agentLng = location != null
        ? double.tryParse(location['longitude']?.toString() ?? '') ?? 77.6450
        : 77.6450;
    final agentPoint = LatLng(agentLat, agentLng);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2874F0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE SHIPMENT TRACKING',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2874F0),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (distanceKm != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2874F0).withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${distanceKm.toStringAsFixed(1)} km away',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2874F0),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Real OpenStreetMap with agent pin ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.zero),
            child: SizedBox(
              height: 180,
              child: AbsorbPointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: agentPoint,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.zonesupply.retailer',
                    ),
                    MarkerLayer(
                      markers: [
                        // Delivery agent marker
                        Marker(
                          point: agentPoint,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2874F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2874F0)
                                      .withAlpha(100),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delivery_dining_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Route polyline: agent → shop (approximate)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            agentPoint,
                            // Destination approximation
                            LatLng(agentLat + 0.012, agentLng - 0.008),
                          ],
                          strokeWidth: 3,
                          color: const Color(0xFF2874F0).withAlpha(180),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Delivery Verification OTP Card
          () {
            final otp = o['deliveryOtp'] ?? ((o['id'].toString().hashCode % 9000) + 1000).toString();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light green background
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded, color: Color(0xFF388E3C), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Verification OTP',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Provide this code to the agent to confirm delivery.',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      otp.toString(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }(),

          // Agent info row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.delivery_dining_rounded,
                          color: Color(0xFF2874F0), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent != null
                                ? agent['name'] ?? 'Delivery Agent'
                                : 'Delivery Agent',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF212121),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            agent != null
                                ? 'Phone: ${agent['phone']}'
                                : 'Out for delivery',
                            style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (agent != null && agent['phone'] != null)
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Calling Agent: ${agent['phone']}'),
                              backgroundColor: const Color(0xFF2874F0),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF388E3C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phone_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                  ],
                ),
                if (distanceKm != null) ...[
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (1.0 - (distanceKm / 5.0).clamp(0.0, 1.0)),
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF2874F0),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Wholesaler',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600)),
                      Text(
                          '${distanceKm.toStringAsFixed(1)} km remaining',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFF2874F0),
                              fontWeight: FontWeight.w800)),
                      Text('Your Shop',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTracker(int step) {
    final stages = ['Ordered', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Order Status History',
            style: GoogleFonts.inter(
              color: const Color(0xFF212121),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Row(
          children: List.generate(5, (i) {
            final isDone = step > i;
            final isActive = step == i + 1;
            final hasLine = i < 4;
            final lineDone = step > i + 1;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isActive ? const Color(0xFF2874F0) : Colors.grey.shade200,
                      border: Border.all(
                        color: isDone || isActive ? const Color(0xFF2874F0) : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.white : Colors.transparent,
                              ),
                            ),
                    ),
                  ),
                  if (hasLine)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: lineDone ? const Color(0xFF2874F0) : Colors.grey.shade200,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final active = step >= (i + 1);
            return Expanded(
              child: Text(
                stages[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : (i == 4 ? TextAlign.right : TextAlign.center),
                style: GoogleFonts.inter(
                  color: active ? const Color(0xFF212121) : const Color(0xFF878787),
                  fontSize: 8.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showOrderDetailsPopup(Map<String, dynamic> o) {
    final shortId = (o['id'] as String?)?.substring(0, 8).toUpperCase() ?? '';
    
    // Aggregate items: use direct items or merge from childOrders
    final directItems = o['items'] as List? ?? [];
    final childOrders = o['childOrders'] as List? ?? [];
    final itemsList = directItems.isNotEmpty
        ? directItems
        : childOrders.expand((c) => (c['items'] as List? ?? [])).toList();
    
    final dateStr = o['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(o['createdAt']).toLocal())
        : '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                  'Order Details',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF212121)),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #$shortId • Placed on $dateStr',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: o['paymentStatus'] == 'PAID' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Payment: ${o['paymentStatus'] ?? 'PENDING'}',
                        style: GoogleFonts.inter(
                          color: o['paymentStatus'] == 'PAID' ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (o['paymentMethod'] != null)
                      Text(
                        'Via: ${o['paymentMethod']}',
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const Divider(height: 24),

                // Show wholesaler breakdown for multi-seller orders
                if (childOrders.isNotEmpty) ...[
                  Text(
                    '${childOrders.length} Seller${childOrders.length > 1 ? 's' : ''} in this order',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: const Color(0xFF212121)),
                  ),
                  const SizedBox(height: 6),
                  ...childOrders.map((child) {
                    final sellerName = child['wholesaler']?['businessName'] ?? 'Wholesaler';
                    final childStatus = (child['status'] as String? ?? 'PENDING').toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: Color(0xFF2874F0), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(sellerName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(childStatus).withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusDisplay(childStatus),
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: _getStatusColor(childStatus)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                ] else if (o['wholesaler']?['businessName'] != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: Color(0xFF2874F0), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Wholesaler: ${o['wholesaler']['businessName']}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF212121)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: itemsList.isEmpty
                      ? Center(
                          child: Text(
                            'No item details available',
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: itemsList.length,
                          separatorBuilder: (context, index) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final item = itemsList[index];
                            final prod = item['product'];
                            final prodName = prod != null ? prod['name'] ?? 'Product' : 'Product';
                            final qty = item['quantity'];
                            final price = item['unitPrice'];
                            final subtotal = item['subtotal'];
                            final prodUnit = prod != null ? prod['unit'] ?? 'unit' : 'unit';

                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prodName,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF212121)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹$price per $prodUnit • Qty: $qty',
                                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  () {
                                    if (subtotal != null) return '₹$subtotal';
                                    final p = double.tryParse(price?.toString() ?? '0') ?? 0;
                                    final q = int.tryParse(qty?.toString() ?? '1') ?? 1;
                                    return '₹${(p * q).toStringAsFixed(2)}';
                                  }(),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF212121)),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const Divider(height: 24),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: const Color(0xFF212121)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            o['deliveryAddress'] ?? o['deliveryZone'] ?? '-',
                            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: const Color(0xFF212121)),
                    ),
                    Text(
                      '₹${o['totalAmount']}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF2874F0)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2874F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
