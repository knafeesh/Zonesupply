import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List _orders = [];
  bool _loading = true;
  late TabController _tabCtrl;
  final List<String> _tabs = ['All', 'Pending', 'Confirmed', 'Dispatched', 'Done'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/orders') as List? ?? [];
      if (!mounted) return;
      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List get _filtered {
    switch (_tabCtrl.index) {
      case 1: return _orders.where((o) => o['status'] == 'PENDING').toList();
      case 2: return _orders.where((o) => o['status'] == 'CONFIRMED' || o['status'] == 'CONSOLIDATED').toList();
      case 3: return _orders.where((o) => o['status'] == 'DISPATCHED' || o['status'] == 'IN_TRANSIT').toList();
      case 4: return _orders.where((o) =>
          o['status'] == 'DELIVERED' || o['status'] == 'CANCELLED').toList();
      default: return _orders;
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await ApiService.patch('/orders/$orderId/status', {'status': status});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order $status', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: _statusColor(status),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return const Color(0xFF2874F0);
      case 'CONSOLIDATED': return const Color(0xFFE056FD);
      case 'DISPATCHED': return const Color(0xFF388E3C);
      case 'IN_TRANSIT': return Colors.amber.shade700;
      case 'DELIVERED': return const Color(0xFF388E3C);
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text('Orders',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No new notifications',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFF2874F0),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Store Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFFB347),
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2874F0)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF2874F0),
              child: _filtered.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('No orders here',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF878787), fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _OrderCard(
                        order: _filtered[i],
                        statusColor: _statusColor(_filtered[i]['status'] ?? 'PENDING'),
                        onUpdateStatus: _updateStatus,
                      ),
                    ),
            ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map order;
  final Color statusColor;
  final Future<void> Function(String orderId, String status) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.onUpdateStatus,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final status = o['status'] as String? ?? 'PENDING';
    final items = (o['items'] as List?) ?? [];
    final orderId = o['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final totalAmount = double.tryParse(o['totalAmount']?.toString() ?? '0') ?? 0;
    final createdAt = o['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(o['createdAt']).toLocal())
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded
              ? widget.statusColor.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Order icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        color: widget.statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$shortId',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: Color(0xFF878787)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(o['deliveryZone'] ?? '-',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF878787), fontSize: 11),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 12, color: Color(0xFF878787)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(createdAt,
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF878787), fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(status,
                            style: GoogleFonts.inter(
                                color: widget.statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${NumberFormat('#,##,##0.00').format(totalAmount)}',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF878787),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded detail
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            // Items breakdown
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items (${items.length})',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF878787),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final qty = item['quantity']?.toString() ?? '1';
                      final price = double.tryParse(
                              item['priceAtOrder']?.toString() ??
                              item['price']?.toString() ?? '0') ??
                          0;
                      final subtotal = price *
                          (int.tryParse(qty) ?? 1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2874F0).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF2874F0), size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product']?['name'] ??
                                      item['productName'] ??
                                      item['name'] ??
                                      'Product',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF212121),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text('₹${price.toStringAsFixed(2)} × $qty',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF878787),
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('₹${subtotal.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF212121),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ]),
                      );
                    }),
                    Divider(color: Colors.grey.shade100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text('₹${totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF2874F0),
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
            // Action buttons
            _buildActions(status, orderId),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(String status, String orderId) {
    if (status == 'DELIVERED' || status == 'CANCELLED') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status == 'DELIVERED' ? '✅ Order Delivered' : '❌ Order Cancelled',
            style: GoogleFonts.inter(
                color: const Color(0xFF878787),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final batchId = widget.order['consolidationBatchId']?.toString() ?? '';
    final isConsolidated = batchId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _updating
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Color(0xFF2874F0), strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                if (status == 'PENDING') ...[
                  // Reject
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text('Reject',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () => _confirm('CANCELLED', orderId),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Accept Order',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () => _doUpdate('CONFIRMED', orderId),
                    ),
                  ),
                ] else if (status == 'CONFIRMED') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2874F0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 16),
                      label: Text('Ready for Dispatch',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () => _doUpdate('DISPATCHED', orderId),
                    ),
                  ),
                ] else if (status == 'DISPATCHED' && !isConsolidated) ...[
                  // Unconsolidated direct delivery: can mark DELIVERED or CANCELLED
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () => _confirm('CANCELLED', orderId),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Mark as Delivered',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () => _doUpdate('DELIVERED', orderId),
                    ),
                  ),
                ] else if (status == 'CONSOLIDATED' ||
                    status == 'DISPATCHED' ||
                    status == 'IN_TRANSIT') ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2874F0).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_shipping_outlined,
                              color: Color(0xFF2874F0), size: 16),
                          const SizedBox(width: 8),
                          Text('In Delivery Pipeline',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF2874F0),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _confirm(String status, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Order?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to reject this order? This cannot be undone.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doUpdate(status, orderId);
            },
            child: Text('Reject',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _doUpdate(String status, String orderId) async {
    setState(() => _updating = true);
    await widget.onUpdateStatus(orderId, status);
    if (mounted) setState(() => _updating = false);
  }
}
