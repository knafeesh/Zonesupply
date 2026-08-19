import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();

    // Navigate to Onboarding after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom Light Blue Wavy Gradient Waves
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: MediaQuery.of(context).size.height * 0.32,
            child: CustomPaint(
              painter: _WavePainter(),
            ),
          ),

          // Floating Subtle Outline Icons (Cart, Tag, Discount, Box)
          Positioned(
            left: 45, bottom: MediaQuery.of(context).size.height * 0.28,
            child: Opacity(
              opacity: 0.25,
              child: Icon(Icons.shopping_cart_outlined, color: const Color(0xFF60A5FA), size: 30),
            ),
          ),
          Positioned(
            left: 130, bottom: MediaQuery.of(context).size.height * 0.25,
            child: Opacity(
              opacity: 0.25,
              child: Icon(Icons.local_offer_outlined, color: const Color(0xFF60A5FA), size: 28),
            ),
          ),
          Positioned(
            right: 125, bottom: MediaQuery.of(context).size.height * 0.23,
            child: Opacity(
              opacity: 0.25,
              child: Icon(Icons.percent_rounded, color: const Color(0xFF60A5FA), size: 34),
            ),
          ),
          Positioned(
            right: 45, bottom: MediaQuery.of(context).size.height * 0.29,
            child: Opacity(
              opacity: 0.25,
              child: Icon(Icons.inventory_2_outlined, color: const Color(0xFF60A5FA), size: 32),
            ),
          ),

          // Center Logo & Text Content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ZS Logo
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Image.asset(
                          'assets/images/zonesupply_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // MY ZONE SUPPLY
                      Text(
                        'MY ZONE',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF60A5FA),
                          letterSpacing: 2.0,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'STORE',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF60A5FA),
                          letterSpacing: 2.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // — Smart Supply, Better Business —
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 24, height: 1.5, color: const Color(0xFF93C5FD)),
                          const SizedBox(width: 8),
                          Text(
                            'Smart Supply, Better Business',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 24, height: 1.5, color: const Color(0xFF93C5FD)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Light Blue Soft Background Waves
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.cubicTo(size.width * 0.25, size.height * 0.1, size.width * 0.65, size.height * 0.6, size.width, size.height * 0.3);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    final paint1 = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.7);
    canvas.drawPath(path1, paint1);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);
    path2.cubicTo(size.width * 0.3, size.height * 0.35, size.width * 0.7, size.height * 0.75, size.width, size.height * 0.45);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.75);
    canvas.drawPath(path2, paint2);

    final path3 = Path();
    path3.moveTo(0, size.height * 0.7);
    path3.cubicTo(size.width * 0.35, size.height * 0.6, size.width * 0.75, size.height * 0.85, size.width, size.height * 0.65);
    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();

    final paint3 = Paint()
      ..color = const Color(0xFFBFDBFE).withValues(alpha: 0.85);
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
