import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'orders_screen.dart';
import 'membership_webview_screen.dart';
import 'login_screen.dart';
import 'location_picker_screen.dart';
import 'package:core/widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;

  // Form fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _zoneName;
  double _lat = 12.9716;
  double _lng = 77.5946;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _shopNameCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/retailers/profile') as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          _nameCtrl.text = data['user']?['name'] ?? '';
          _emailCtrl.text = data['user']?['email'] ?? '';
          _phoneCtrl.text = data['user']?['phone'] ?? '';
          _shopNameCtrl.text = data['shopName'] ?? '';
          _gstCtrl.text = data['gstNumber'] ?? '';
          _addressCtrl.text = data['address'] ?? '';
          _zoneName = data['zone']?['name'] ?? 'Zone-South-BLR';
          _lat = double.tryParse(data['latitude']?.toString() ?? '12.9716') ?? 12.9716;
          _lng = double.tryParse(data['longitude']?.toString() ?? '77.5946') ?? 77.5946;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      await ApiService.patch('/retailers/profile', {
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'shopName': _shopNameCtrl.text,
        'gstNumber': _gstCtrl.text,
        'address': _addressCtrl.text,
        'latitude': _lat,
        'longitude': _lng,
      });
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF0071DC),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showMapPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat,
          initialLng: _lng,
          initialAddress: _addressCtrl.text,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _addressCtrl.text = result.fullAddress;
      });
    }
  }



  void _showHelpSupportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071DC).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0071DC)),
                ),
                const SizedBox(width: 12),
                Text('Help & Support', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            Text('How can we help your store today?', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Color(0xFF0071DC)),
              title: Text('FAQs & Guidelines', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Order processing, delivery time & payments', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF0071DC)),
              title: Text('Live Chat with Support', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('Available 9 AM - 9 PM daily', style: GoogleFonts.inter(fontSize: 12)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog(String title, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0071DC)),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toll-Free Helpline:', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(phone, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0071DC))),
            const SizedBox(height: 8),
            Text('Click below to copy phone number or initiate call.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071DC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: Text('Copy Number', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied $phone to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out from your retailer account?',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.share_rounded, color: Color(0xFF0071DC)),
            const SizedBox(width: 10),
            Text('Share Zone Store App', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite neighboring retail shops to join Zone Store and unlock extra group discounts!', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'https://zonestore.app/referral/retailer-105',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0071DC)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071DC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: Text('Copy Link', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'https://zonestore.app/referral/retailer-105'));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Referral link copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setRatingState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text('Rate Us on App Store', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience ordering stock on Zone Store?', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFB800),
                      size: 36,
                    ),
                    onPressed: () {
                      setRatingState(() => rating = index + 1);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071DC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for rating us $rating stars!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Submit Rating', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: const Color(0xFF334155)),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071DC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Got It', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0071DC))),
      );
    }

    final auth = context.watch<AuthProvider>();
    final userName = auth.user?['name'] ?? (_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Retailer');
    final profileInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'R';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. App Header matching Browse & Category screens
          SliverToBoxAdapter(
            child: AppHeader(
              appName: "ZONESUPPLY",
              tagline: "Retail, Simplified",
              userName: userName,
              subtitleLabel: "$userName's Store",
              subtitleIcon: Icons.store_outlined,
              notificationCount: 4,
              profileInitial: profileInitial,
              isCompact: true,
              isLight: true,
              onNotificationTap: () {},
              onProfileTap: () {},
            ),
          ),

          // 2. Section Header Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE2EDFD), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'MY STORE PROFILE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _shopNameCtrl.text.isNotEmpty ? _shopNameCtrl.text : "Zone Store",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0071DC),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Profile Content Body List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([


          // 2. Orders & Transactions Section
          _buildSectionHeader('ORDERS & TRANSACTIONS'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0071DC).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0071DC), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Orders',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track shipments, invoices & order history',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Membership & Verification Section
          _buildSectionHeader('MEMBERSHIP & VERIFICATION'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MembershipWebViewScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF258CFB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_membership_rounded, color: Color(0xFF258CFB), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Membership Portal',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Apply for membership, upload KYC & check status',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Main Help & Support Menu (Exact items matching reference screenshot)
          _buildSectionHeader('HELP & SUPPORT'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            elevation: 0,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Store Locator',
                  onTap: _showMapPicker,
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Help and Support',
                  onTap: _showHelpSupportDialog,
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.phone_outlined,
                  title: 'Customer Care',
                  onTap: () => _showCallDialog('Customer Care', '1800-123-4567'),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Call Store Helpline',
                  onTap: () => _showCallDialog('Call Store Helpline', '1800-987-6543'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. About & Legal Group (Exact items matching reference screenshot)
          _buildSectionHeader('ABOUT & LEGAL'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            elevation: 0,
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Terms of use',
                  onTap: () => _showLegalDialog(
                    'Terms of Use',
                    'Welcome to Zone Store! By placing wholesale orders, you agree to our wholesale supply terms, zone consolidation policies, and 24-hour verification window for stock deliveries.',
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.share_outlined,
                  title: 'Share',
                  onTap: _showShareDialog,
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.star_border_rounded,
                  title: 'Rate Us on App Store',
                  onTap: _showRatingDialog,
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showLegalDialog(
                    'Privacy Policy',
                    'Zone Store values your store privacy. Your business details, GST records, and delivery locations are encrypted and protected under secure B2B data protection standards.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Streamlined Account & Business Details Card
          _buildSectionHeader('MY STORE DETAILS'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField('Shop Name', _shopNameCtrl, Icons.storefront_rounded),
                  const SizedBox(height: 12),
                  _buildTextField('Owner Name', _nameCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildTextField('Contact Phone', _phoneCtrl, Icons.phone_outlined),
                  const SizedBox(height: 12),
                  _buildTextField('GST Number', _gstCtrl, Icons.assignment_turned_in_outlined),
                  const SizedBox(height: 12),
                  _buildTextField('Delivery Address', _addressCtrl, Icons.location_on_outlined, maxLines: 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 6. Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0071DC),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text('Save Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _saveProfile,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    side: BorderSide(color: Colors.red.shade100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _handleLogout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ]),
      ),
    ),
  ],
),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0071DC).withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0071DC), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : Colors.grey.shade100,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0071DC), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Real Map Location Picker (OpenStreetMap — free, no API key)
// ─────────────────────────────────────────────────────────────────────────────
class _MapLocationPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const _MapLocationPicker({
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<_MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<_MapLocationPicker> {
  late MapController _mapController;
  late LatLng _pinLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinLocation = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0071DC),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Select Location',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pinLocation,
              initialZoom: 15,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && pos.center != null) {
                  setState(() => _pinLocation = pos.center!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zonesupply.retailer',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pinLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFE74C3C),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071DC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text('Confirm Location', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  Navigator.pop(context, {
                    'lat': _pinLocation.latitude,
                    'lng': _pinLocation.longitude,
                    'address': '${_pinLocation.latitude.toStringAsFixed(4)}, ${_pinLocation.longitude.toStringAsFixed(4)}',
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
