import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/delivery_service.dart';
import 'batch_detail_screen.dart';
import 'package:core/widgets/app_header.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    
    // Initial fetch of delivery runs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadAll() {
    final ds = context.read<DeliveryService>();
    ds.fetchAvailableJobs();
    ds.fetchMyJobs();
  }

  Future<void> _loadAvailable() async {
    await context.read<DeliveryService>().fetchAvailableJobs();
  }

  Future<void> _loadMine() async {
    await context.read<DeliveryService>().fetchMyJobs();
  }

  Future<void> _claimJob(String batchId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<DeliveryService>().claimJob(batchId);
      messenger.showSnackBar(SnackBar(
        content: Text('🚚 Job claimed successfully!', style: GoogleFonts.roboto(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF2874F0),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ds = context.watch<DeliveryService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: Column(
        children: [
          AppHeader(
            appName: "ZONESUPPLY",
            tagline: "Deliver, Simplified",
            userName: auth.user?['name'] ?? 'Partner',
            subtitleLabel: "Delivery Partner",
            subtitleIcon: Icons.two_wheeler_outlined,
            notificationCount: 1,
            profileInitial: (auth.user?['name'] ?? 'P')[0].toUpperCase(),
            onNotificationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No new delivery jobs alert.',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFF2874F0),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            onProfileTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthProvider>().logout();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            color: const Color(0xFF2874F0),
            child: TabBar(
              controller: _tabCtrl,
              labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w900, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w700, fontSize: 14),
              labelColor: const Color(0xFFFFC200),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFFFC200),
              indicatorWeight: 3.5,
              tabs: const [
                Tab(text: 'Available Jobs'),
                Tab(text: 'My Jobs'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
        children: [
          _buildJobList(
            jobs: ds.availableJobs,
            loading: ds.loadingAvailable,
            available: true,
            onRefresh: _loadAvailable,
          ),
          _buildJobList(
            jobs: ds.myJobs,
            loading: ds.loadingMyJobs,
            available: false,
            onRefresh: _loadMine,
          ),
        ],
      ),
    );
  }

  Widget _buildJobList({
    required List<Map<String, dynamic>> jobs,
    required bool loading,
    required bool available,
    required Future<void> Function() onRefresh,
  }) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2874F0)),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF2874F0),
      backgroundColor: Colors.white,
      child: jobs.isEmpty
          ? Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_outlined,
                          color: Color(0xFF878787),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        available ? 'No Available Jobs' : 'No Claimed Jobs',
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF212121),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        available
                            ? 'Pull down to refresh or check back later.'
                            : 'Browse available runs to claim your first job.',
                        style: GoogleFonts.roboto(
                          color: const Color(0xFF878787),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: jobs.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final job = jobs[idx];
                return _JobCard(
                  batch: job,
                  available: available,
                  onClaim: () => _claimJob(job['id']),
                  onNavigate: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BatchDetailScreen(batchId: job['id']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> batch;
  final bool available;
  final VoidCallback onClaim;
  final VoidCallback onNavigate;

  const _JobCard({
    required this.batch,
    required this.available,
    required this.onClaim,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final orderCount = batch['orderCount'] as int? ?? 0;
    final zone = batch['deliveryZone'] as String? ?? '-';
    final value = batch['totalValue'];
    final wholesaler = batch['wholesaler'] as Map<String, dynamic>? ?? {};
    final wholesalerName = wholesaler['businessName'] ?? 'Wholesaler';
    final status = batch['status'] as String? ?? 'created';

    String badgeLabel = 'WAITING';
    Color badgeColor = const Color(0xFFF1C40F);
    if (status == 'picked_up') {
      badgeLabel = 'PICKED UP';
      badgeColor = const Color(0xFF2874F0);
    } else if (status == 'completed') {
      badgeLabel = 'COMPLETED';
      badgeColor = const Color(0xFF2ECC71);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: available ? null : onNavigate,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: Color(0xFF2874F0),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone,
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF212121),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'From: $wholesalerName',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF878787),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: Text(
                            '₹$value',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF388E3C),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!available) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeLabel,
                              style: GoogleFonts.roboto(
                                color: badgeColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF0F0F0)),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFF878787),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$orderCount retailer stops',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF212121),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF878787),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '~${(orderCount * 15)} min route',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF212121),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48, // Optimize touch target height to 48dp+
                  child: available
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC200),
                            foregroundColor: const Color(0xFF212121),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onClaim,
                          icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                          label: Text(
                            'Claim Delivery Job',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2874F0),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onNavigate,
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: Text(
                            'Navigate & Deliver',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
