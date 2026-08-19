import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapRouteScreen extends StatefulWidget {
  final Map<String, dynamic> batch;
  const MapRouteScreen({super.key, required this.batch});
  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  int _step = 0; // 0=heading, 1=pickup, 2=delivering, 3=done
  final _steps = ['Head to Wholesaler', 'Pick Up Packages', 'Deliver to Zone', 'Completed!'];
  final _stepIcons = [
    Icons.directions_run_rounded,
    Icons.inventory_2_rounded,
    Icons.local_shipping_rounded,
    Icons.check_circle_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
      duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final zone = widget.batch['deliveryZone'] as String? ?? 'Zone';
    final orderCount = widget.batch['orderCount'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Navigating to $zone', style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        // Map placeholder with animated ping
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFECEFF1), // Light map background
            child: Stack(alignment: Alignment.center, children: [
              // Simulated map grid lines
              CustomPaint(painter: _MapGridPainter(), child: Container()),

              // Animated ping
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2874F0).withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2874F0),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
              ),

              // Info overlay
              Positioned(
                top: 16, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation_rounded,
                        color: Color(0xFF2874F0), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Simulated Route Running', style: GoogleFonts.inter(
                          color: const Color(0xFF212121), fontWeight: FontWeight.w700,
                          fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Connect Google Maps API to enable live navigation',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF878787), fontSize: 10, fontWeight: FontWeight.w500)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('~${orderCount * 15} min',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE65100),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // Step tracker
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              )
            ]
          ),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Delivery Progress', style: GoogleFonts.inter(
              color: const Color(0xFF212121), fontSize: 16,
              fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Steps
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_steps.length, (i) {
              final done = i < _step;
              final current = i == _step;
              
              Color iconBgColor = const Color(0xFFF5F5F5);
              Color iconColor = const Color(0xFF878787);
              Color borderColor = const Color(0xFFE0E0E0);
              Color textColor = const Color(0xFF878787);
              FontWeight textWeight = FontWeight.w500;

              if (done) {
                iconBgColor = const Color(0xFFE8F5E9);
                iconColor = const Color(0xFF388E3C);
                borderColor = const Color(0xFFC8E6C9);
                textColor = const Color(0xFF388E3C);
                textWeight = FontWeight.w600;
              } else if (current) {
                iconBgColor = const Color(0xFFE3F2FD);
                iconColor = const Color(0xFF2874F0);
                borderColor = const Color(0xFF90CAF9);
                textColor = const Color(0xFF2874F0);
                textWeight = FontWeight.w700;
              }

              return Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconBgColor,
                    border: Border.all(
                      color: borderColor,
                      width: current ? 2 : 1,
                    ),
                  ),
                  child: Icon(_stepIcons[i], size: 22, color: iconColor),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(_steps[i], textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10, color: textColor, fontWeight: textWeight),
                  ),
                ),
              ]);
            })),
            const SizedBox(height: 24),

            // Action button
            if (_step < 3)
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB641B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  onPressed: () => setState(() => _step++),
                  child: Text(_step == 0 ? 'Confirm Arrival at Wholesaler'
                      : _step == 1 ? 'Confirm Pickup'
                      : 'Confirm Delivery',
                    style: GoogleFonts.inter(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              )
            else
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  label: Text('Job Complete! ✨',
                    style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Draw simulated roads in white
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    canvas.drawLine(Offset(size.width * 0.2, 0),
        Offset(size.width * 0.2, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.6, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.35),
        Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.65), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
