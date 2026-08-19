import 'package:core/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'consolidation_screen.dart';
import 'ledger_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    int productsCount = 0;
    int ordersCount = 0;
    int pendingOrdersCount = 0;
    int batchesCount = 0;
    double revenueAmount = 0.0;
    double totalOutstanding = 0.0;
    List recentOrders = [];

    try {
      final products = await ApiService.get('/products/my') as List?;
      productsCount = products?.length ?? 0;
    } catch (e) {
      debugPrint("Error loading products count: $e");
    }

    try {
      final orders = await ApiService.get('/orders') as List?;
      ordersCount = orders?.length ?? 0;
      pendingOrdersCount =
          orders?.where((o) => o['status'] == 'PENDING').length ?? 0;
      revenueAmount = orders?.fold<double>(
            0.0,
            (sum, o) =>
                sum +
                (double.tryParse(o['totalAmount']?.toString() ?? '0') ?? 0.0),
          ) ??
          0.0;
      // 3 most recent
      recentOrders = (orders ?? []).take(3).toList();
    } catch (e) {
      debugPrint("Error loading orders/revenue: $e");
    }

    try {
      final batches = await ApiService.get('/consolidation') as List?;
      batchesCount = batches?.length ?? 0;
    } catch (e) {
      debugPrint("Error loading batches: $e");
    }

    try {
      final ledger =
          await ApiService.get('/credit-ledger/wholesaler/outstanding') as List?;
      for (final r in (ledger ?? [])) {
        totalOutstanding +=
            double.tryParse(r['outstandingBalance']?.toString() ?? '0') ?? 0;
      }
    } catch (e) {
      debugPrint("Error loading ledger: $e");
    }

    Map<String, dynamic>? profile;
    try {
      profile = await ApiService.get('/wholesalers/profile') as Map<String, dynamic>?;
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }

    setState(() {
      _stats = {
        'products': productsCount,
        'orders': ordersCount,
        'pendingOrders': pendingOrdersCount,
        'batches': batchesCount,
        'revenue': revenueAmount,
        'outstanding': totalOutstanding,
        'recentOrders': recentOrders,
        'profile': profile,
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        stats: _stats,
        loading: _loading,
        onRefresh: _loadStats,
        onGoToLedger: () => setState(() => _selectedIndex = 4),
        onGoToOrders: () => setState(() => _selectedIndex = 2),
        onGoToProducts: () => setState(() => _selectedIndex = 1),
        onGoToBatches: () => setState(() => _selectedIndex = 3),
      ),
      const ProductsScreen(),
      const OrdersScreen(),
      const ConsolidationScreen(),
      const LedgerScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Inventory'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
      (Icons.local_shipping_outlined, Icons.local_shipping_rounded, 'Batches'),
      (Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet_rounded, 'Ledger'),
    ];
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = _selectedIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          selected ? items[i].$2 : items[i].$1,
                          key: ValueKey('$i-$selected'),
                          color: selected
                              ? const Color(0xFF2874F0)
                              : const Color(0xFF878787),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF2874F0)
                              : const Color(0xFF878787),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Home Tab
