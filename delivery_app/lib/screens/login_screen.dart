import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/delivery_service.dart';
import 'otp_screen.dart';

const _primary = Color(0xFFFF6B9D);
const _primaryDark = Color(0xFFE0497A);
const _accent = Color(0xFFFFB800);
const _bgTop = Color(0xFFFFF0F6);
const _bgBot = Color(0xFFFFF8FC);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  int _authTab = 0; // 0 = Email, 1 = Phone OTP
  bool _isLogin = true;
  bool _obscure = true;

  final _phoneOrEmailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _phoneOrEmailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final auth = context.read<AuthProvider>();
    final input = _phoneOrEmailCtrl.text.trim();
    if (input.isEmpty || _passCtrl.text.isEmpty) { _showError('Please fill all required fields'); return; }
    bool success;
    if (_isLogin) {
      success = await auth.login(input, _passCtrl.text);
    } else {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) { _showError('Please enter your full name'); return; }
      success = await auth.register(input, _passCtrl.text, name);
    }
    if (!success && mounted) _showError(auth.error ?? 'Authentication failed');
  }

  Future<void> _submitPhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) { _showError('Please enter your phone number'); return; }
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(phone);
    if (sent && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
    } else if (mounted) {
      _showError(auth.error ?? 'Failed to send OTP');
    }
  }

  void _quickFill(String loginVal, String password, {bool mockMode = false}) {
    setState(() {
      DeliveryService.useMockData = mockMode;
      _phoneOrEmailCtrl.text = loginVal;
      _passCtrl.text = password;
      _isLogin = true;
      _authTab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Prefilled: $loginVal (Mock: ${mockMode ? "ON" : "OFF"})'),
      backgroundColor: mockMode ? Colors.amber.shade800 : _primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bgTop, _bgBot]),
        ),
        child: Stack(
          children: [
            Positioned(top: 40, left: 10, child: CustomPaint(size: const Size(100, 100), painter: DotPatternPainter())),
            Positioned(top: 40, right: 10, child: CustomPaint(size: const Size(100, 100), painter: DotPatternPainter())),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(children: [
                      _buildLogo(),
                      const SizedBox(height: 24),
                      _buildCard(auth),
                      const SizedBox(height: 16),
                      _buildQuickLoginPanel(),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() => Column(children: [
        Container(
          height: 80,
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/logo_banner.jpg', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 12),
        Text('DELIVERY PORTAL',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 2.0)),
      ]);

  Widget _buildCard(AuthProvider auth) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildAuthMethodTabs(),
            const SizedBox(height: 24),
            Text(
              _authTab == 0 ? (_isLogin ? 'Welcome back!' : 'Join as Partner') : 'Phone Login',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              _authTab == 0
                  ? (_isLogin ? 'Sign in to continue to your account' : 'Register as a delivery partner')
                  : 'Get a one-time code to your phone',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _authTab == 0 ? _buildEmailForm(auth) : _buildPhoneSection(auth),
            ),
          ]),
        ),
      );

  Widget _buildAuthMethodTabs() => Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          _methodTab(0, Icons.email_outlined, 'Email'),
          _methodTab(1, Icons.phone_outlined, 'Phone OTP'),
        ]),
      );

  Widget _methodTab(int index, IconData icon, String label) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _authTab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: _authTab == index ? LinearGradient(colors: [_primary, _primaryDark]) : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _authTab == index
                  ? [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: _authTab == index ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                  color: _authTab == index ? Colors.white : const Color(0xFF64748B))),
            ]),
          ),
        ),
      );

  Widget _buildEmailForm(AuthProvider auth) => Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _subTab('Sign In', _isLogin, () => setState(() => _isLogin = true)),
            const SizedBox(width: 16),
            _subTab('Register', !_isLogin, () => setState(() => _isLogin = false)),
          ]),
          const SizedBox(height: 20),
          if (!_isLogin) ...[_input(_nameCtrl, 'Full Name', Icons.person_outline_rounded), const SizedBox(height: 14)],
          _input(_phoneOrEmailCtrl, 'Phone Number / Email', Icons.phone_android_rounded, type: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _input(_passCtrl, 'Password', Icons.lock_outline_rounded, obscure: _obscure, suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
            onPressed: () => setState(() => _obscure = !_obscure),
          )),
          const SizedBox(height: 20),
          _primaryBtn(auth.loading ? null : _submitEmail, auth.loading, _isLogin ? 'Sign In' : 'Register Now'),
        ],
      );

  Widget _subTab(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _primary : const Color(0xFF64748B))),
          const SizedBox(height: 4),
          AnimatedContainer(duration: const Duration(milliseconds: 200), height: 2, width: active ? 40 : 0,
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(1))),
        ]),
      );

  Widget _buildPhoneSection(AuthProvider auth) => Column(
        key: const ValueKey('phone'),
        children: [
          const SizedBox(height: 8),
          _input(_phoneCtrl, 'Phone Number (+91XXXXXXXXXX)', Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 20),
          _primaryBtn(auth.loading ? null : _submitPhone, auth.loading, 'Send OTP'),
          const SizedBox(height: 12),
          Text('A 6-digit code will be sent to verify your number.',
              textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
        ],
      );

  Widget _input(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false, TextInputType? type, Widget? suffix}) =>
      TextFormField(
        controller: ctrl, obscureText: obscure, keyboardType: type,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label, labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)), suffixIcon: suffix,
          filled: true, fillColor: const Color(0xFFF8FAFC), isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  Widget _primaryBtn(VoidCallback? onTap, bool loading, String label) => SizedBox(
        width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primary, _primaryDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onTap,
            child: loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ]),
          ),
        ),
      );

  Widget _buildQuickLoginPanel() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.offline_bolt_rounded, color: _accent, size: 20),
            const SizedBox(width: 8),
            Text('QUICK LOGIN / TEST CONTROLS',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Mock Data (Standalone)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            Switch.adaptive(
              value: DeliveryService.useMockData,
              activeTrackColor: _primary,
              onChanged: (val) {
                setState(() => DeliveryService.useMockData = val);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Mock Data: ${val ? "Enabled" : "Disabled"}'),
                  backgroundColor: val ? _accent : _primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ));
              },
            ),
          ]),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Text('Autofill Credentials:', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _quickFillBtn('Mock Agent', () => _quickFill('+91 99999 99999', 'password123', mockMode: true), Colors.amber.shade700),
            _quickFillBtn('Injmam (Live)', () => _quickFill('injmam@gmail.com', 'password123'), _primary),
            _quickFillBtn('Nafeesh (Live)', () => _quickFill('knafeesh32@gmail.com', 'password123'), _primary),
          ]),
        ]),
      );

  Widget _quickFillBtn(String label, VoidCallback onPressed, Color color) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1), foregroundColor: color,
          shadowColor: Colors.transparent, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

// ── Custom Painters (preserved) ────────────────────────────────────────────
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B9D).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const double spacing = 12.0;
    const double radius = 1.5;
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 6; j++) {
        canvas.drawCircle(Offset(i * spacing + 12, j * spacing + 12), radius, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
