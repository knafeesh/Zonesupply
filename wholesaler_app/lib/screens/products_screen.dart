import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _products = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  bool _lowStockOnly = false;
  final _searchCtrl = TextEditingController();

  static const List<Map<String, String>> _imagePresets = [
    {
      'name': 'Grocery',
      'url': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Mobiles',
      'url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Fashion',
      'url': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=500&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Electronics',
      'url': 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=500&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Home',
      'url': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=500&auto=format&fit=crop&q=60'
    },
  ];

  /// All top-level categories
  static const List<String> _allCategories = [
    'Grocery', 'Mobiles', 'Fashion', 'Electronics', 'Home & Furniture',
    'Beauty', 'Kitchen', 'Fruits & Vegetables', 'Dairy & Bakery',
    'Stationery', 'Sports', 'Hardware',
  ];

  static const Map<String, List<String>> _subCategories = {
    'Grocery': ['Rice & Grains', 'Atta & Flours', 'Edible Oils', 'Spices & Masalas', 'Snacks & Packaged Food', 'Beverages'],
    'Mobiles': ['Smartphones', 'Keypad Phones', 'Mobile Chargers', 'Earphones & Headphones', 'Power Banks', 'Cases & Covers'],
    'Fashion': [
      'Fancy Saree',
      'Chiffon',
      'Suit-Unistitched',
      'Georgette',
      'Silk',
      'Cotton',
      'Lehenga',
      'Gowns',
      'Kurti/Set',
      'Men',
    ],
    'Electronics': ['Smart TVs', 'Speakers & Audio', 'Cameras', 'Power & Charging', 'Home Appliances'],
    'Home & Furniture': ['Bedding & Linens', 'Curtains & Cushions', 'Furniture', 'Home Decor', 'Lighting & Lamps'],
    'Beauty': ['Makeup & Cosmetics', 'Skincare', 'Haircare', 'Perfumes & Deos', 'Personal Care'],
    'Kitchen': ['Cookware & Pots', 'Tableware & Plates', 'Gas Stoves', 'Water Bottles', 'Kitchen Tools'],
    'Fruits & Vegetables': ['Fresh Vegetables', 'Fresh Fruits', 'Organic Greens', 'Exotic Produce'],
    'Dairy & Bakery': ['Milk & Cream', 'Butter & Cheese', 'Paneer & Tofu', 'Fresh Bread', 'Cakes & Muffins'],
    'Stationery': ['Notebooks & Diaries', 'Pens & Pencils', 'Office Supplies', 'Art & Craft', 'School Kits'],
    'Sports': ['Cricket Gear', 'Fitness & Gym', 'Badminton & Tennis', 'Indoor Games', 'Sports Wear'],
    'Hardware': ['Power Tools', 'Hand Tools', 'Screws & Nails', 'Electrical Supplies', 'Plumbing Fittings'],
  };

  static const Map<String, List<String>> _subSubCategories = {
    'Fashion > Kurti/Set': ['Kurti Set', 'Kurti', 'Coord Set', 'Plazo Set', 'Tops'],
    'Fashion > Men': ['T Shirt', 'Pent', 'Shirts', 'Lower', 'Jeans'],
  };

  static const Map<String, String> _categoryImages = {
    'All': 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=100&auto=format&fit=crop&q=60',
    'Grocery': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=120&auto=format&fit=crop&q=60',
    'Mobiles': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=120&auto=format&fit=crop&q=60',
    'Fashion': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=120&auto=format&fit=crop&q=60',
    'Electronics': 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=120&auto=format&fit=crop&q=60',
    'Home & Furniture': 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=120&auto=format&fit=crop&q=60',
    'Beauty': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=120&auto=format&fit=crop&q=60',
    'Kitchen': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=120&auto=format&fit=crop&q=60',
    'Fruits & Vegetables': 'https://images.unsplash.com/photo-1573244514212-2b3a14736758?w=120&auto=format&fit=crop&q=60',
    'Dairy & Bakery': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=120&auto=format&fit=crop&q=60',
    'Stationery': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=120&auto=format&fit=crop&q=60',
    'Sports': 'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=120&auto=format&fit=crop&q=60',
    'Hardware': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=120&auto=format&fit=crop&q=60',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.get('/products/my') as List? ?? [];
      setState(() {
        _products = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      setState(() => _loading = true);
      await ApiService.delete('/products/$id');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${p['name']}"? This cannot be undone.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF878787), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(p['id']);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
      } else {
        debugPrint("File upload status failed: ${response.statusCode}");
        final resBody = await response.stream.bytesToString();
        debugPrint("File upload error body: $resBody");
      }
    } catch (e) {
      debugPrint("File upload failed: $e");
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source, StateSetter setSheetState, List<String> imagesList) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        final uploadedUrl = await _uploadImageFile(file);
        if (uploadedUrl != null) {
          setSheetState(() {
            imagesList.add(uploadedUrl);
          });
        } else {
          final randomId = DateTime.now().millisecondsSinceEpoch % 1000;
          final mockUrl = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&mock=$randomId';
          setSheetState(() {
            imagesList.add(mockUrl);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Using mock captured photo (server offline)')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Camera/Gallery exception: $e");
      final randomId = DateTime.now().millisecondsSinceEpoch % 1000;
      final mockUrl = 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&mock=$randomId';
      setSheetState(() {
        imagesList.add(mockUrl);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hardware camera unavailable. Prefilled simulated capture.')),
        );
      }
    }
  }

  void _showImageSourceOptions(StateSetter setSheetState, List<String> imagesList) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Product Image',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF212121)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _OptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFF2874F0),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera, setSheetState, imagesList);
                    },
                  ),
                  _OptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF388E3C),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery, setSheetState, imagesList);
                    },
                  ),
                  _OptionButton(
                    icon: Icons.image_search_rounded,
                    label: 'Presets',
                    color: const Color(0xFFE056FD),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showPresetsSelector(setSheetState, imagesList);
                    },
                  ),
                  _OptionButton(
                    icon: Icons.link_rounded,
                    label: 'URL',
                    color: const Color(0xFFF1C40F),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showUrlInputPrompt(setSheetState, imagesList);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetsSelector(StateSetter setSheetState, List<String> imagesList) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select Image Preset', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: _imagePresets.length,
            itemBuilder: (context, idx) {
              final preset = _imagePresets[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  setSheetState(() {
                    imagesList.add(preset['url']!);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(preset['url']!, fit: BoxFit.cover),
                        Container(
                          color: Colors.black26,
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            preset['name']!,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showUrlInputPrompt(StateSetter setSheetState, List<String> imagesList) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter Image URL', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty) {
                setSheetState(() {
                  imagesList.add(url);
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog({Map<String, dynamic>? prefilledData}) {
    final nameCtrl = TextEditingController(text: prefilledData?['name']);
    final priceCtrl = TextEditingController(text: prefilledData?['pricePerUnit']?.toString());
    final stockCtrl = TextEditingController(text: prefilledData?['stockQuantity']?.toString());
    final unitCtrl = TextEditingController(text: prefilledData?['unit']);
    final discountCtrl = TextEditingController(text: prefilledData?['discount']?.toString() ?? '0');
    final barcodeCtrl = TextEditingController(text: prefilledData?['barcode'] ?? '');
    
    final specs = prefilledData?['specifications'] as Map<String, dynamic>? ?? {};
    final sizeCtrl = TextEditingController(text: specs['size']?.toString());
    final colorCtrl = TextEditingController(text: specs['color']?.toString());
    final brandCtrl = TextEditingController(text: specs['brand']?.toString());
    final fabricCtrl = TextEditingController(text: specs['fabric']?.toString());
    String? blousePiece = specs['blousePiece']?.toString();
    final sariStyleCtrl = TextEditingController(text: specs['sariStyle']?.toString());
    final warrantyCtrl = TextEditingController(text: specs['warranty']?.toString());

    final List<String> images = [];
    if (prefilledData?['imageUrl'] != null) {
      images.add(prefilledData!['imageUrl']);
    }
    // Parse existing category for pre-fill
    final existingCat = prefilledData?['category'] as String? ?? '';
    String? selectedCategory = _allCategories.contains(existingCat) ? existingCat : (existingCat.isNotEmpty ? existingCat.split(' > ').first : null);
    String? selectedSubCategory;
    String? selectedSubSubCategory;
    if (existingCat.contains(' > ')) {
      final parts = existingCat.split(' > ');
      selectedCategory = parts[0];
      selectedSubCategory = parts.length > 1 ? parts[1] : null;
      selectedSubSubCategory = parts.length > 2 ? parts[2] : null;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefilledData != null ? 'Add Scanned Product' : 'Add Product',
                  style: GoogleFonts.inter(color: const Color(0xFF212121), fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _inputField('Product Name', nameCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _inputField('Price (₹)', priceCtrl, type: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField('Stock', stockCtrl, type: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _inputField('Unit (e.g. kg/piece)', unitCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryDropdown(
                        label: 'Category',
                        value: selectedCategory,
                        items: _allCategories,
                        onChanged: (val) => setSheetState(() {
                          selectedCategory = val;
                          selectedSubCategory = null;
                        }),
                      ),
                    ),
                  ],
                ),
                if (selectedCategory != null && _subCategories.containsKey(selectedCategory)) ...[
                  const SizedBox(height: 12),
                  _CategoryDropdown(
                    label: 'Sub-Category (${selectedCategory!})',
                    value: selectedSubCategory,
                    items: _subCategories[selectedCategory!]!,
                    onChanged: (val) => setSheetState(() {
                      selectedSubCategory = val;
                      selectedSubSubCategory = null;
                    }),
                  ),
                ],
                if (selectedCategory != null && selectedSubCategory != null) ...[
                  () {
                    final key = '$selectedCategory > $selectedSubCategory';
                    if (_subSubCategories.containsKey(key)) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _CategoryDropdown(
                          label: 'Style / Type (${selectedSubCategory!})',
                          value: selectedSubSubCategory,
                          items: _subSubCategories[key]!,
                          onChanged: (val) => setSheetState(() => selectedSubSubCategory = val),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }(),
                ],
                // Specifications section if category is selected
                if (selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Color(0xFF2874F0), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Product Specifications (${selectedCategory!})',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF212121),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selectedCategory!.toLowerCase().contains('fashion')) ...[
                    Row(
                      children: [
                        Expanded(child: _inputField('Brand', brandCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _inputField('Size (e.g. S/M/L or Saree)', sizeCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _inputField('Color', colorCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _inputField('Fabric (e.g. Cotton/Silk)', fabricCtrl)),
                      ],
                    ),
                    if (selectedSubCategory != null &&
                        (selectedSubCategory!.toLowerCase().contains('saree') ||
                         selectedSubCategory!.toLowerCase().contains('chiffon') ||
                         selectedSubCategory!.toLowerCase().contains('georgette') ||
                         selectedSubCategory!.toLowerCase().contains('silk') ||
                         selectedSubCategory!.toLowerCase().contains('cotton') ||
                         selectedSubCategory!.toLowerCase().contains('lehenga') ||
                         selectedSubCategory!.toLowerCase().contains('gown') ||
                         selectedSubCategory!.toLowerCase().contains('kurti'))) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _inputField('Sari Style / Pattern', sariStyleCtrl)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CategoryDropdown(
                              label: 'Blouse Piece',
                              value: blousePiece,
                              items: const ['Yes', 'No', 'Unstitched'],
                              onChanged: (val) => setSheetState(() => blousePiece = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: _inputField('Brand', brandCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _inputField('Color / Variant', colorCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _inputField('Warranty (e.g. 1 Year)', warrantyCtrl),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _inputField('Barcode', barcodeCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField('Discount (%)', discountCtrl, type: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Product Images (Max 6)',
                    style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length + (images.length < 6 ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx == images.length) {
                        return GestureDetector(
                          onTap: () => _showImageSourceOptions(setSheetState, images),
                          child: Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF2874F0), style: BorderStyle.solid, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF2874F0).withValues(alpha: 0.05),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: Color(0xFF2874F0), size: 20),
                                SizedBox(height: 4),
                                Text('Add', style: TextStyle(color: Color(0xFF2874F0), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }

                      final url = images[idx];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 70,
                        height: 70,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    url.startsWith('/') ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$url' : url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    images.removeAt(idx);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2874F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      try {
                        await ApiService.post('/products', {
                          'name': nameCtrl.text.trim(),
                          'pricePerUnit': double.tryParse(priceCtrl.text) ?? 0,
                          'stockQuantity': int.tryParse(stockCtrl.text) ?? 0,
                          'unit': unitCtrl.text.trim(),
                          'category': selectedSubSubCategory != null
                              ? '${selectedCategory ?? ''} > ${selectedSubCategory ?? ''} > $selectedSubSubCategory'
                              : (selectedSubCategory != null
                                  ? '${selectedCategory ?? ''} > $selectedSubCategory'
                                  : (selectedCategory ?? '')),
                          'discount': double.tryParse(discountCtrl.text) ?? 0,
                          'barcode': barcodeCtrl.text.trim(),
                          'imageUrl': images.isNotEmpty ? images[0] : '',
                          'images': images,
                          'specifications': {
                            if (selectedCategory != null) ...{
                              if (selectedCategory!.toLowerCase().contains('fashion')) ...{
                                'brand': brandCtrl.text.trim(),
                                'size': sizeCtrl.text.trim(),
                                'color': colorCtrl.text.trim(),
                                'fabric': fabricCtrl.text.trim(),
                                'blousePiece': blousePiece,
                                'sariStyle': sariStyleCtrl.text.trim(),
                              } else ...{
                                'brand': brandCtrl.text.trim(),
                                'color': colorCtrl.text.trim(),
                                'warranty': warrantyCtrl.text.trim(),
                              }
                            }
                          },
                        });
                        await _load();
                      } catch (e) {
                        setState(() => _loading = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text('Add Product', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> product) {
    final nameCtrl = TextEditingController(text: product['name']);
    final priceCtrl = TextEditingController(text: product['pricePerUnit']?.toString());
    final stockCtrl = TextEditingController(text: product['stockQuantity']?.toString());
    final unitCtrl = TextEditingController(text: product['unit']);
    final discountCtrl = TextEditingController(text: product['discount']?.toString() ?? '0');
    final barcodeCtrl = TextEditingController(text: product['barcode'] ?? '');
    
    final specs = product['specifications'] as Map<String, dynamic>? ?? {};
    final sizeCtrl = TextEditingController(text: specs['size']?.toString());
    final colorCtrl = TextEditingController(text: specs['color']?.toString());
    final brandCtrl = TextEditingController(text: specs['brand']?.toString());
    final fabricCtrl = TextEditingController(text: specs['fabric']?.toString());
    String? blousePiece = specs['blousePiece']?.toString();
    final sariStyleCtrl = TextEditingController(text: specs['sariStyle']?.toString());
    final warrantyCtrl = TextEditingController(text: specs['warranty']?.toString());

    final List<String> images = [];
    if (product['images'] != null) {
      images.addAll(List<String>.from(product['images']));
    } else if (product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty) {
      images.add(product['imageUrl']);
    }
    // Parse existing category for pre-fill
    final existingCat = product['category'] as String? ?? '';
    String? selectedCategory = _allCategories.contains(existingCat) ? existingCat : (existingCat.isNotEmpty ? existingCat.split(' > ').first : null);
    String? selectedSubCategory;
    String? selectedSubSubCategory;
    if (existingCat.contains(' > ')) {
      final parts = existingCat.split(' > ');
      selectedCategory = parts[0];
      selectedSubCategory = parts.length > 1 ? parts[1] : null;
      selectedSubSubCategory = parts.length > 2 ? parts[2] : null;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Product',
                        style: GoogleFonts.inter(color: const Color(0xFF212121), fontSize: 18, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(product);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _inputField('Product Name', nameCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _inputField('Price (₹)', priceCtrl, type: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField('Stock', stockCtrl, type: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _inputField('Unit (e.g. kg/piece)', unitCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryDropdown(
                        label: 'Category',
                        value: selectedCategory,
                        items: _allCategories,
                        onChanged: (val) => setSheetState(() {
                          selectedCategory = val;
                          selectedSubCategory = null;
                        }),
                      ),
                    ),
                  ],
                ),
                if (selectedCategory != null && _subCategories.containsKey(selectedCategory)) ...[
                  const SizedBox(height: 12),
                  _CategoryDropdown(
                    label: 'Sub-Category (${selectedCategory!})',
                    value: selectedSubCategory,
                    items: _subCategories[selectedCategory!]!,
                    onChanged: (val) => setSheetState(() {
                      selectedSubCategory = val;
                      selectedSubSubCategory = null;
                    }),
                  ),
                ],
                if (selectedCategory != null && selectedSubCategory != null) ...[
                  () {
                    final key = '$selectedCategory > $selectedSubCategory';
                    if (_subSubCategories.containsKey(key)) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _CategoryDropdown(
                          label: 'Style / Type (${selectedSubCategory!})',
                          value: selectedSubSubCategory,
                          items: _subSubCategories[key]!,
                          onChanged: (val) => setSheetState(() => selectedSubSubCategory = val),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }(),
                ],
                // Specifications section if category is selected
                if (selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: Color(0xFF2874F0), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Product Specifications (${selectedCategory!})',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF212121),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selectedCategory!.toLowerCase().contains('fashion')) ...[
                    Row(
                      children: [
                        Expanded(child: _inputField('Brand', brandCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _inputField('Size (e.g. S/M/L or Saree)', sizeCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _inputField('Color', colorCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _inputField('Fabric (e.g. Cotton/Silk)', fabricCtrl)),
                      ],
                    ),
                    if (selectedSubCategory != null &&
                        (selectedSubCategory!.toLowerCase().contains('saree') ||
                         selectedSubCategory!.toLowerCase().contains('chiffon') ||
                         selectedSubCategory!.toLowerCase().contains('georgette') ||
                         selectedSubCategory!.toLowerCase().contains('silk') ||
                         selectedSubCategory!.toLowerCase().contains('cotton') ||
                         selectedSubCategory!.toLowerCase().contains('lehenga') ||
                         selectedSubCategory!.toLowerCase().contains('gown') ||
                         selectedSubCategory!.toLowerCase().contains('kurti'))) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _inputField('Sari Style / Pattern', sariStyleCtrl)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CategoryDropdown(
                              label: 'Blouse Piece',
                              value: blousePiece,
                              items: const ['Yes', 'No', 'Unstitched'],
                              onChanged: (val) => setSheetState(() => blousePiece = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: _inputField('Brand', brandCtrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _inputField('Color / Variant', colorCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _inputField('Warranty (e.g. 1 Year)', warrantyCtrl),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _inputField('Barcode', barcodeCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField('Discount (%)', discountCtrl, type: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Product Images (Max 6)',
                    style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length + (images.length < 6 ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx == images.length) {
                        return GestureDetector(
                          onTap: () => _showImageSourceOptions(setSheetState, images),
                          child: Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF2874F0), style: BorderStyle.solid, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFF2874F0).withValues(alpha: 0.05),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, color: Color(0xFF2874F0), size: 20),
                                SizedBox(height: 4),
                                Text('Add', style: TextStyle(color: Color(0xFF2874F0), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }

                      final url = images[idx];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 70,
                        height: 70,
                        child: Stack(
                           children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    url.startsWith('/') ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$url' : url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    images.removeAt(idx);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2874F0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      try {
                        await ApiService.patch('/products/${product['id']}', {
                          'name': nameCtrl.text.trim(),
                          'pricePerUnit': double.tryParse(priceCtrl.text) ?? 0,
                          'stockQuantity': int.tryParse(stockCtrl.text) ?? 0,
                          'unit': unitCtrl.text.trim(),
                          'category': selectedSubSubCategory != null
                              ? '${selectedCategory ?? ''} > ${selectedSubCategory ?? ''} > $selectedSubSubCategory'
                              : (selectedSubCategory != null
                                  ? '${selectedCategory ?? ''} > $selectedSubCategory'
                                  : (selectedCategory ?? '')),
                          'discount': double.tryParse(discountCtrl.text) ?? 0,
                          'barcode': barcodeCtrl.text.trim(),
                          'imageUrl': images.isNotEmpty ? images[0] : '',
                          'images': images,
                          'specifications': {
                            if (selectedCategory != null) ...{
                              if (selectedCategory!.toLowerCase().contains('fashion')) ...{
                                'brand': brandCtrl.text.trim(),
                                'size': sizeCtrl.text.trim(),
                                'color': colorCtrl.text.trim(),
                                'fabric': fabricCtrl.text.trim(),
                                'blousePiece': blousePiece,
                                'sariStyle': sariStyleCtrl.text.trim(),
                              } else ...{
                                'brand': brandCtrl.text.trim(),
                                'color': colorCtrl.text.trim(),
                                'warranty': warrantyCtrl.text.trim(),
                              }
                            }
                          },
                        });
                        await _load();
                      } catch (e) {
                        setState(() => _loading = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text('Update Product', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List get _filteredProducts {
    return _products.where((p) {
      final name = (p['name'] as String? ?? '').toLowerCase();
      final barcode = (p['barcode'] as String? ?? '').toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(searchLower) || barcode.contains(searchLower);

      bool matchesCategory = true;
      if (_selectedCategoryFilter != null) {
        final cat = (p['category'] as String? ?? '').toLowerCase();
        final sel = _selectedCategoryFilter!.toLowerCase();
        matchesCategory = cat == sel || cat.startsWith('$sel > ');
      }

      bool matchesStock = true;
      if (_lowStockOnly) {
        final stock = int.tryParse(p['stockQuantity']?.toString() ?? '0') ?? 0;
        matchesStock = stock <= 5;
      }

      return matchesSearch && matchesCategory && matchesStock;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Inventory', style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            tooltip: 'Scan Product to Add',
            onPressed: () async {
              final barcode = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScannerRealScreen()),
              );
              if (barcode != null && barcode.isNotEmpty) {
                setState(() => _loading = true);
                try {
                  final product = await ApiService.get('/products/barcode/$barcode');
                  setState(() => _loading = false);
                  if (product != null) {
                    _showAddDialog(prefilledData: {
                      'name': product['name'],
                      'pricePerUnit': product['pricePerUnit'],
                      'stockQuantity': product['stockQuantity'],
                      'unit': product['unit'],
                      'category': product['category'],
                      'imageUrl': product['imageUrl'],
                      'images': product['images'] != null ? List<String>.from(product['images']) : [],
                      'discount': product['discount'],
                      'barcode': barcode,
                    });
                  } else {
                    _showAddDialog(prefilledData: {
                      'barcode': barcode,
                    });
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  _showAddDialog(prefilledData: {
                    'barcode': barcode,
                  });
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No new notifications',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFF2874F0),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Store Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: const Color(0xFF2874F0),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Product', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2874F0)))
          : Column(
              children: [
                // Search Bar + Category Filter (inline)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: const TextStyle(color: Color(0xFF212121), fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: const TextStyle(color: Color(0xFF878787), fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF878787), size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF878787), size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category filter button
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) {
                              return StatefulBuilder(
                                builder: (ctx, setModalState) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 40, height: 4,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0E0E0),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text('Filter by Category',
                                            style: GoogleFonts.inter(
                                              fontSize: 16, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            // All chip
                                            FilterChip(
                                              label: Text('All',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: _selectedCategoryFilter == null
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: _selectedCategoryFilter == null
                                                        ? Colors.white
                                                        : const Color(0xFF212121),
                                                  )),
                                              selected: _selectedCategoryFilter == null,
                                              selectedColor: const Color(0xFF2874F0),
                                              backgroundColor: const Color(0xFFF1F3F6),
                                              checkmarkColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color: _selectedCategoryFilter == null
                                                      ? const Color(0xFF2874F0)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                              onSelected: (_) {
                                                setState(() => _selectedCategoryFilter = null);
                                                setModalState(() {});
                                                Navigator.pop(ctx);
                                              },
                                            ),
                                            // Category chips
                                            ..._allCategories.map((cat) {
                                              final isSelected = _selectedCategoryFilter == cat;
                                              return FilterChip(
                                                label: Text(cat,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : const Color(0xFF212121),
                                                    )),
                                                selected: isSelected,
                                                selectedColor: const Color(0xFF2874F0),
                                                backgroundColor: const Color(0xFFF1F3F6),
                                                checkmarkColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                  side: BorderSide(
                                                    color: isSelected
                                                        ? const Color(0xFF2874F0)
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                                onSelected: (_) {
                                                  setState(() => _selectedCategoryFilter = cat);
                                                  setModalState(() {});
                                                  Navigator.pop(ctx);
                                                },
                                              );
                                            }),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: _selectedCategoryFilter != null
                                ? const Color(0xFF2874F0)
                                : const Color(0xFFF1F3F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: _selectedCategoryFilter != null
                                    ? Colors.white
                                    : const Color(0xFF878787),
                                size: 22,
                              ),
                              if (_selectedCategoryFilter != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFE500),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Active category label (shown when filter is active)
                if (_selectedCategoryFilter != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2874F0).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_list_rounded,
                                  size: 12, color: Color(0xFF2874F0)),
                              const SizedBox(width: 4),
                              Text(
                                _selectedCategoryFilter!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2874F0),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setState(() => _selectedCategoryFilter = null),
                                child: const Icon(Icons.close_rounded,
                                    size: 12, color: Color(0xFF2874F0)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Low Stock Filter & Count Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_filteredProducts.length} items',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF878787),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _lowStockOnly = !_lowStockOnly;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _lowStockOnly 
                                ? Colors.red.withValues(alpha: 0.1) 
                                : const Color(0xFFF1F3F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _lowStockOnly ? Colors.red : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: _lowStockOnly ? Colors.red : const Color(0xFF878787),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Low Stock Only',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _lowStockOnly ? Colors.red : const Color(0xFF878787),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Inventory List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF2874F0),
                    child: _filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'No matching products found',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF878787),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: _filteredProducts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final p = _filteredProducts[i];
                              final hasImage = p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty;
                              return InkWell(
                                onTap: () => _showEditDialog(p),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2874F0).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: hasImage
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                p['imageUrl'].toString().startsWith('/')
                                                    ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}${p['imageUrl']}'
                                                    : p['imageUrl'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: Color(0xFF2874F0),
                                                  size: 24,
                                                ),
                                              ),
                                            )
                                          : const Icon(Icons.inventory_2_outlined,
                                              color: Color(0xFF2874F0)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['name'] ?? '', style: GoogleFonts.inter(
                                          color: const Color(0xFF212121), fontWeight: FontWeight.w700, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        () {
                                          final original = double.tryParse(p['pricePerUnit']?.toString() ?? '0') ?? 0;
                                          final discount = double.tryParse(p['discount']?.toString() ?? '0') ?? 0;
                                          if (discount > 0) {
                                            final discounted = original * (1 - discount / 100);
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text('₹${discounted.toStringAsFixed(2)}',
                                                      style: GoogleFonts.inter(color: const Color(0xFF388E3C), fontSize: 12, fontWeight: FontWeight.w700)),
                                                    const SizedBox(width: 6),
                                                    Text('₹$original',
                                                      style: GoogleFonts.inter(
                                                        color: const Color(0xFF878787), 
                                                        fontSize: 11, 
                                                        fontWeight: FontWeight.w500,
                                                        decoration: TextDecoration.lineThrough,
                                                      )),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text('${discount.toStringAsFixed(0)}% OFF / ${p['unit']}',
                                                  style: GoogleFonts.inter(color: const Color(0xFFE056FD), fontSize: 10, fontWeight: FontWeight.w800)),
                                              ],
                                            );
                                          } else {
                                            return Text('₹$original / ${p['unit']}',
                                              style: GoogleFonts.inter(color: const Color(0xFF878787), fontSize: 12, fontWeight: FontWeight.w500));
                                          }
                                        }(),
                                      ],
                                    )),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('Stock: ${p['stockQuantity']}',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF388E3C), fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () => _confirmDelete(p),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                        )
                                      ],
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: onChanged,
      style: const TextStyle(color: Color(0xFF212121), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF878787), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF1F3F6),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2874F0), width: 1.5),
        ),
      ),
    );
  }
}

class BarcodeScannerRealScreen extends StatefulWidget {
  const BarcodeScannerRealScreen({super.key});

  @override
  State<BarcodeScannerRealScreen> createState() => _BarcodeScannerRealScreenState();
}

class _BarcodeScannerRealScreenState extends State<BarcodeScannerRealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerCtrl;
  late Animation<double> _scannerAnim;
  final MobileScannerController _cameraCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _scannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_scannerCtrl);
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _cameraCtrl.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String barcode) {
    if (_scanned) return;
    _scanned = true;
    Navigator.pop(context, barcode);
  }

  void _showManualInputDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enter Barcode Manually', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 8901234567890',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final code = textCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _onBarcodeDetected(code);
              }
            },
            child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Scan Product Barcode',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded, color: Colors.white),
            tooltip: 'Enter Manually',
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraCtrl,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _onBarcodeDetected(barcodes.first.rawValue!);
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Text(
                  'Camera error or simulator active.\nUse Simulation or Keyboard input below.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _scannerAnim,
                    builder: (context, child) {
                      return Positioned(
                        top: _scannerAnim.value * 250,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Text(
                'Point camera at a barcode to scan\nor tap keyboard icon to type it manually',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text('SIMULATE SCAN (TESTING)',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _simulateBtn('Rice (8901058002315)', '8901058002315'),
                    _simulateBtn('Phone (8901234567890)', '8901234567890'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _simulateBtn('Fashion (8909876543210)', '8909876543210'),
                    _simulateBtn('Headphones (8901112223334)', '8901112223334'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _simulateBtn(String label, String code) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      icon: const Icon(Icons.barcode_reader, size: 16),
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
      onPressed: () => _onBarcodeDetected(code),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF212121)),
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF878787), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF1F3F6),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2874F0), width: 1.5),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF212121))),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
