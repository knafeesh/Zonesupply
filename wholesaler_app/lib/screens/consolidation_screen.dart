import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'batch_details_screen.dart';

class ConsolidationScreen extends StatefulWidget {
  const ConsolidationScreen({super.key});

  @override
  State<ConsolidationScreen> createState() => _ConsolidationScreenState();
}

class _ConsolidationScreenState extends State<ConsolidationScreen> {
  List _batches = [];
  List _filteredBatches = [];
  bool _loading = true;

  // Stats
  int _activeBatches = 0;
  int _pendingDispatch = 0;
  int _deliveredBatches = 0;
  double _totalBatchValue = 0.0;

  // Filter States
  String _activeTab = 'All'; // All, Created, Packed, Out for Delivery, Delivered
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/consolidation') as List? ?? [];
      
      int active = 0;
      int pendingDisp = 0;
      int delivered = 0;
      double totalVal = 0.0;

      for (final b in data) {
        final status = b['status']?.toString().toUpperCase() ?? 'CREATED';
        final hasDriver = b['deliveryPartnerId'] != null;
        final value = double.tryParse(b['totalValue']?.toString() ?? '0') ?? 0.0;

        totalVal += value;

        if (status == 'COMPLETED') {
          delivered++;
        } else {
          active++;
          if (status == 'CREATED' && !hasDriver) {
            pendingDisp++;
          }
        }
      }

      setState(() {
        _batches = data;
        _activeBatches = active;
        _pendingDispatch = pendingDisp;
        _deliveredBatches = delivered;
        _totalBatchValue = totalVal;
        _loading = false;
      });
      _applyFilters();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    List filtered = List.from(_batches);

    // 1. Tab Filter (All, Created, Packed, Out for Delivery, Delivered)
    if (_activeTab == 'Created') {
      filtered = filtered.where((b) =>
          b['status']?.toString().toUpperCase() == 'CREATED' &&
          b['deliveryPartnerId'] == null).toList();
    } else if (_activeTab == 'Packed') {
      filtered = filtered.where((b) =>
          b['status']?.toString().toUpperCase() == 'CREATED' &&
          b['deliveryPartnerId'] != null).toList();
    } else if (_activeTab == 'Out for Delivery') {
      filtered = filtered.where((b) =>
          b['status']?.toString().toUpperCase() == 'PICKED_UP' ||
          b['status']?.toString().toUpperCase() == 'IN_TRANSIT').toList();
    } else if (_activeTab == 'Delivered') {
      filtered = filtered.where((b) =>
          b['status']?.toString().toUpperCase() == 'COMPLETED').toList();
    }

