import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BatchDetailsScreen extends StatefulWidget {
  final String batchId;
  const BatchDetailsScreen({super.key, required this.batchId});

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  Map<String, dynamic>? _batch;
  bool _loading = true;
  List _agents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/consolidation/${widget.batchId}') as Map<String, dynamic>?;
      setState(() {
        _batch = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading batch details: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await ApiService.get('/consolidation/agents') as List? ?? [];
      setState(() {
        _agents = agents;
      });
    } catch (e) {
      debugPrint("Error loading agents: $e");
    }
  }

  Future<void> _assignAgent(String agentId) async {
    try {
      await ApiService.patch('/consolidation/${widget.batchId}/assign', {'agentId': agentId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Delivery agent assigned successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error assigning agent: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showAssignAgentDialog() async {
    await _loadAgents();
    if (_agents.isEmpty) {
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
            itemCount: _agents.length,
            separatorBuilder: (_, index) => const Divider(),
            itemBuilder: (context, index) {
              final agent = _agents[index];
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
                  _assignAgent(agent['id']);
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

  void _printInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Generating and printing batch consolidated invoice...'),
      backgroundColor: Color(0xFF2874F0),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2874F0))),
      );
    }

    if (_batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: Center(
          child: Text(
            'Batch not found.',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final b = _batch!;
    final batchIdShort = b['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final status = b['status']?.toString().toUpperCase() ?? 'CREATED';
    final dateStr = b['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(b['createdAt']).toLocal())
        : '';
    final totalVal = double.tryParse(b['totalValue']?.toString() ?? '0') ?? 0.0;
    
    final driverAssigned = b['deliveryPartner'] != null;
    final driverName = b['deliveryPartner']?['user']?['name'] ?? '';
    final vehicle = b['deliveryPartner']?['vehicleType'] ?? '';
    final license = b['deliveryPartner']?['licenseNumber'] ?? '';

    // Status mapping
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
    } else if (driverAssigned) {
      displayStatus = 'Packed';
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
    } else {
      displayStatus = 'Created';
      statusColor = const Color(0xFF2874F0);
      statusBg = const Color(0xFF2874F0).withValues(alpha: 0.1);
    }

    final List orders = b['orders'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2874F0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Batch #$batchIdShort',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF2874F0),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Batch summary card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Consolidation Batch Summary',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
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
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow('Created Date', dateStr),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Delivery Zone', b['zone']?['name'] ?? '-'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Total Orders', '${b['orderCount'] ?? 0} drops'),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Total Value',
                      '₹${NumberFormat('#,##,##0.00').format(totalVal)}',
                      valueColor: const Color(0xFF2874F0),
                      valueWeight: FontWeight.w800,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver assignment card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Driver Details',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const Divider(height: 24),
                    if (driverAssigned) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: Color(0xFF2874F0)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vehicle: ${vehicle.replaceAll('_', ' ').toUpperCase()} | License: $license',
                                  style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (status == 'CREATED')
                            IconButton(
                              icon: const Icon(Icons.edit_road_rounded, color: Color(0xFF2874F0)),
                              onPressed: _showAssignAgentDialog,
                            ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No delivery agent assigned yet.',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2874F0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text('Assign', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: _showAssignAgentDialog,
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Progress Timeline',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const Divider(height: 24),
                    _buildTimelineStep(
                      title: 'Batch Created',
                      description: 'Orders consolidated and enqueued',
                      isCompleted: true,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Driver Assigned',
                      description: driverAssigned ? 'Assigned to $driverName' : 'Pending agent assignment',
                      isCompleted: driverAssigned,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Picked Up / Dispatched',
                      description: 'Batch collection scanned at warehouse',
                      isCompleted: status == 'PICKED_UP' || status == 'IN_TRANSIT' || status == 'COMPLETED',
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Delivered',
                      description: 'All retailer drops successfully dispatched',
                      isCompleted: status == 'COMPLETED',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Orders list card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Drops Inside Batch',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          '${orders.length} Orders',
                          style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final ord = orders[idx];
                        final isDel = ord['deliveryStatus']?.toString().toUpperCase() == 'DELIVERED';
                        final isFail = ord['deliveryStatus']?.toString().toUpperCase() == 'FAILED';
                        
                        Color dropStatusColor = Colors.orange.shade700;
                        if (isDel) dropStatusColor = const Color(0xFF388E3C);
                        if (isFail) dropStatusColor = Colors.red.shade700;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade100),
                            color: const Color(0xFFF8F9FA),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2874F0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${ord['deliverySequence'] ?? (idx + 1)}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ord['retailerName'] ?? 'Retailer',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat('#,##,##0').format(double.tryParse(ord['totalAmount']?.toString() ?? '0') ?? 0)}',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ord['address'] ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Payment: ${ord['paymentMethod']} (${ord['paymentStatus']})',
                                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF878787), fontWeight: FontWeight.w500),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: dropStatusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ord['deliveryStatus']?.toString().toUpperCase() ?? 'PENDING',
                                      style: GoogleFonts.inter(
                                        color: dropStatusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Print Invoice Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2874F0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.print_rounded),
                label: Text('Print Consolidated Invoice', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                onPressed: _printInvoice,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, FontWeight? valueWeight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 13)),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor ?? const Color(0xFF212121),
            fontWeight: valueWeight ?? FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String description,
    required bool isCompleted,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF388E3C) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? const Color(0xFF388E3C) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isCompleted ? const Color(0xFF212121) : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
