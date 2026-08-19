import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    try {
      final txs = await ApiService.get('/credit-ledger/wholesaler/transactions') as List? ?? [];
      // Filter for PAYMENT type
      final paymentsOnly = txs.where((tx) =>
          tx['type']?.toString().toUpperCase() == 'PAYMENT').toList();
      setState(() {
        _payments = paymentsOnly;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2874F0),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Payment History',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        color: const Color(0xFF2874F0),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2874F0)),
              )
            : _payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No payment history yet',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF878787),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Payments recorded will appear here',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final pay = _payments[index];
                      final amount = double.tryParse(pay['amount']?.toString() ?? '0') ?? 0;
                      final txId = pay['id']?.toString().substring(0, 8).toUpperCase() ?? '';
                      final note = pay['note']?.toString() ?? '';
                      final dateStr = pay['createdAt'] != null
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                              .format(DateTime.parse(pay['createdAt']).toLocal())
                          : '';

                      final retailerName = pay['ledger']?['retailer']?['user']?['name'] ??
                          pay['ledger']?['retailerName'] ??
                          'Retailer';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      retailerName,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF212121),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat('#,##,##0.00').format(amount)}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF388E3C),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF878787),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'PAID',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF388E3C),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 0.5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.isNotEmpty ? 'Note: $note' : 'Manual Payment',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF878787),
                                        fontSize: 12,
                                        fontStyle: note.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'ID: #$txId',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
