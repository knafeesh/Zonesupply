import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'product_details_screen.dart';
import 'wholesaler_shop_screen.dart';
import 'cart_screen.dart';

class GroceryCategoryScreen extends StatefulWidget {
  final String? initialSubCategory;

  const GroceryCategoryScreen({
    super.key,
    this.initialSubCategory,
  });

  @override
  State<GroceryCategoryScreen> createState() => _GroceryCategoryScreenState();
}

class _GroceryCategoryScreenState extends State<GroceryCategoryScreen> {
  List _products = [];
  List _wholesalers = [];
  List _backendBanners = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  Set<String> _favoritedIds = {};

  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  String? _selectedSubCategory;

  // Real-photo Grocery Categories (Row 1: Staples, Cooking, Dairy, Drinks)
  final List<Map<String, dynamic>> _groceryRow1 = [
    {
      'name': 'Atta & Flours',
      'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80',
      'query': 'atta',
    },
    {
      'name': 'Rice & Basmati',
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&auto=format&fit=crop&q=80',
      'query': 'rice',
    },
    {
      'name': 'Dals & Pulses',
      'image': 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80',
      'query': 'dal',
    },
    {
      'name': 'Edible Oils & Ghee',
      'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80',
      'query': 'oil',
    },
    {
      'name': 'Spices & Masalas',
      'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&auto=format&fit=crop&q=80',
      'query': 'masala',
    },
    {
      'name': 'Sugar & Salt',
      'image': 'https://images.unsplash.com/photo-1622484216805-3e28c4e4efc3?w=400&auto=format&fit=crop&q=80',
      'query': 'sugar',
    },
    {
      'name': 'Dairy & Butter',
      'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&auto=format&fit=crop&q=80',
      'query': 'dairy',
    },
    {
      'name': 'Bakery & Bread',
      'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80',
      'query': 'bakery',
    },
    {
      'name': 'Juices & Mango',
      'image': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=400&auto=format&fit=crop&q=80',
      'query': 'juice',
    },
    {
      'name': 'Tea & Coffee',
      'image': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&auto=format&fit=crop&q=80',
      'query': 'tea',
    },
  ];

  // (Row 2: Offers, Snacks, Sodas, Dry Fruits, Hygiene & Cleaning)
  final List<Map<String, dynamic>> _groceryRow2 = [
    {
      'name': 'Offers',
      'isOffer': true,
      'text': 'Min. 30% Off',
      'query': 'offer',
    },
    {
      'name': 'Chips & Namkeen',
      'image': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&auto=format&fit=crop&q=80',
      'query': 'chips',
    },
    {
      'name': 'Biscuits & Cookies',
      'image': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&auto=format&fit=crop&q=80',
      'query': 'biscuit',
    },
    {
      'name': 'Cold Drinks & Sodas',
      'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
      'query': 'drink',
    },
    {
      'name': 'Noodles & Pasta',
      'image': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=400&auto=format&fit=crop&q=80',
      'query': 'noodle',
    },
    {
      'name': 'Dry Fruits & Nuts',
      'image': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=400&auto=format&fit=crop&q=80',
      'query': 'dry fruit',
    },
    {
      'name': 'Sauces & Spreads',
      'image': 'https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=400&auto=format&fit=crop&q=80',
      'query': 'sauce',
    },
    {
      'name': 'Soaps & Detergents',
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80',
      'query': 'soap',
    },
    {
      'name': 'Personal Care',
      'image': 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400&auto=format&fit=crop&q=80',
      'query': 'care',
    },
    {
      'name': 'Cleaning & Household',
      'image': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?w=400&auto=format&fit=crop&q=80',
      'query': 'clean',
    },
  ];

