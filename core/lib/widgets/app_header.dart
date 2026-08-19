import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeader extends StatelessWidget {
  final String appName;          // "ZONESUPPLY" for all apps (same brand)
  final String tagline;          // "Wholesale, Simplified" / "Retail, Simplified" / "Deliver, Simplified"
  final String userName;        
  final String subtitleLabel;    
  final IconData subtitleIcon;   // Icons.storefront_outlined / Icons.store / Icons.two_wheeler_outlined
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;
  final String profileInitial;
  
  // optional: accent color override if each app wants slight tint difference
  final Color? accentColor;
  final String? backgroundImagePath;
  final VoidCallback? onSubtitleTap;
  final String? logoImagePath;
  final bool isCompact;
  final bool isLight;

  const AppHeader({
    super.key,
    required this.appName,
    required this.tagline,
    required this.userName,
    required this.subtitleLabel,
    required this.subtitleIcon,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onProfileTap,
    required this.profileInitial,
    this.accentColor,
    this.backgroundImagePath,
    this.onSubtitleTap,
    this.logoImagePath,
    this.isCompact = false,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color startColor = isLight
        ? const Color(0xFFE2EDFD) // Light blue
        : (accentColor ?? const Color(0xFF0057D9));
    final Color endColor = isLight
        ? const Color(0xFFF1F7FF) // Very light blue
        : (accentColor != null
            ? accentColor!.withOpacity(0.8)
            : const Color(0xFF003CBF));

    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subTextColor = isLight ? const Color(0xFF475569) : Colors.white70;
    final Color accentShapeColor = isLight
        ? const Color(0xFF0057D9).withOpacity(0.06)
        : Colors.white.withOpacity(0.08);

    return Container(
      constraints: BoxConstraints(minHeight: isCompact ? 140 : 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF0057D9).withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: endColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background decorative accent 1 (top right)
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentShapeColor,
              ),
            ),
          ),
          // Background decorative accent 2 (bottom left - hidden in compact mode)
          if (!isCompact)
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentShapeColor,
                ),
              ),
            ),
          // Background decorative accent 3 (bottom right - hidden in compact mode)
          if (!isCompact)
            Positioned(
              right: 40,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentShapeColor,
                ),
              ),
            ),
          // Optional Background Image (e.g. 3D trolley)
          if (backgroundImagePath != null && !isCompact)
            Positioned(
              right: -10,
              bottom: 0,
              top: 50,
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  backgroundImagePath!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  width: 170,
                ),
              ),
            ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: isCompact
                  ? const EdgeInsets.fromLTRB(20, 16, 20, 16)
                  : const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo + AppName/Tagline
                      Row(
                        children: [
                          if (logoImagePath != null) ...[
                            Image.asset(
                              logoImagePath!,
                              height: isCompact ? 34 : 42,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appName,
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: isCompact ? 15 : 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  tagline,
                                  style: GoogleFonts.inter(
                                    color: subTextColor,
                                    fontSize: isCompact ? 9 : 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              width: isCompact ? 28 : 36,
                              height: isCompact ? 28 : 36,
                              decoration: BoxDecoration(
                                color: isLight ? const Color(0xFF0057D9) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Z',
                                style: GoogleFonts.inter(
                                  color: isLight ? Colors.white : startColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isCompact ? 16 : 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appName,
                                  style: GoogleFonts.inter(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompact ? 15 : 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  tagline,
                                  style: GoogleFonts.inter(
                                    color: subTextColor,
                                    fontSize: isCompact ? 9 : 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      // Notifications + Profile
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onNotificationTap,
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: textColor,
                                  size: isCompact ? 22 : 26,
                                ),
                                if (notificationCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: isCompact ? 12 : 16,
                                        minHeight: isCompact ? 12 : 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$notificationCount',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isCompact ? 7 : 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: onProfileTap,
                            behavior: HitTestBehavior.opaque,
                            child: CircleAvatar(
                              radius: isCompact ? 14 : 18,
                              backgroundColor: isLight ? const Color(0xFF0057D9) : Colors.white,
                              child: Text(
                                profileInitial,
                                style: GoogleFonts.inter(
                                  color: isLight ? Colors.white : startColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isCompact ? 12 : 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 20),
                    // Welcome back + User name
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const SizedBox(height: 12),
                  ],
                  // Subtitle Row (Store/Storefront/Delivery Icon + Label + Chevron)
                  GestureDetector(
                    onTap: onSubtitleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          subtitleIcon,
                          color: subTextColor,
                          size: isCompact ? 14 : 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subtitleLabel,
                          style: GoogleFonts.inter(
                            color: subTextColor,
                            fontSize: isCompact ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subTextColor,
                          size: isCompact ? 14 : 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
