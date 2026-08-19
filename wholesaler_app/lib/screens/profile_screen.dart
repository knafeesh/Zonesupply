import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/wholesalers/profile');
      setState(() {
        _profile = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading profile: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<String?> _uploadImageFile(XFile file) async {
    try {
      final token = await ApiService.getToken();
      final uri = Uri.parse('${ApiService.baseUrl}/products/upload');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final extension = file.name.split('.').last.toLowerCase();
      String subtype = 'jpeg';
      if (extension == 'png') {
        subtype = 'png';
      } else if (extension == 'gif') {
        subtype = 'gif';
      } else if (extension == 'webp') {
        subtype = 'webp';
      } else if (extension == 'jpg') {
        subtype = 'jpeg';
      }

      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: MediaType('image', subtype),
      ));

      final response = await request.send();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        return data['url'] as String;
      }
    } catch (e) {
      debugPrint("File upload failed: $e");
    }
    return null;
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() => _uploading = true);
      final uploadedUrl = await _uploadImageFile(file);
      if (uploadedUrl != null) {
        // Update profile photo in backend
        final updated = await ApiService.patch('/wholesalers/profile', {
          'profilePicture': uploadedUrl,
        });
        setState(() {
          _profile = updated;
          _uploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Profile picture updated successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF388E3C),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else {
        setState(() => _uploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to upload image', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2874F0)),
              title: Text('Take Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2874F0)),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_profile == null) return;
    final user = _profile!['user'] ?? {};
    
    final nameCtrl = TextEditingController(text: user['name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final businessNameCtrl = TextEditingController(text: _profile!['businessName'] ?? '');
    final shopNumberCtrl = TextEditingController(text: _profile!['shopNumber'] ?? '');
    final gstNumberCtrl = TextEditingController(text: _profile!['gstNumber'] ?? '');
    final addressCtrl = TextEditingController(text: _profile!['address'] ?? '');

    bool saving = false;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Edit Profile Details',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Phone'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: businessNameCtrl,
                    decoration: const InputDecoration(labelText: 'Business Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: shopNumberCtrl,
                    decoration: const InputDecoration(labelText: 'Shop Number / Block'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: gstNumberCtrl,
                    decoration: const InputDecoration(labelText: 'GST Registration Number'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Pickup Location / Address'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2874F0),
                  foregroundColor: Colors.white,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
                        try {
                          final updated = await ApiService.patch('/wholesalers/profile', {
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'businessName': businessNameCtrl.text.trim(),
                            'shopNumber': shopNumberCtrl.text.trim(),
                            'gstNumber': gstNumberCtrl.text.trim(),
                            'address': addressCtrl.text.trim(),
                          });
                          setState(() {
                            _profile = updated;
                          });
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          messenger.showSnackBar(SnackBar(
                            content: Text('Profile updated successfully!',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF388E3C),
                            behavior: SnackBarBehavior.floating,
                          ));
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Error updating: $e', style: GoogleFonts.inter()),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2874F0)),
        ),
      );
    }

    final user = _profile?['user'] ?? {};
    final name = user['name'] ?? 'Wholesaler';
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? 'No contact number';
    final businessName = _profile?['businessName'] ?? 'No business name';
    final shopNumber = _profile?['shopNumber'] ?? 'Not set';
    final gstNumber = _profile?['gstNumber'] ?? 'Not set';
    final address = _profile?['address'] ?? 'Not set';
    final profilePicture = user['profilePicture'] as String?;

    String? fullPicUrl;
    if (profilePicture != null) {
      // Connect to same host as ApiService base
      final apiUri = Uri.parse(ApiService.baseUrl);
      fullPicUrl = '${apiUri.scheme}://${apiUri.host}:${apiUri.port}$profilePicture';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text('Store Profile',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: const Color(0xFF2874F0),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Gradient Section with Avatar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2874F0), Color(0xFF1557C0)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  // Photo upload wrapper
                  GestureDetector(
                    onTap: _uploading ? null : _showImageSourceSheet,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: fullPicUrl != null ? NetworkImage(fullPicUrl) : null,
                            child: fullPicUrl == null
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'W',
                                    style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2874F0)),
                                  )
                                : null,
                          ),
                        ),
                        if (_uploading)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC200),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF212121)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    businessName,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Profile info cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edit Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Account Information',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF212121),
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF2874F0)),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text('Edit Profile',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                        onPressed: _showEditProfileDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Store details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline_rounded, 'Owner Name', name),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.phone_outlined, 'Contact Number', phone),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.storefront_outlined, 'Shop Number / Block', shopNumber),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.verified_user_outlined, 'GST Number', gstNumber),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.location_on_outlined, 'Pickup Location', address, isMultiLine: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text('Logout',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await context.read<AuthProvider>().logout();
                        navigator.popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isMultiLine = false}) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF878787), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.inter(
                    color: const Color(0xFF212121),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
