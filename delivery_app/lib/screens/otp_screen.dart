import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _primary = Color(0xFFFF6B9D);
const _primaryDark = Color(0xFFE0497A);

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _pinCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  int _resendCountdown = 60;
  Timer? _timer;
  bool _nameRequired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCountdown <= 1) {
        t.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pinCtrl.dispose();
    _nameCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_pinCtrl.text.length < 6) { _showSnack('Enter the 6-digit code', isError: true); return; }
    final auth = context.read<AuthProvider>();
    final name = _nameCtrl.text.trim();
    final success = await auth.verifyOtp(widget.phone, _pinCtrl.text, name: name.isEmpty ? null : name);
    if (!success && mounted) {
      _showSnack(auth.error ?? 'Invalid OTP', isError: true);
      setState(() => _nameRequired = true);
      _pinCtrl.clear();
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(widget.phone);
    if (sent && mounted) {
      _startCountdown();
      _pinCtrl.clear();
      _showSnack('OTP resent to ${widget.phone}');
    } else if (mounted) {
      _showSnack(auth.error ?? 'Failed to resend', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final defaultTheme = PinTheme(
      width: 52, height: 58,
      textStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: _primary),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCADD), width: 1.5),
      ),
    );
    final focusedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: _primary, width: 2),
        color: Colors.white,
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 10)],
      ),
    );
    final submittedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        color: _primary.withOpacity(0.08),
        border: Border.all(color: _primary, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF374151)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primary, _primaryDark]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 24),
                Text('Verify your phone',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                    children: [
                      const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                      TextSpan(text: widget.phone,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Pinput(
                  controller: _pinCtrl, length: 6,
                  defaultPinTheme: defaultTheme,
                  focusedPinTheme: focusedTheme,
                  submittedPinTheme: submittedTheme,
                  keyboardType: TextInputType.number,
                  onCompleted: (_) => _verify(),
                ),
                const SizedBox(height: 28),
                if (_nameRequired) ...[
                  Align(alignment: Alignment.centerLeft,
                    child: Text('What should we call you?',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151)))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Your full name (optional)',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF9CA3AF)),
                      filled: true, fillColor: const Color(0xFFF9FAFB), isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity, height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_primary, _primaryDark]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: auth.loading ? null : _verify,
                      child: auth.loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text('Verify & Login', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_resendCountdown > 0)
                  Text('Resend code in ${_resendCountdown}s',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)))
                else
                  GestureDetector(
                    onTap: auth.loading ? null : _resend,
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                        children: [
                          const TextSpan(text: "Didn't receive it? "),
                          TextSpan(text: 'Resend OTP',
                              style: const TextStyle(color: _primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