  // Default Grocery Banners
  final List<Map<String, dynamic>> _defaultOfferBanners = [
    {
      'title': 'Direct Mills Atta & Basmati Fest',
      'subtitle': 'Fresh wheat chakki atta & 1121 basmati rice — Up to 40% bulk margins',
      'tag': 'STAPLES SPECIAL',
      'gradient': [Color(0xFF15803D), Color(0xFF16A34A)],
      'icon': Icons.grain_rounded,
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Edible Oils & Pure Desi Ghee',
      'subtitle': 'Fortune, Emami, Amul Ghee 15L Tins & 1L Pouches at factory rates',
      'tag': 'COOKING ESSENTIALS',
      'gradient': [Color(0xFFD97706), Color(0xFFF59E0B)],
      'icon': Icons.water_drop_rounded,
      'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Authentic Spices & Masala Sacks',
      'subtitle': 'Catch, MDH, Everest bulk cartons — Extra 10% cash discount',
      'tag': 'SPICES SPECIAL',
      'gradient': [Color(0xFFDC2626), Color(0xFFEA580C)],
      'icon': Icons.local_fire_department_rounded,
      'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Beverages & Soft Drinks Mega Pallet',
      'subtitle': 'Coca-Cola, Thums Up, Frooti, Red Bull crates & direct wholesale prices',
      'tag': 'BEVERAGE BULK',
      'gradient': [Color(0xFF0284C7), Color(0xFF06B6D4)],
      'icon': Icons.local_drink_rounded,
      'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Premium Dry Fruits & Nuts',
      'subtitle': 'California Almonds, W240 Cashews, Kishmish bulk boxes — High margin deals',
      'tag': 'DRY FRUITS DEALS',
      'gradient': [Color(0xFF7C3AED), Color(0xFF9333EA)],
      'icon': Icons.eco_rounded,
      'image': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty) {
      _selectedSubCategory = widget.initialSubCategory;
    }

    _load();

    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final total = _getDynamicOfferBanners().length;
        if (total > 0) {
          _currentBannerIndex = (_currentBannerIndex + 1) % total;
          _bannerController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final productsData = await ApiService.get('/products') as List? ?? [];
      final wholesalersData = await ApiService.get('/wholesalers') as List? ?? [];
      final favsData = await ApiService.get('/wholesalers/favorites/my') as List? ?? [];
      final favIds = favsData.map((w) => w['id'].toString()).toSet();

      List bannersData = [];
      try {
        final res = await ApiService.get('/banners?category=Grocery');
        if (res is List) bannersData = res;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _products = productsData;
          _wholesalers = wholesalersData;
          _backendBanners = bannersData;
          _favoritedIds = favIds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static double parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim()) ?? fallback;
    }
    return fallback;
  }

