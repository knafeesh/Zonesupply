import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'payment_history_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List _retailers = [];
  List _transactions = [];
  List _filteredTransactions = [];
  Map<String, String> _txStatuses = {};
  bool _loading = true;

  double _totalOutstanding = 0.0;
  double _receivedPayments = 0.0;
  int _totalTransactionsCount = 0;

  // Filter States
  String _activeTab = 'All'; // All, Payments, Credit, Debit
  String _searchQuery = '';
  String _dateFilter = 'All'; // All, Today, This Week, This Month, Custom
  DateTimeRange? _customDateRange;

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
      // 1. Fetch outstanding retailer accounts
      final ledgers = await ApiService.get('/credit-ledger/wholesaler/outstanding') as List? ?? [];
      
      // 2. Fetch all transactions
      final txs = await ApiService.get('/credit-ledger/wholesaler/transactions') as List? ?? [];

      double totalOut = 0.0;
      for (final r in ledgers) {
        totalOut += double.tryParse(r['outstandingBalance']?.toString() ?? '0') ?? 0;
      }

      double recPay = 0.0;
      for (final tx in txs) {
        final type = tx['type']?.toString().toUpperCase() ?? '';
        if (type == 'PAYMENT') {
          recPay += double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
        }
      }

      // Compute dynamic status badges via FIFO matching algorithm
      final statuses = _computeTxStatuses(ledgers, txs);

      setState(() {
        _retailers = ledgers;
        _transactions = txs;
        _txStatuses = statuses;
        _totalOutstanding = totalOut;
        _receivedPayments = recPay;
        _totalTransactionsCount = txs.length;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      debugPrint("Error loading ledger data: $e");
      setState(() => _loading = false);
    }
  }

  Map<String, String> _computeTxStatuses(List ledgers, List transactions) {
    final Map<String, double> retailerOutstandingMap = {};
    for (final r in ledgers) {
      final rId = r['retailer']?['id']?.toString() ?? r['retailerId']?.toString() ?? '';
      if (rId.isNotEmpty) {
        retailerOutstandingMap[rId] = double.tryParse(r['outstandingBalance']?.toString() ?? '0') ?? 0.0;
      }
    }

    final Map<String, String> statuses = {};

    // Group transactions by retailerId
    final Map<String, List> txsByRetailer = {};
    for (final tx in transactions) {
      final rId = tx['ledger']?['retailerId']?.toString() ?? '';
      if (rId.isNotEmpty) {
        txsByRetailer.putIfAbsent(rId, () => []).add(tx);
      }
    }

    // Process each retailer's debits dynamically using FIFO
    txsByRetailer.forEach((rId, rTxs) {
      // Sort chronologically ascending (oldest first) to run FIFO simulation
      rTxs.sort((a, b) {
        final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return da.compareTo(db);
      });

      double remainingOutstanding = retailerOutstandingMap[rId] ?? 0.0;

      // We process backwards (from newest to oldest) to match outstanding balances
      final reversedTxs = rTxs.reversed.toList();
      for (final tx in reversedTxs) {
        final txId = tx['id']?.toString() ?? '';
        final type = tx['type']?.toString().toUpperCase() ?? '';

        if (type == 'PAYMENT' || type == 'CREDIT' || type == 'REVERSAL') {
          statuses[txId] = 'Paid';
        } else if (type == 'DEBIT') {
          final amt = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
          if (remainingOutstanding > 0) {
            final unpaid = amt < remainingOutstanding ? amt : remainingOutstanding;
            remainingOutstanding -= unpaid;
            if (unpaid > 0) {
              final date = DateTime.tryParse(tx['createdAt']?.toString() ?? '') ?? DateTime.now();
              final diff = DateTime.now().difference(date).inDays;
              if (diff > 14) {
                statuses[txId] = 'Overdue';
              } else {
                statuses[txId] = 'Pending';
              }
            } else {
              statuses[txId] = 'Paid';
            }
          } else {
            statuses[txId] = 'Paid';
          }
        } else {
          statuses[txId] = 'Paid';
        }
      }
    });

    return statuses;
  }

  void _applyFilters() {
    List filtered = List.from(_transactions);

    // 1. Apply Tab Filter (All, Payments, Credit, Debit)
    if (_activeTab == 'Payments') {
      filtered = filtered.where((tx) => tx['type']?.toString().toUpperCase() == 'PAYMENT').toList();
    } else if (_activeTab == 'Credit') {
      filtered = filtered.where((tx) => tx['type']?.toString().toUpperCase() == 'CREDIT').toList();
    } else if (_activeTab == 'Debit') {
      filtered = filtered.where((tx) => tx['type']?.toString().toUpperCase() == 'DEBIT').toList();
    }

    // 2. Apply Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((tx) {
        final retailerName = (tx['ledger']?['retailer']?['user']?['name']?.toString() ?? '').toLowerCase();
        final txId = (tx['id']?.toString() ?? '').toLowerCase();
        final note = (tx['note']?.toString() ?? '').toLowerCase();
        return retailerName.contains(query) || txId.contains(query) || note.contains(query);
      }).toList();
    }

    // 3. Apply Date Filter
    final now = DateTime.now();
    if (_dateFilter == 'Today') {
      filtered = filtered.where((tx) {
        final date = DateTime.tryParse(tx['createdAt']?.toString() ?? '')?.toLocal();
        if (date == null) return false;
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }).toList();
    } else if (_dateFilter == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final cleanStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      filtered = filtered.where((tx) {
        final date = DateTime.tryParse(tx['createdAt']?.toString() ?? '')?.toLocal();
        if (date == null) return false;
        return date.isAfter(cleanStart) || date.isAtSameMomentAs(cleanStart);
      }).toList();
    } else if (_dateFilter == 'This Month') {
      filtered = filtered.where((tx) {
        final date = DateTime.tryParse(tx['createdAt']?.toString() ?? '')?.toLocal();
        if (date == null) return false;
        return date.year == now.year && date.month == now.month;
      }).toList();
    } else if (_dateFilter == 'Custom' && _customDateRange != null) {
      final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      filtered = filtered.where((tx) {
        final date = DateTime.tryParse(tx['createdAt']?.toString() ?? '')?.toLocal();
        if (date == null) return false;
        return date.isAfter(start) && date.isBefore(end);
      }).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _showAddDialog({required bool isPayment}) {
    if (_retailers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No retailers available to create entries for.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    String? selectedRetailerId = _retailers.first['retailer']?['id']?.toString() ?? _retailers.first['retailerId']?.toString();
    String entryType = isPayment ? 'PAYMENT' : 'DEBIT'; // Default type for ledger entry is DEBIT
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isPayment ? 'Add Payment' : 'Add Ledger Entry',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRetailerId,
                  decoration: InputDecoration(
                    labelText: 'Select Retailer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _retailers.map((r) {
                    final name = r['retailer']?['user']?['name'] ?? r['retailerName'] ?? 'Retailer';
                    final id = r['retailer']?['id']?.toString() ?? r['retailerId']?.toString() ?? '';
                    return DropdownMenuItem(value: id, child: Text(name));
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedRetailerId = val);
                  },
                ),
                const SizedBox(height: 16),
                if (!isPayment) ...[
                  DropdownButtonFormField<String>(
                    initialValue: entryType,
                    decoration: InputDecoration(
                      labelText: 'Entry Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DEBIT', child: Text('Debit (Owes Money)')),
                      DropdownMenuItem(value: 'CREDIT', child: Text('Credit (Reduces Debt)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => entryType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: amtCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Note / Reference',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
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
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter a valid amount.'),
                  ));
                  return;
                }
                if (selectedRetailerId == null) return;

                Navigator.pop(dialogCtx);
                setState(() => _loading = true);

                try {
                  await ApiService.post('/credit-ledger/transaction', {
                    'retailerId': selectedRetailerId,
                    'amount': amount,
                    'type': isPayment ? 'PAYMENT' : entryType,
                    'note': noteCtrl.text.trim(),
                  });
                  await _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Ledger entry recorded successfully!'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error recording transaction: $e'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              child: Text('Record', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
              'Ledger Operations',
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
                  color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded, color: Color(0xFF388E3C)),
              ),
              title: Text('Add Payment', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              subtitle: Text('Record payments received from retailers', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddDialog(isPayment: true);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.border_color_rounded, color: Color(0xFF2874F0)),
              ),
              title: Text('Add Ledger Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              subtitle: Text('Manually record debits or credit claims', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddDialog(isPayment: false);
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
            // App bar
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: const Color(0xFF2874F0),
              foregroundColor: Colors.white,
              title: Text(
                'Ledger Account',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                  tooltip: 'Payment History',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
                    );
                  },
                ),
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

            // Main stats and filters adapter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Scroll
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildStatCard(
                            title: 'Pending Payments',
                            value: '₹${NumberFormat('#,##,##0').format(_totalOutstanding)}',
                            color: Colors.red.shade600,
                            bgColor: Colors.red.shade50,
                            icon: Icons.pending_actions_rounded,
                          ),
                          _buildStatCard(
                            title: 'Received Payments',
                            value: '₹${NumberFormat('#,##,##0').format(_receivedPayments)}',
                            color: const Color(0xFF388E3C),
                            bgColor: Colors.green.shade50,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                          _buildStatCard(
                            title: 'Total Transactions',
                            value: '$_totalTransactionsCount',
                            color: const Color(0xFF2874F0),
                            bgColor: const Color(0xFF2874F0).withValues(alpha: 0.08),
                            icon: Icons.history_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search and Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search retailer or transaction',
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
                        ),
                        const SizedBox(width: 8),
                        // Filter Dropdown Icon
                        PopupMenuButton<String>(
                          icon: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: _dateFilter != 'All' ? const Color(0xFF2874F0).withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dateFilter != 'All' ? const Color(0xFF2874F0) : Colors.grey.shade200,
                              ),
                            ),
                            child: Icon(
                              Icons.filter_list_rounded,
                              color: _dateFilter != 'All' ? const Color(0xFF2874F0) : Colors.grey.shade600,
                            ),
                          ),
                          onSelected: (val) async {
                            if (val == 'Custom') {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2028),
                                initialDateRange: _customDateRange,
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateFilter = 'Custom';
                                  _customDateRange = picked;
                                });
                                _applyFilters();
                              }
                            } else {
                              setState(() {
                                _dateFilter = val;
                                _customDateRange = null;
                              });
                              _applyFilters();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'All', child: Text('All Dates')),
                            const PopupMenuItem(value: 'Today', child: Text('Today')),
                            const PopupMenuItem(value: 'This Week', child: Text('This Week')),
                            const PopupMenuItem(value: 'This Month', child: Text('This Month')),
                            const PopupMenuItem(value: 'Custom', child: Text('Custom Date...')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Custom date range chip indicator
                    if (_dateFilter == 'Custom' && _customDateRange != null) ...[
                      Chip(
                        backgroundColor: const Color(0xFF2874F0).withValues(alpha: 0.1),
                        side: const BorderSide(color: Color(0xFF2874F0)),
                        label: Text(
                          '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}',
                          style: GoogleFonts.inter(color: const Color(0xFF2874F0), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onDeleted: () {
                          setState(() {
                            _dateFilter = 'All';
                            _customDateRange = null;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Tab bar row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Payments', 'Credit', 'Debit'].map((tab) {
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
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Loading details or transaction listings
            _loading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF2874F0)),
                    ),
                  )
                : _filteredTransactions.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF878787),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Payments and retailer records will appear here.',
                                  textAlign: TextAlign.center,
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
                              final tx = _filteredTransactions[i];
                              return _TransactionCard(
                                tx: tx,
                                status: _txStatuses[tx['id']] ?? 'Paid',
                              );
                            },
                            childCount: _filteredTransactions.length,
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

class _TransactionCard extends StatelessWidget {
  final Map tx;
  final String status;

  const _TransactionCard({required this.tx, required this.status});

  @override
  Widget build(BuildContext context) {
    final type = tx['type']?.toString().toUpperCase() ?? 'DEBIT';
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final isPayment = type == 'PAYMENT';
    final isCredit = type == 'CREDIT';
    final txId = tx['id']?.toString().substring(0, 8).toUpperCase() ?? '';
    final note = tx['note']?.toString() ?? '';
    final date = tx['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(tx['createdAt']).toLocal())
        : '';

    final retailerName = tx['ledger']?['retailer']?['user']?['name'] ??
        tx['ledger']?['retailerName'] ??
        'Retailer';

    // Status colors
    Color statusColor;
    Color statusBg;
    if (status == 'Overdue') {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
    } else if (status == 'Pending') {
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
    } else {
      statusColor = const Color(0xFF388E3C);
      statusBg = Colors.green.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPayment
                      ? const Color(0xFF388E3C).withValues(alpha: 0.1)
                      : isCredit
                          ? const Color(0xFF2874F0).withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPayment
                      ? Icons.arrow_downward_rounded
                      : isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                  color: isPayment
                      ? const Color(0xFF388E3C)
                      : isCredit
                          ? const Color(0xFF2874F0)
                          : Colors.red.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      retailerName,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF212121),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF878787),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment || isCredit ? '-' : '+'}₹${NumberFormat('#,##,##0.00').format(amount)}',
                    style: GoogleFonts.inter(
                      color: isPayment || isCredit ? const Color(0xFF388E3C) : Colors.red.shade700,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note.isNotEmpty
                      ? 'Note: $note'
                      : isPayment
                          ? 'Manual Payment'
                          : isCredit
                              ? 'Credit Adjustment'
                              : 'Ledger Entry',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF878787),
                    fontSize: 11,
                    fontStyle: note.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              Text(
                'ID: #$txId',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