    // 2. Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        final batchId = (b['id']?.toString() ?? '').toLowerCase();
        final zone = (b['zone']?['name']?.toString() ?? '').toLowerCase();
        final retailers = (b['retailerNames']?.toString() ?? '').toLowerCase();
        return batchId.contains(query) || zone.contains(query) || retailers.contains(query);
      }).toList();
    }

    setState(() {
      _filteredBatches = filtered;
    });
  }

  Future<void> _assignAgent(String batchId, String agentId) async {
    try {
      await ApiService.patch('/consolidation/$batchId/assign', {'agentId': agentId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agent assigned successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error assigning agent: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showAssignAgentDialog(String batchId) async {
    setState(() => _loading = true);
    List agents = [];
    try {
      agents = await ApiService.get('/consolidation/agents') as List? ?? [];
    } catch (e) {
      debugPrint("Error loading agents: $e");
    }
    setState(() => _loading = false);

    if (agents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No delivery agents available.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Assign Delivery Agent',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: agents.length,
            separatorBuilder: (_, index) => const Divider(),
            itemBuilder: (context, index) {
              final agent = agents[index];
              final name = agent['user']?['name'] ?? 'Agent';
              final status = agent['status']?.toString().toUpperCase() ?? 'OFFLINE';
              final isAvailable = status == 'AVAILABLE';

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isAvailable ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_run_rounded,
                    color: isAvailable ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Status: $status | Vehicle: ${agent['vehicleType'] ?? '-'}',
                  style: GoogleFonts.inter(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _assignAgent(batchId, agent['id']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  void _showCreateBatchDialog() async {
    setState(() => _loading = true);
    List zones = [];
    try {
      zones = await ApiService.get('/zones') as List? ?? [];
    } catch (e) {
      debugPrint("Error loading zones: $e");
    }
    setState(() => _loading = false);

    if (zones.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No zones available.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    String? selectedZoneId = zones.first['id']?.toString();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Create Consolidation Batch',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a delivery zone to manually pool and consolidate pending orders.',
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedZoneId,
                decoration: InputDecoration(
                  labelText: 'Delivery Zone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: zones.map((z) {
                  return DropdownMenuItem(
                    value: z['id']?.toString(),
                    child: Text(z['name'] ?? 'Zone'),
                  );
                }).toList(),
                onChanged: (val) {
                  setDialogState(() => selectedZoneId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2874F0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (selectedZoneId == null) return;
                Navigator.pop(dialogCtx);
                setState(() => _loading = true);
                try {
                  await ApiService.post('/consolidation/create', {'zoneId': selectedZoneId});
                  await _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Consolidation batch created successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              child: Text('Create', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMergeOrdersDialog() async {
    setState(() => _loading = true);
    List pendingOrders = [];
    try {
      final orders = await ApiService.get('/orders') as List? ?? [];
      pendingOrders = orders.where((o) => o['status']?.toString().toUpperCase() == 'PENDING').toList();
    } catch (e) {
      debugPrint("Error loading pending orders: $e");
    }
    setState(() => _loading = false);

    if (pendingOrders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No pending orders available to merge.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final List<String> selectedOrderIds = [];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Merge Pending Orders',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pendingOrders.length,
              itemBuilder: (context, idx) {
                final o = pendingOrders[idx];
                final id = o['id']?.toString() ?? '';
                final isChecked = selectedOrderIds.contains(id);
                final shopName = o['retailer']?['shopName'] ?? o['retailer']?['user']?['name'] ?? 'Retailer';
                final dateStr = o['createdAt'] != null
                    ? DateFormat('dd MMM').format(DateTime.parse(o['createdAt']).toLocal())
                    : '';
                final amount = double.tryParse(o['totalAmount']?.toString() ?? '0') ?? 0;

                return CheckboxListTile(
                  value: isChecked,
                  title: Text(shopName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text(
                    'Amt: ₹${NumberFormat('#,##,##0').format(amount)} | Zone: ${o['deliveryZone'] ?? '-'} | Date: $dateStr',
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selectedOrderIds.add(id);
                      } else {
                        selectedOrderIds.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2874F0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: selectedOrderIds.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(dialogCtx);
                      setState(() => _loading = true);
                      try {
                        await ApiService.post('/consolidation/merge', {'orderIds': selectedOrderIds});
                        await _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Selected orders merged successfully!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } catch (e) {
                        setState(() => _loading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    },
              child: Text('Merge', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consolidation Operations',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_box_rounded, color: Color(0xFF2874F0)),
              ),
              title: Text('Create Batch', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              subtitle: Text('Consolidate pending orders in a specific zone', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateBatchDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.merge_type_rounded, color: Color(0xFF388E3C)),
              ),
              title: Text('Merge Orders', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              subtitle: Text('Manually select and merge specific orders', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showMergeOrdersDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          'Consolidation Batches',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabMenu,
        backgroundColor: const Color(0xFF2874F0),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF2874F0),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Stats section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Dashboard cards scroll
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildStatCard(
                            title: 'Active Batches',
                            value: '$_activeBatches',
                            color: const Color(0xFF2874F0),
                            bgColor: const Color(0xFF2874F0).withValues(alpha: 0.08),
                            icon: Icons.local_shipping_rounded,
                          ),
                          _buildStatCard(
                            title: 'Pending Dispatch',
                            value: '$_pendingDispatch',
                            color: Colors.orange.shade700,
                            bgColor: Colors.orange.shade50,
                            icon: Icons.hourglass_empty_rounded,
                          ),
                          _buildStatCard(
                            title: 'Delivered',
                            value: '$_deliveredBatches',
                            color: const Color(0xFF388E3C),
                            bgColor: Colors.green.shade50,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          _buildStatCard(
                            title: 'Total Batch Value',
                            value: '₹${NumberFormat('#,##,##0').format(_totalBatchValue)}',
                            color: Colors.purple.shade700,
                            bgColor: Colors.purple.shade50,
                            icon: Icons.monetization_on_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search batch ID, retailer or order',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Choice chips status filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Created', 'Packed', 'Out for Delivery', 'Delivered'].map((tab) {
                          final isSel = _activeTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                tab,
                                style: GoogleFonts.inter(
                                  color: isSel ? Colors.white : Colors.grey.shade600,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: const Color(0xFF2874F0),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: isSel ? Colors.transparent : Colors.grey.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _activeTab = tab);
                                  _applyFilters();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Batches list
            _loading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF2874F0))),
                  )
                : _filteredBatches.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No batches created yet.',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF878787),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create your first batch.',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final b = _filteredBatches[i];
                              return _BatchCard(
                                batch: b,
                                onUpdated: _load,
                                onAssign: () => _showAssignAgentDialog(b['id']),
                              );
                            },
                            childCount: _filteredBatches.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF878787), fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: const Color(0xFF212121),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final Map batch;
  final VoidCallback onUpdated;
  final VoidCallback onAssign;

  const _BatchCard({
    required this.batch,
    required this.onUpdated,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final status = batch['status']?.toString().toUpperCase() ?? 'CREATED';
    final hasDriver = batch['deliveryPartnerId'] != null;
    final value = double.tryParse(batch['totalValue']?.toString() ?? '0') ?? 0.0;
    final orderCount = batch['orderCount'] ?? 0;
    final deliveredCount = batch['deliveredCount'] ?? 0;
    final shortId = batch['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    
    final dateStr = batch['createdAt'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(batch['createdAt']).toLocal())
        : '';

    // Map status colors
    String displayStatus;
    Color statusColor;
    Color statusBg;

    if (status == 'COMPLETED') {
      displayStatus = 'Delivered';
      statusColor = const Color(0xFF388E3C);
      statusBg = Colors.green.shade50;
    } else if (status == 'PICKED_UP' || status == 'IN_TRANSIT') {
      displayStatus = 'Out for Delivery';
      statusColor = Colors.purple.shade700;
      statusBg = Colors.purple.shade50;
    } else if (hasDriver) {
      displayStatus = 'Packed';
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
    } else {
      displayStatus = 'Created';
      statusColor = const Color(0xFF2874F0);
      statusBg = const Color(0xFF2874F0).withValues(alpha: 0.1);
    }

    final double progress = orderCount > 0 ? (deliveredCount / orderCount) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Batch ID & status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#BAT-$shortId',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF212121)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayStatus.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),

          // Middle: Retailer Name, Location, Created Date
          Text(
            batch['retailerNames'] ?? 'Retailer',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF212121)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
              const SizedBox(width: 4),
              Text(
                batch['zone']?['name'] ?? '-',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),

          // Bottom: Total Orders, Total Value, Delivery Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$orderCount Drops • ₹${NumberFormat('#,##,##0').format(value)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: const Color(0xFF212121)),
              ),
              Text(
                '$deliveredCount/$orderCount Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: statusColor),
              ),
            ],
          ),
          if (orderCount > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2874F0),
                    side: const BorderSide(color: Color(0xFF2874F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BatchDetailsScreen(batchId: batch['id'])),
                    ).then((_) => onUpdated());
                  },
                  child: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              if (status == 'CREATED') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2874F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 14),
                    label: Text(
                      hasDriver ? 'Change Driver' : 'Assign Agent',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: onAssign,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