  static int parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val.trim()) ?? (double.tryParse(val.trim())?.toInt() ?? fallback);
    }
    return fallback;
  }

  bool _isGroceryProduct(Map<String, dynamic> p) {
    final cat = (p['category'] as String? ?? '').toLowerCase();
    final subCat = (p['subCategory'] as String? ?? '').toLowerCase();
    final name = (p['name'] as String? ?? '').toLowerCase();

    // Exclude strictly fashion
    if (cat.contains('fashion') || cat.contains('apparel') || cat.contains('clothing')) {
      return false;
    }

    return cat.contains('grocery') ||
        cat.contains('rice') ||
        cat.contains('atta') ||
        cat.contains('oil') ||
        cat.contains('food') ||
        cat.contains('beverage') ||
        cat.contains('dairy') ||
        cat.contains('snack') ||
        subCat.contains('atta') ||
        subCat.contains('rice') ||
        subCat.contains('dal') ||
        subCat.contains('oil') ||
        subCat.contains('masala') ||
        subCat.contains('sugar') ||
        subCat.contains('biscuit') ||
        subCat.contains('snack') ||
        subCat.contains('tea') ||
        subCat.contains('drink') ||
        name.contains('atta') ||
        name.contains('rice') ||
        name.contains('oil') ||
        name.contains('ghee') ||
        name.contains('dal') ||
        name.contains('sugar') ||
        name.contains('salt') ||
        name.contains('masala') ||
        name.contains('biscuit') ||
        name.contains('chips') ||
        name.contains('drink') ||
        name.contains('tea') ||
        name.contains('coffee') ||
        name.contains('noodle') ||
        name.contains('soap') ||
        name.contains('detergent');
  }

  static String getProductImage(Map<String, dynamic> p) {
    String? url;
    if (p['imageUrl'] != null && p['imageUrl'].toString().trim().isNotEmpty) {
      url = p['imageUrl'].toString().trim();
    } else if (p['image'] != null && p['image'].toString().trim().isNotEmpty) {
      url = p['image'].toString().trim();
    } else if (p['images'] is List && (p['images'] as List).isNotEmpty) {
      url = (p['images'] as List).first.toString().trim();
    } else if (p['imageUrls'] is List && (p['imageUrls'] as List).isNotEmpty) {
      url = (p['imageUrls'] as List).first.toString().trim();
    }

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('/')) {
        return '${ApiService.baseUrl.replaceAll('/api/v1', '')}$url';
      }
      return url;
    }

    final name = (p['name'] as String? ?? '').toLowerCase();
    final subCat = (p['subCategory'] as String? ?? '').toLowerCase();
    final cat = (p['category'] as String? ?? '').toLowerCase();

    if (name.contains('atta') || subCat.contains('atta') || name.contains('flour')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('rice') || subCat.contains('rice') || name.contains('basmati')) {
      return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('dal') || subCat.contains('dal') || name.contains('pulse') || name.contains('chana')) {
      return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('oil') || subCat.contains('oil') || name.contains('ghee') || name.contains('mustard')) {
      return 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('masala') || subCat.contains('masala') || name.contains('spice') || name.contains('chili') || name.contains('turmeric')) {
      return 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('sugar') || subCat.contains('sugar') || name.contains('salt')) {
      return 'https://images.unsplash.com/photo-1622484216805-3e28c4e4efc3?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('milk') || subCat.contains('milk') || name.contains('dairy') || name.contains('butter') || name.contains('cheese')) {
      return 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('biscuit') || subCat.contains('biscuit') || name.contains('cookie')) {
      return 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('chip') || subCat.contains('chip') || name.contains('namkeen') || name.contains('snack')) {
      return 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('drink') || subCat.contains('drink') || name.contains('coke') || name.contains('soda') || name.contains('juice')) {
      return 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('tea') || subCat.contains('tea') || name.contains('coffee')) {
      return 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('noodle') || subCat.contains('noodle') || name.contains('pasta') || name.contains('maggi')) {
      return 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('dry fruit') || subCat.contains('dry fruit') || name.contains('almond') || name.contains('cashew') || name.contains('kaju')) {
      return 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('soap') || subCat.contains('soap') || name.contains('detergent') || name.contains('surf')) {
      return 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=80';
    }

    return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600&auto=format&fit=crop&q=80';
  }

  String _getWholesalerCategory(Map<String, dynamic> w) {
    if (w['categories'] is List) {
      for (var c in w['categories'] as List) {
        final cl = c.toString().toLowerCase();
        if (cl.contains('grocery') || cl.contains('rice') || cl.contains('atta') || cl.contains('oil') || cl.contains('fmcg') || cl.contains('grain') || cl.contains('food') || cl.contains('dairy') || cl.contains('spice')) {
          return 'Grocery';
        }
      }
    }
    final name = (w['businessName'] as String? ?? '').toLowerCase();
    if (name.contains('grocery') || name.contains('trader') || name.contains('staple') || name.contains('mill') || name.contains('oil') || name.contains('grain') || name.contains('kirana') || name.contains('food') || name.contains('spice') || name.contains('fmcg') || name.contains('atta') || name.contains('rice') || name.contains('sugar')) {
      return 'Grocery';
    }
    final wId = w['id'].toString();
    final prods = _products.where((p) => p['wholesalerId']?.toString() == wId || p['wholesaler']?['id']?.toString() == wId);
    for (var p in prods) {
      if (_isGroceryProduct(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p))) {
        return 'Grocery';
      }
    }
    return 'Other';
  }

  List<Map<String, dynamic>> _getDynamicOfferBanners() {
    final List<Map<String, dynamic>> dynamicBanners = [];

    // 1. Wholesaler uploaded offer banners from backend
    for (var b in _backendBanners) {
      final title = b['title']?.toString() ?? 'Special Wholesale Grocery Offer';
      final subtitle = b['subtitle']?.toString() ?? 'Direct manufacturer wholesale rates';
      final tag = b['tag']?.toString() ?? 'SELLER OFFER';
      final img = b['imageUrl']?.toString() ?? '';
      final gStartHex = b['gradientStart']?.toString() ?? '#15803D';
      final gEndHex = b['gradientEnd']?.toString() ?? '#16A34A';

      final Color gStart = _hexToColor(gStartHex, const Color(0xFF15803D));
      final Color gEnd = _hexToColor(gEndHex, const Color(0xFF16A34A));

      final shopName = b['wholesaler']?['businessName']?.toString();

      dynamicBanners.add({
        'title': title,
        'subtitle': subtitle,
        'tag': shopName != null && shopName.isNotEmpty ? '$tag • $shopName' : tag,
        'gradient': [gStart, gEnd],
        'icon': Icons.local_offer_rounded,
        'image': img.startsWith('/') ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$img' : img,
        'wholesalerId': b['wholesalerId']?.toString(),
        'wholesaler': b['wholesaler'],
        'subCategory': b['subCategory'],
      });
    }

    // 2. Dynamic offers extracted from wholesale products
    for (var p in _products) {
      if (_isGroceryProduct(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p))) {
        final offerText = p['offer']?.toString() ?? p['specialOffer']?.toString() ?? p['discountTag']?.toString();
        final img = getProductImage(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p));
        if (offerText != null && offerText.isNotEmpty) {
          dynamicBanners.add({
            'title': p['name'] ?? 'Wholesale Grocery Deal',
            'subtitle': offerText,
            'tag': 'SELLER DEAL',
            'gradient': [const Color(0xFF15803D), const Color(0xFF16A34A)],
            'icon': Icons.local_offer_rounded,
            'image': img,
            'wholesalerId': p['wholesalerId'] ?? p['wholesaler']?['id'],
            'wholesaler': p['wholesaler'],
          });
          if (dynamicBanners.length >= 6) break;
        }
      }
    }

    if (dynamicBanners.isNotEmpty) {
      return dynamicBanners;
    }
    return _defaultOfferBanners;
  }

  Color _hexToColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  Widget _buildGroceryCategoryTile(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final isOffer = item['isOffer'] == true;
    final isSelected = _selectedSubCategory == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSubCategory == name) {
            _selectedSubCategory = null;
          } else {
            _selectedSubCategory = name;
          }
        });
      },
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isOffer ? const Color(0xFFE50914) : const Color(0xFFF1F8F4),
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? Border.all(color: const Color(0xFF16A34A), width: 2.5)
                    : Border.all(color: Colors.transparent, width: 2.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isOffer
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Min.',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '30%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Off',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ],
                      )
                    : Image.network(
                        item['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F8F4),
                          child: const Center(
                            child: Icon(Icons.shopping_basket_rounded, color: Color(0xFF16A34A), size: 28),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List get _filteredProducts {
    var list = _products.where((p) {
      final map = p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p);
      return _isGroceryProduct(map);
    }).toList();

    if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty && _selectedSubCategory != 'All Grocery') {
      if (_selectedSubCategory == 'Offers') {
        list = list.where((p) {
          final price = parseDouble(p['price'] ?? p['pricePerUnit'], 0);
          final mrp = parseDouble(p['mrp'] ?? p['originalPrice'], price);
          final disc = mrp > 0 ? ((mrp - price) / mrp * 100).round() : 0;
          final offer = p['offer']?.toString() ?? p['specialOffer']?.toString() ?? p['discountTag']?.toString();
          return disc >= 30 || (offer != null && offer.isNotEmpty);
        }).toList();
      } else {
        final term = _selectedSubCategory!.toLowerCase().replaceAll('&', '').replaceAll('and', '').trim();
        list = list.where((p) {
          final sub = (p['subCategory'] as String? ?? '').toLowerCase();
          final name = (p['name'] as String? ?? '').toLowerCase();
          final cat = (p['category'] as String? ?? '').toLowerCase();
          return sub.contains(term) || name.contains(term) || cat.contains(term);
        }).toList();
      }
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final brand = (p['brand'] as String? ?? '').toLowerCase();
        final sku = (p['sku'] as String? ?? '').toLowerCase();
        final sub = (p['subCategory'] as String? ?? '').toLowerCase();
        return name.contains(q) || brand.contains(q) || sku.contains(q) || sub.contains(q);
      }).toList();
    }

    return list;
  }

  List get _groceryWholesalers {
    final list = _wholesalers.where((w) {
      final map = w is Map<String, dynamic> ? w : Map<String, dynamic>.from(w);
      return _getWholesalerCategory(map) == 'Grocery';
    }).toList();

    if (list.isNotEmpty) return list;

    // Verified default grocery suppliers if none registered in DB yet
    return [
      {
        'id': 'grocery-mill-1',
        'businessName': 'Shree Ram Agro & Flour Mills',
        'businessAddress': 'Sector 18 Grain Mandi, Karnal',
        'categories': ['Grocery'],
      },
      {
        'id': 'grocery-mill-2',
        'businessName': 'Delhi Wholesale Kirana & Spice Mandi',
        'businessAddress': 'Khari Baoli Wholesale Market, Old Delhi',
        'categories': ['Grocery'],
      },
      {
        'id': 'grocery-mill-3',
        'businessName': 'Fortune Foods & Edible Oil Depo',
        'businessAddress': 'Transport Nagar Wholesale Complex, Jaipur',
        'categories': ['Grocery'],
      },
      {
        'id': 'grocery-mill-4',
        'businessName': 'Punjab Basmati Rice & Grain Traders',
        'businessAddress': 'Amritsar Wholesale Grain Yard, Punjab',
        'categories': ['Grocery'],
      },
    ];
  }

  Future<void> _toggleFavorite(String wholesalerId) async {
    try {
      final res = await ApiService.post('/wholesalers/$wholesalerId/favorite', {});
      final favorited = res['favorited'] as bool;
      setState(() {
        if (favorited) {
          _favoritedIds.add(wholesalerId);
        } else {
          _favoritedIds.remove(wholesalerId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              favorited ? 'Added supplier to favorites' : 'Removed supplier from favorites',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: favorited ? const Color(0xFF16A34A) : Colors.black87,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final banners = _getDynamicOfferBanners();
    final wholesalers = _groceryWholesalers;
        final catalog = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_grocery_store_rounded, color: Color(0xFF16A34A), size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'GROCERY HUB',
              style: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Consumer<CartProvider>(
              builder: (_, cart, __) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                backgroundColor: const Color(0xFF16A34A),
                child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0F172A)),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF16A34A),
              child: CustomScrollView(
                slivers: [
                  // 1. Search Bar
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Search atta, rice, oil, spices, drinks...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Color(0xFF878787)),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _search = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. FASHION OFFER SLIDESHOW
                  if (banners.isNotEmpty && _search.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 190,
                              child: PageView.builder(
                                controller: _bannerController,
                                itemCount: banners.length,
                                onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                                itemBuilder: (_, idx) {
                                  final b = banners[idx];
                                  return GestureDetector(
                                    onTap: () {
                                      if (b['wholesaler'] != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => WholesalerShopScreen(wholesaler: b['wholesaler']),
                                          ),
                                        ).then((_) => _load());
                                      } else if (b['subCategory'] != null && b['subCategory'].toString().isNotEmpty) {
                                        setState(() {
                                          _selectedSubCategory = b['subCategory'].toString();
                                        });
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (b['gradient'] as List<Color>)[0].withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              b['image'] as String,
                                              fit: BoxFit.cover,
                                              color: Colors.black.withValues(alpha: 0.4),
                                              colorBlendMode: BlendMode.darken,
                                              errorBuilder: (_, __, ___) => Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: b['gradient'] as List<Color>,
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.25),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                                    ),
                                                    child: Text(
                                                      b['tag'] as String,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    b['title'] as String,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w900,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    b['subtitle'] as String,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 16,
                                              child: Icon(
                                                b['icon'] as IconData? ?? Icons.local_grocery_store_rounded,
                                                color: Colors.white.withValues(alpha: 0.8),
                                                size: 32,
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
                            const SizedBox(height: 8),
                            // Dot indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(banners.length, (idx) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentBannerIndex == idx ? 18 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: _currentBannerIndex == idx
                                        ? const Color(0xFF16A34A)
                                        : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. GROCERY DEPARTMENTS (2-Row Real Photo Visual Cards)
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  'GROCERY DEPARTMENTS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF16A34A),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedSubCategory != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedSubCategory = null),
                                    child: Text(
                                      'Clear Filter ✕',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFD4367C),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _groceryRow1.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (_, colIdx) {
                                final topItem = _groceryRow1[colIdx];
                                final bottomItem = _groceryRow2[colIdx];
                                return Column(
                                  children: [
                                    _buildGroceryCategoryTile(topItem),
                                    const SizedBox(height: 12),
                                    _buildGroceryCategoryTile(bottomItem),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. FASHION WHOLESALE SHOPS SECTION
                  if (wholesalers.isNotEmpty && _search.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    'Wholesale Grocery Shops & Mills',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${wholesalers.length} Verified',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF16A34A),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: wholesalers.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, idx) {
                                  final w = wholesalers[idx];
                                  final wId = w['id'].toString();
                                  final profilePic = w['user']?['profilePicture'];
                                  final shopProducts = _products
                                      .where((p) => p['wholesalerId']?.toString() == wId || p['wholesaler']?['id']?.toString() == wId)
                                      .toList();
                                  final productCount = shopProducts.length;

                                  final shopGradients = [
                                    [const Color(0xFF16A34A), const Color(0xFFBB4DE0)],
                                    [const Color(0xFFD4367C), const Color(0xFFFF8A65)],
                                    [const Color(0xFF1565C0), const Color(0xFF00ACC1)],
                                    [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                                    [const Color(0xFFE65100), const Color(0xFFFFB300)],
                                    [const Color(0xFF4527A0), const Color(0xFF7E57C2)],
                                  ];
                                  final gradient = shopGradients[idx % shopGradients.length];

                                  return GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WholesalerShopScreen(wholesaler: w),
                                        ),
                                      );
                                      _load();
                                    },
                                    child: Container(
                                      width: 145,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradient[0].withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                                                  backgroundImage: profilePic != null && profilePic.toString().isNotEmpty
                                                      ? NetworkImage(
                                                          profilePic.toString().startsWith('/')
                                                              ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$profilePic'
                                                              : profilePic.toString(),
                                                        )
                                                      : null,
                                                  child: profilePic == null || profilePic.toString().isEmpty
                                                      ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 22)
                                                      : null,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  w['businessName'] ?? 'Fashion Store',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 11),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '$productCount items',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Text(
                                                    'Visit Shop →',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),



                  // 7. ALL GROCERY PRODUCTS GRID HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            _selectedSubCategory != null ? _selectedSubCategory!.toUpperCase() : 'ALL GROCERY PRODUCTS',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${catalog.length} Items',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 8. 2-COLUMN PRODUCT GRID
                  if (catalog.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.local_grocery_store_outlined, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text(
                                'No grocery products found',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final p = catalog[index];
                            final map = p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p);
                            return _GroceryProductCard(
                              product: map,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: map),
                                ),
                              ),
                            );
                          },
                          childCount: catalog.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }
}

class _GroceryProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _GroceryProductCard({required this.product, required this.onTap});

  @override
  State<_GroceryProductCard> createState() => _GroceryProductCardState();
}

class _GroceryProductCardState extends State<_GroceryProductCard> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartProvider>();
    final pId = p['id'].toString();
    final pName = p['name'] ?? 'Product';
    final brand = p['brand'] ?? 'Fashion Brand';
    final sku = 'SKU: ${p['sku'] ?? p['itemCode'] ?? 'FS-101'}';

    final sellingPrice = _GroceryCategoryScreenState.parseDouble(p['price'] ?? p['pricePerUnit'], 0);
    final originalPrice = _GroceryCategoryScreenState.parseDouble(p['mrp'] ?? p['originalPrice'], sellingPrice > 0 ? sellingPrice * 1.3 : 1000);
    final bestPrice = _GroceryCategoryScreenState.parseDouble(p['bestPrice'], sellingPrice > 0 ? sellingPrice * 0.95 : 950);
    final discount = originalPrice > 0 ? ((originalPrice - sellingPrice) / originalPrice * 100).round() : 0;
    final minQty = _GroceryCategoryScreenState.parseInt(p['moq'], 6);
    final moq = 'MOQ: $minQty pcs';
    final offer = p['offer'] ?? (discount > 0 ? '$discount% Off on wholesale bulk' : 'Special Wholesaler Rate');
    final extraDiscount = p['specialOffer'] ?? (discount > 15 ? 'Extra 5% off on 50+ units' : 'Free Shipping above ₹5,000');

    final imageUrl = _GroceryCategoryScreenState.getProductImage(p);

    final cartItems = cart.items.where((i) => i.productId == pId).toList();
    final inCart = cartItems.isNotEmpty;
    final qty = inCart ? cartItems.first.quantity : 0;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(
                        'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600&auto=format&fit=crop&q=80',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isWishlisted = !_isWishlisted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isWishlisted ? 'Added to Wishlist' : 'Removed from Wishlist'),
                          duration: const Duration(milliseconds: 600),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isWishlisted ? const Color(0xFFDC2626) : Colors.grey.shade400,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF16A34A),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          pName,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          sku,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '₹${sellingPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (discount > 0)
                              Text(
                                '₹${originalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            moq,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offer: $offer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFD97706),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Add to cart button
                    inCart
                        ? Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () => cart.decrement(pId),
                                  child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                ),
                                Text(
                                  '$qty',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => cart.addItem(p),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () {
                                cart.addItem(p);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                    duration: Duration(milliseconds: 700),
                                    backgroundColor: Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'ADD TO CART',
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
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
    );
  }
}