// ──────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onGoToLedger;
  final VoidCallback onGoToOrders;
  final VoidCallback onGoToProducts;
  final VoidCallback onGoToBatches;

  const _HomeTab({
    this.stats,
    required this.loading,
    required this.onRefresh,
    required this.onGoToLedger,
    required this.onGoToOrders,
    required this.onGoToProducts,
    required this.onGoToBatches,
  });
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recentOrders = (stats?['recentOrders'] as List?) ?? [];
    final outstanding = (stats?['outstanding'] as double?) ?? 0.0;
    final pendingOrders = stats?['pendingOrders'] as int? ?? 0;
    final profile = stats?['profile'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF2874F0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              appName: "ZONESUPPLY",
              tagline: "Wholesale, Simplified",
              userName: profile?['user']?['name'] ?? auth.user?['name'] ?? 'Wholesaler',
              subtitleLabel: (profile != null && profile['businessName'] != null)
                  ? profile['businessName']
                  : "Wholesaler Shop",
              subtitleIcon: Icons.storefront_outlined,
              notificationCount: 3,
              profileInitial: (profile?['user']?['name'] ?? auth.user?['name'] ?? 'W')[0].toUpperCase(),
              backgroundImagePath: 'assets/images/trolley.jpg',
              logoImagePath: 'assets/images/logo_banner.jpg',
              onNotificationTap: () {
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
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              onSubtitleTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),
          if (pendingOrders > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB347).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: Color(0xFFFF9F00)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have $pendingOrders pending order${pendingOrders > 1 ? 's' : ''} awaiting action.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFD35400),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onGoToOrders,
                        child: Text('VIEW', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFD35400))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (loading)
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF2874F0)),
                    ),
                  )
                else ...[
                  // Stats 2×2 grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        'Products',
                        stats?['products']?.toString() ?? '0',
                        Icons.inventory_2_outlined,
                        const Color(0xFF2874F0),
                        actionText: 'View all',
                        onTap: onGoToProducts,
                      ),
                      _StatCard(
                        'Pending Orders',
                        stats?['pendingOrders']?.toString() ?? '0',
                        Icons.assignment_outlined,
                        const Color(0xFFFF9F00),
                        actionText: 'View all',
                        onTap: onGoToOrders,
                      ),
                      _StatCard(
                        'Batches',
                        stats?['batches']?.toString() ?? '0',
                        Icons.local_shipping_outlined,
                        const Color(0xFF9B59B6),
                        actionText: 'View all',
                        onTap: onGoToBatches,
                      ),
                      _StatCard(
                        'Revenue',
                        '₹${NumberFormat('#,##,##0').format((stats?['revenue'] as double?) ?? 0.0)}',
                        Icons.currency_rupee_rounded,
                        const Color(0xFF2ECC71),
                        actionText: 'View details',
                        onTap: onGoToLedger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Total Outstanding (Ledger) Card
                  GestureDetector(
                    onTap: onGoToLedger,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD1D8).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Outstanding (Ledger)',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF666666),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${NumberFormat('#,##,##0.00').format(outstanding)}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFD32F2F),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  outstanding > 0
                                      ? 'Tap to manage & record payments'
                                      : 'All clear — no outstanding dues',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF878787),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFD32F2F),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF212121),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: onGoToProducts,
                        child: Row(
                          children: [
                            Text(
                              'View All',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF2874F0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF2874F0),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        context,
                        'Add Product',
                        Icons.add_box_outlined,
                        const Color(0xFF2874F0),
                        onGoToProducts,
                      ),
                      _buildQuickAction(
                        context,
                        'Create Batch',
                        Icons.note_add_outlined,
                        const Color(0xFFFF9F00),
                        onGoToBatches,
                      ),
                      _buildQuickAction(
                        context,
                        'New Order',
                        Icons.shopping_cart_outlined,
                        const Color(0xFF2ECC71),
                        onGoToOrders,
                      ),
                      _buildQuickAction(
                        context,
                        'Collect Payment',
                        Icons.account_balance_wallet_outlined,
                        const Color(0xFF9B59B6),
                        onGoToLedger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Revenue Trend Section Header with Stats & Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revenue Trend',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF212121),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Revenue',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF878787),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,##0').format((stats?['revenue'] as double?) ?? 0.0)}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF212121),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'This Month',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF212121),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: Colors.grey.shade100,
                            strokeWidth: 1,
                          ),
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                String text = '';
                                if (value == 0) text = '0';
                                else if (value == 1000) text = '1K';
                                else if (value == 2000) text = '2K';
                                else if (value == 3000) text = '3K';
                                return Text(
                                  text,
                                  style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 400),
                              FlSpot(1, 800),
                              FlSpot(2, 1200),
                              FlSpot(3, 900),
                              FlSpot(4, 2500),
                              FlSpot(5, 2200),
                            ],
                            isCurved: true,
                            color: const Color(0xFF2874F0),
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFF2874F0),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF2874F0).withOpacity(0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ──── Recent Orders ────
                  if (recentOrders.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Orders',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        GestureDetector(
                          onTap: onGoToOrders,
                          child: Text('See all',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF2874F0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...recentOrders.map((o) {
                      final status = o['status'] as String? ?? 'PENDING';
                      final amount = double.tryParse(
                              o['totalAmount']?.toString() ?? '0') ??
                          0;
                      final orderId = o['id']?.toString() ?? '';
                      final shortId = orderId.length > 8
                          ? orderId.substring(0, 8).toUpperCase()
                          : orderId.toUpperCase();

                      Color statusColor;
                      switch (status) {
                        case 'PENDING':
                          statusColor = Colors.orange;
                          break;
                        case 'CONFIRMED':
                          statusColor = const Color(0xFF2874F0);
                          break;
                        case 'DELIVERED':
                          statusColor = const Color(0xFF388E3C);
                          break;
                        case 'CANCELLED':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #$shortId…',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF212121),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  o['deliveryZone'] ?? '-',
                                  style: GoogleFonts.inter(
                                      color: const Color(0xFF878787),
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF212121),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status,
                                    style: GoogleFonts.inter(
                                        color: statusColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ]),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}



Widget _buildQuickAction(
  BuildContext context,
  String label,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF212121),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String actionText;
  final VoidCallback? onTap;

  const _StatCard(
    this.title,
    this.value,
    this.icon,
    this.color, {
    required this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F3F6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF212121),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF878787),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  actionText,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2874F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2874F0),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
