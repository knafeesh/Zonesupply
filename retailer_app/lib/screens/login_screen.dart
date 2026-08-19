import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'membership_webview_screen.dart';

import 'package:url_launcher/url_launcher.dart';

// ── Light Blue Design System Palette ─────────────────────────────────────
const _primary     = Color(0xFF258CFB);
const _navyDark    = Color(0xFF0F172A);
const _blueAccent  = Color(0xFF0071DC);
const _bgTop       = Color(0xFFEBF4FE);
const _bgBot       = Color(0xFFF8FAFF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _membershipCtrl = TextEditingController();
  bool _agreedToTerms    = true;
  bool _loading          = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _membershipCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final membershipId = _membershipCtrl.text.trim();
    if (membershipId.isEmpty) {
      _showSnack('Please enter your Membership ID or Mobile Number', isError: true);
      return;
    }
    if (!_agreedToTerms) {
      _showSnack('Please agree to the Privacy Policy & Terms of Use', isError: true);
      return;
    }

    setState(() => _loading = true);

    // 1. Strict Membership Verification
    final memCheck = await ApiService.checkMembership(membershipId);

    if (memCheck['isApproved'] != true) {
      setState(() => _loading = false);
      if (!mounted) return;

      final status = memCheck['status']?.toString() ?? 'not_found';
      final msg = memCheck['message']?.toString() ?? 'Membership verification failed.';
      final isNetworkError = memCheck['success'] == false && status == 'not_found' &&
          (msg.contains('connect') || msg.contains('server') || msg.contains('Unable'));

      if (isNetworkError) {
        // Network / server unreachable — show retry dialog
        _showMembershipStatusDialog(
          title: 'Connection Error',
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
          message: 'Could not reach the membership server. Make sure you are connected to the same Wi-Fi as the server, then try again.',
          primaryBtnText: 'Retry',
          onPrimaryTap: () {
            Navigator.pop(context);
            _handleContinue();
          },
        );
      } else if (status == 'pending') {
        _showMembershipStatusDialog(
          title: 'Application Pending',
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.amber.shade700,
          bgColor: Colors.amber.shade50,
          message: msg,
          primaryBtnText: 'Track Status',
          onPrimaryTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MembershipWebViewScreen(
                  initialUrl: 'http://10.225.158.51:5173/check-status',
                ),
              ),
            );
          },
        );
      } else if (status == 'rejected') {
        _showMembershipStatusDialog(
          title: 'Application Rejected',
          icon: Icons.cancel_rounded,
          iconColor: Colors.red.shade700,
          bgColor: Colors.red.shade50,
          message: msg,
          primaryBtnText: 'Re-Apply Now',
          onPrimaryTap: () {
            Navigator.pop(context);
            _applyForMembership();
          },
        );
      } else {
        // Not found — genuine membership not registered
        _showMembershipStatusDialog(
          title: 'Membership Not Found',
          icon: Icons.lock_outline_rounded,
          iconColor: _primary,
          bgColor: Colors.blue.shade50,
          message: 'No approved membership found for "$membershipId". Please check your Membership ID or apply for membership.',
          primaryBtnText: 'Apply for Membership',
          onPrimaryTap: () {
            Navigator.pop(context);
            _applyForMembership();
          },
        );
      }
      return;
    }


    // 2. Member is APPROVED! Log in with real backend JWT
    final retailer = memCheck['retailer'] as Map<String, dynamic>?;
    final retailerName = retailer?['fullName'] ?? 'Member $membershipId';
    final mobileNumber = retailer?['mobile'] ?? membershipId;
    final retailerEmail = retailer?['email'] as String?;
    final shopName = retailer?['shopName'] as String?;
    final approvedMembershipId = memCheck['membershipId']?.toString() ?? membershipId;

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithMembership(
      mobile: mobileNumber,
      name: retailerName,
      membershipId: approvedMembershipId,
      email: retailerEmail,
      shopName: shopName,
    );

    setState(() => _loading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome, $retailerName! ($approvedMembershipId)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (mounted) {
      _showSnack(auth.error ?? 'Login failed', isError: true);
    }
  }

  void _showMembershipStatusDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String message,
    required String primaryBtnText,
    required VoidCallback onPrimaryTap,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _navyDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF475569),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: onPrimaryTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(primaryBtnText, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.red.shade700 : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _applyForMembership() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MembershipWebViewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // Top Wavy Gradient Overlay
            Positioned(
              top: 0, left: 0, right: 0,
              height: 180,
              child: CustomPaint(painter: _TopBackgroundPainter()),
            ),

            // Top Decorative Dot Grid Patterns
            Positioned(
              top: 70, left: 24,
              child: _buildDotGrid(),
            ),
            Positioned(
              top: 70, right: 24,
              child: _buildDotGrid(),
            ),

            // Bottom Wavy Curve
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 120,
              child: CustomPaint(painter: _BottomCurvePainter()),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeaderLogo(),
                          const SizedBox(height: 24),
                          _buildMemberCard(),
                          const SizedBox(height: 28),
                          _buildBottomMembershipLink(),
                        ],
                      ),
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

  // 3x4 Decorative Dot Grid
  Widget _buildDotGrid() => Column(
        children: List.generate(
          4,
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: List.generate(
                3,
                (c) => Container(
                  margin: const EdgeInsets.only(right: 5),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBFDBFE),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  // Top Header Logo & Branding
  Widget _buildHeaderLogo() => Column(
        children: [
          // 3D Blue Shopping Bag Emblem
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF60A5FA), Color(0xFF258CFB)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/zonesupply_logo.png',
                width: 68,
                height: 68,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_bag_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ZONE STORE Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ZONE ',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _navyDark,
                    letterSpacing: 1.0,
                  ),
                ),
                TextSpan(
                  text: 'STORE',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _blueAccent,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tagline with Side Lines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 24, height: 1.5, color: const Color(0xFF93C5FD)),
              const SizedBox(width: 8),
              Text(
                'Best Quality. Best Price. For Retailers.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 24, height: 1.5, color: const Color(0xFF93C5FD)),
            ],
          ),
        ],
      );

  // Center Light Blue Card
  Widget _buildMemberCard() => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0057D9).withValues(alpha: 0.10),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // User Icon Circle
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _blueAccent,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),

            // Member Login Title
            Text(
              'Member Login',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _blueAccent,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              'Login to access your account',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),

            // Membership ID Input Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0057D9).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: _blueAccent,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _membershipCtrl,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _navyDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Membership ID',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Checkbox Terms Row
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                    activeColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: _blueAccent,
                          ),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Terms of Use',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: _blueAccent,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Full-Width Continue Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );

  // Bottom Member Application Section
  Widget _buildBottomMembershipLink() => Column(
        children: [
          Text(
            'Don\'t have a Membership?',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          // Outlined Pill Button
          OutlinedButton(
            onPressed: _applyForMembership,
            style: OutlinedButton.styleFrom(
              foregroundColor: _blueAccent,
              backgroundColor: const Color(0xFFEFF6FF),
              side: const BorderSide(color: Color(0xFF93C5FD), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_outlined, size: 18, color: _blueAccent),
                const SizedBox(width: 8),
                Text(
                  'Apply for Membership',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// Background Wave Painters
class _TopBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.cubicTo(size.width * 0.7, size.height * 0.9, size.width * 0.3, size.height * 0.2, 0, size.height * 0.8);
    path.close();

    final paint = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.cubicTo(size.width * 0.4, size.height * 0.2, size.width * 0.75, size.height * 0.9, size.width, size.height * 0.4);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..color = const Color(0xFFBFDBFE).withValues(alpha: 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
