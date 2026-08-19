import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

// ─── Premium Color Palette ──────────────────────────────────────────────────
const _primary = Color(0xFF2563EB); // Royal Blue
const _primaryDark = Color(0xFF1D4ED8);
const _accent = Color(0xFF3B82F6); // Soft Blue Accent
const _bgTop = Color(0xFFEFF6FF); // Ultra Soft Blue Base
const _bgBot = Color(0xFFFFFFFF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  // 0 = Email, 1 = Phone OTP
  int _authTab = 0;
  bool _isLogin = true;
  bool _obscure = true;
  bool _rememberMe = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final auth = context.read<AuthProvider>();
    bool success;
    if (_isLogin) {
      success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      success = await auth.register(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    }
    if (!success && mounted) _showError(auth.error ?? 'Authentication failed');
  }

  Future<void> _submitPhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(phone);
    if (sent && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)));
    } else if (mounted) {
      _showError(auth.error ?? 'Failed to send OTP');
    }
  }

  Future<void> _submitGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (!success && mounted) _showError(auth.error ?? 'Google sign-in failed');
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBot],
          ),
        ),
        child: Stack(
          children: [
            // Abstract Wave Background Shapes & Blobs
            Positioned(top: -100, right: -50, child: _blob(260, _accent.withOpacity(0.12))),
            Positioned(top: 180, left: -80, child: _blob(220, _primary.withOpacity(0.06))),
            Positioned(bottom: -60, right: -60, child: _blob(300, _accent.withOpacity(0.08))),
            CustomPaint(
              size: Size.infinite,
              painter: _WavePainter(),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      children: [
                        _buildLogoHeader(),
                        const SizedBox(height: 24),
                        _buildGlassCard(auth),
                        const SizedBox(height: 28),
                        _buildFooterSupport(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.01),
            ],
          ),
        ),
      );


  Widget _buildLogoHeader() => Column(
        children: [
          // Logo banner image with size minimized as requested
          SizedBox(
            width: 80,
            height: 80,
            child: Image.asset('assets/images/zonesupply_logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            'WHOLESALER PORTAL',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
              letterSpacing: 2.5,
            ),
          ),
        ],
      );

  Widget _buildGlassCard(AuthProvider auth) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented toggle tabs
              _buildSegmentedToggle(),
              const SizedBox(height: 24),

              // Welcome Title
              Text(
                'Welcome Back!',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to your wholesaler account',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // Animated Form Toggle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _authTab == 0 ? _buildEmailForm(auth) : _buildPhoneForm(auth),
              ),
              
              const SizedBox(height: 20),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildSocialButtons(auth),
            ],
          ),
        ),
      );

  Widget _buildSegmentedToggle() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _toggleItem(0, 'Email'),
            _toggleItem(1, 'Phone OTP'),
          ],
        ),
      );

  Widget _toggleItem(int index, String label) {
    final isSelected = _authTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _authTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [_primary, _accent])
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(AuthProvider auth) => Column(
        key: const ValueKey('email_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _subTab('Sign In', _isLogin, () => setState(() => _isLogin = true)),
              const SizedBox(width: 16),
              _subTab('Register', !_isLogin, () => setState(() => _isLogin = false)),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isLogin) ...[
            _inputField(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 14),
          ],
          _inputField(_emailCtrl, 'Email Address', Icons.mail_outline_rounded, type: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _inputField(
            _passCtrl,
            'Password',
            Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 14),
          if (_isLogin)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember Me', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text('Forgot Password?', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
              ],
            ),
          const SizedBox(height: 20),
          _primaryButton(auth.loading ? null : _submitEmail, auth.loading, _isLogin ? 'Sign In' : 'Create Account'),
        ],
      );

  Widget _buildPhoneForm(AuthProvider auth) => Column(
        key: const ValueKey('phone_form'),
        children: [
          const SizedBox(height: 8),
          _inputField(_phoneCtrl, 'Phone Number (+91XXXXXXXXXX)', Icons.phone_android_rounded, type: TextInputType.phone),
          const SizedBox(height: 20),
          _primaryButton(auth.loading ? null : _submitPhone, auth.loading, 'Send OTP'),
          const SizedBox(height: 12),
          Text(
            'A 6-digit code will be sent to your phone number.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
        ],
      );

  Widget _subTab(String label, bool active, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _primary : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: active ? 40 : 0,
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(1)),
            ),
          ],
        ),
      );

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? type,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.5)),
        ),
      );

  Widget _primaryButton(VoidCallback? onTap, bool loading, String label) => SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onTap,
            child: loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      );

  Widget _buildDivider() => Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'or continue with',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      );

  Widget _buildSocialButtons(AuthProvider auth) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                child: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _primary)),
              ),
              label: Text(
                'Google',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              onPressed: auth.loading ? null : _submitGoogle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone_android_rounded, size: 16, color: _primary),
              label: Text(
                'Phone OTP',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              onPressed: () {
                setState(() => _authTab = 1);
              },
            ),
          ),
        ],
      );

  Widget _buildFooterSupport() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Need help? ', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          Text('Contact Support', style: GoogleFonts.inter(fontSize: 13, color: _primary, fontWeight: FontWeight.w700)),
        ],
      );
}

// ─── Custom Painter for Minimal Warehouse/Abstract Waves ─────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.15, size.width * 0.6, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.35, size.width, size.height * 0.3)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Subtle Grid/Warehouse grid dots
    final dotPaint = Paint()..color = const Color(0xFF2563EB).withOpacity(0.03);
    for (double i = 20; i < size.width; i += 24) {
      for (double j = 40; j < size.height * 0.4; j += 24) {
        canvas.drawCircle(Offset(i, j), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
