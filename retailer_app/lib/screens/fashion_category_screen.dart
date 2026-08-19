import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'wholesaler_shop_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class FashionCategoryScreen extends StatefulWidget {
  final String? initialSubCategory;

  const FashionCategoryScreen({
    super.key,
    this.initialSubCategory,
  });

  @override
  State<FashionCategoryScreen> createState() => _FashionCategoryScreenState();
}

class _FashionCategoryScreenState extends State<FashionCategoryScreen> {
  List _products = [];
  List _wholesalers = [];
  List _backendBanners = [];
  Set<String> _favoritedIds = {};
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  String? _selectedSubCategory;

  // Real photo Fashion Categories matching user UI (Row 1: Women, Tops, Western, Accessories)
  final List<Map<String, dynamic>> _fashionRow1 = [
    {
      'name': 'Women',
      'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      'query': 'women',
    },
    {
      'name': 'Jeans & Jeggings',
      'image': 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&auto=format&fit=crop&q=80',
      'query': 'jeans',
    },
    {
      'name': 'T-shirts',
      'image': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&auto=format&fit=crop&q=80',
      'query': 't-shirt',
    },
    {
      'name': 'Tops & Shirts',
      'image': 'https://images.unsplash.com/photo-1598554747436-c9293d6a588f?w=400&auto=format&fit=crop&q=80',
      'query': 'top',
    },
    {
      'name': 'Dresses',
      'image': 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&auto=format&fit=crop&q=80',
      'query': 'dress',
    },
    {
      'name': 'Jewellery',
      'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400&auto=format&fit=crop&q=80',
      'query': 'jewellery',
    },
    {
      'name': 'Innerwear',
      'image': 'https://images.unsplash.com/photo-1590736969955-71cc94801759?w=400&auto=format&fit=crop&q=80',
      'query': 'innerwear',
    },
    {
      'name': 'Trousers & Pants',
      'image': 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&auto=format&fit=crop&q=80',
      'query': 'trouser',
    },
    {
      'name': 'Footwear',
      'image': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400&auto=format&fit=crop&q=80',
      'query': 'footwear',
    },
    {
      'name': 'Beauty',
      'image': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&auto=format&fit=crop&q=80',
      'query': 'beauty',
    },
  ];

  // (Row 2: Offers, Men, Bottoms, Cargos, Co-ords)
  final List<Map<String, dynamic>> _fashionRow2 = [
    {
      'name': 'Offers',
      'isOffer': true,
      'text': 'Min. 30% Off',
      'query': 'offer',
    },
    {
      'name': 'Men',
      'image': 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=400&auto=format&fit=crop&q=80',
      'query': 'men',
    },
    {
      'name': 'T-shirts',
      'image': 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=400&auto=format&fit=crop&q=80',
      'query': 't-shirt',
    },
    {
      'name': 'Jeans',
      'image': 'https://images.unsplash.com/photo-1542272604-780c96856592?w=400&auto=format&fit=crop&q=80',
      'query': 'jeans',
    },
    {
      'name': 'Shirts',
      'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&auto=format&fit=crop&q=80',
      'query': 'shirt',
    },
    {
      'name': 'Trackpants',
      'image': 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=400&auto=format&fit=crop&q=80',
      'query': 'trackpant',
    },
    {
      'name': 'Trouser & Pants',
      'image': 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400&auto=format&fit=crop&q=80',
      'query': 'trouser',
    },
    {
      'name': 'Joggers',
      'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&auto=format&fit=crop&q=80',
      'query': 'jogger',
    },
    {
      'name': 'Cargos',
      'image': 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400&auto=format&fit=crop&q=80',
      'query': 'cargo',
    },
    {
      'name': 'Co-ords',
      'image': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400&auto=format&fit=crop&q=80',
      'query': 'co-ord',
    },
  ];

  // Fashion offer banners — support dynamic wholesaler offers + fallbacks
  final List<Map<String, dynamic>> _defaultOfferBanners = [
    {
      'title': 'New Season Arrivals',
      'subtitle': 'Fresh wholesale fashion drops — up to 60% off retail',
      'tag': 'TRENDING NOW',
      'gradient': [Color(0xFF6C3BD5), Color(0xFFBB4DE0)],
      'icon': Icons.trending_up_rounded,
      'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Premium Ethnic Wear',
      'subtitle': 'Sarees, Kurtis, Lehengas — Best B2B rates in market',
      'tag': 'ETHNIC SPECIAL',
      'gradient': [Color(0xFFD4367C), Color(0xFFFF8A65)],
      'icon': Icons.checkroom_rounded,
      'image': 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Bulk Men\'s Collection',
      'subtitle': 'T-shirts, Shirts, Trousers — Minimum order 12 pcs',
      'tag': 'BULK OFFER',
      'gradient': [Color(0xFF1565C0), Color(0xFF00ACC1)],
      'icon': Icons.inventory_rounded,
      'image': 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?w=600&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Kids Fashion Fiesta',
      'subtitle': 'Playful kids wear — vibrant colors & best margins',
      'tag': 'KIDS SPECIAL',
      'gradient': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      'icon': Icons.child_care_rounded,
      'image': 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=600&auto=format&fit=crop&q=80',
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
          setState(() {
            _currentBannerIndex = (_currentBannerIndex + 1) % total;
          });
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
        final res = await ApiService.get('/banners?category=Fashion');
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

  bool _isFashionProduct(Map<String, dynamic> p) {
    final cat = (p['category'] as String? ?? '').toLowerCase();
    final subCat = (p['subCategory'] as String? ?? '').toLowerCase();
    final name = (p['name'] as String? ?? '').toLowerCase();

    return cat.contains('fashion') ||
        cat.contains('apparel') ||
        cat.contains('clothing') ||
        cat.contains('wear') ||
        subCat.contains('saree') ||
        subCat.contains('kurti') ||
        subCat.contains('men') ||
        subCat.contains('shirt') ||
        subCat.contains('dress') ||
        subCat.contains('suit') ||
        subCat.contains('lehenga') ||
        subCat.contains('jean') ||
        subCat.contains('top') ||
        subCat.contains('jewel') ||
        subCat.contains('inner') ||
        subCat.contains('footwear') ||
        subCat.contains('beauty') ||
        subCat.contains('trackpant') ||
        subCat.contains('trouser') ||
        subCat.contains('jogger') ||
        subCat.contains('cargo') ||
        subCat.contains('co-ord') ||
        name.contains('saree') ||
        name.contains('kurti') ||
        name.contains('shirt') ||
        name.contains('t-shirt') ||
        name.contains('jeans') ||
        name.contains('pant') ||
        name.contains('trousers') ||
        name.contains('dress') ||
        name.contains('top') ||
        name.contains('shoe') ||
        name.contains('sandal') ||
        name.contains('jewel') ||
        name.contains('cargo') ||
        name.contains('jogger');
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

    if (name.contains('saree') || subCat.contains('saree')) {
      return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('kurti') || subCat.contains('kurti')) {
      return 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('dress') || subCat.contains('dress') || name.contains('gown') || subCat.contains('gown')) {
      return 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('lehenga') || subCat.contains('lehenga')) {
      return 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('t-shirt') || name.contains('tee') || subCat.contains('t-shirt')) {
      return 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('jean') || subCat.contains('jean') || name.contains('denim') || subCat.contains('jegging')) {
      return 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('shirt') || subCat.contains('shirt')) {
      return 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('top') || subCat.contains('top')) {
      return 'https://images.unsplash.com/photo-1598554747436-c9293d6a588f?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('jewel') || subCat.contains('jewel') || name.contains('earring') || name.contains('necklace')) {
      return 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('inner') || subCat.contains('inner') || name.contains('bra') || name.contains('lingerie')) {
      return 'https://images.unsplash.com/photo-1590736969955-71cc94801759?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('footwear') || name.contains('shoe') || name.contains('sandal') || name.contains('heel') || subCat.contains('footwear')) {
      return 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('beauty') || subCat.contains('beauty') || name.contains('makeup') || name.contains('lipstick')) {
      return 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('trackpant') || subCat.contains('trackpant')) {
      return 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('trouser') || name.contains('pant') || subCat.contains('trouser') || name.contains('chino')) {
      return 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('jogger') || subCat.contains('jogger')) {
      return 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('cargo') || subCat.contains('cargo')) {
      return 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('co-ord') || subCat.contains('co-ord') || name.contains('coord') || name.contains('suit')) {
      return 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('men') || subCat.contains('men')) {
      return 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=600&auto=format&fit=crop&q=80';
    } else if (name.contains('women') || subCat.contains('women')) {
      return 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&auto=format&fit=crop&q=80';
    }

    return 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600&auto=format&fit=crop&q=80';
  }

  String _getWholesalerCategory(Map<String, dynamic> w) {
    if (w['categories'] is List) {
      for (var c in w['categories'] as List) {
        final cl = c.toString().toLowerCase();
        if (cl.contains('fashion') || cl.contains('apparel') || cl.contains('cloth')) {
          return 'Fashion';
        }
      }
    }
    final name = (w['businessName'] as String? ?? '').toLowerCase();
    if (name.contains('fashion') || name.contains('cloth') || name.contains('garment') || name.contains('textile') || name.contains('wear') || name.contains('apparel') || name.contains('dress') || name.contains('saree') || name.contains('kurti')) {
      return 'Fashion';
    }
    final wId = w['id'].toString();
    final prods = _products.where((p) => p['wholesalerId']?.toString() == wId || p['wholesaler']?['id']?.toString() == wId);
    for (var p in prods) {
      if (_isFashionProduct(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p))) {
        return 'Fashion';
      }
    }
    return 'Other';
  }

  List<Map<String, dynamic>> _getDynamicOfferBanners() {
    final List<Map<String, dynamic>> dynamicBanners = [];

    // 1. Wholesaler uploaded offer banners from backend (Seller Dashboard)
    for (var b in _backendBanners) {
      final title = b['title']?.toString() ?? 'Special Wholesale Offer';
      final subtitle = b['subtitle']?.toString() ?? 'Direct manufacturer wholesale rates';
      final tag = b['tag']?.toString() ?? 'SELLER OFFER';
      final img = b['imageUrl']?.toString() ?? '';
      final gStartHex = b['gradientStart']?.toString() ?? '#6C3BD5';
      final gEndHex = b['gradientEnd']?.toString() ?? '#BB4DE0';

      final Color gStart = _hexToColor(gStartHex, const Color(0xFF6C3BD5));
      final Color gEnd = _hexToColor(gEndHex, const Color(0xFFBB4DE0));

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
      if (_isFashionProduct(p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p))) {
        final offerText = p['offer']?.toString() ?? p['specialOffer']?.toString() ?? p['discountTag']?.toString();
        final img = (p['imageUrls'] as List?)?.isNotEmpty == true ? p['imageUrls'][0].toString() : null;
        if (offerText != null && offerText.isNotEmpty && img != null) {
          dynamicBanners.add({
            'title': p['name'] ?? 'Wholesale Special Offer',
            'subtitle': offerText,
            'tag': 'SELLER OFFER',
            'gradient': [const Color(0xFF6C3BD5), const Color(0xFFBB4DE0)],
            'icon': Icons.local_offer_rounded,
            'image': img.startsWith('/') ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$img' : img,
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

  Widget _buildFashionCategoryTile(Map<String, dynamic> item) {
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
                color: isOffer ? const Color(0xFFE50914) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? Border.all(color: const Color(0xFF6C3BD5), width: 2.5)
                    : Border.all(color: Colors.transparent, width: 2.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C3BD5).withValues(alpha: 0.25),
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
                          color: const Color(0xFFF3F4F6),
                          child: const Center(
                            child: Icon(Icons.checkroom_rounded, color: Color(0xFF6C3BD5), size: 28),
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
                color: isSelected ? const Color(0xFF6C3BD5) : const Color(0xFF1E293B),
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
      return _isFashionProduct(map);
    }).toList();

    if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty && _selectedSubCategory != 'All Fashion') {
      if (_selectedSubCategory == 'Offers') {
        list = list.where((p) {
          final price = parseDouble(p['price'] ?? p['pricePerUnit'], 0);
          final mrp = parseDouble(p['mrp'] ?? p['originalPrice'], price);
          final disc = mrp > 0 ? ((mrp - price) / mrp * 100).round() : 0;
          final offer = p['offer']?.toString() ?? p['specialOffer']?.toString() ?? p['discountTag']?.toString();
          return disc >= 30 || (offer != null && offer.isNotEmpty);
        }).toList();
      } else if (_selectedSubCategory == 'Women') {
        list = list.where((p) {
          final sub = (p['subCategory'] as String? ?? '').toLowerCase();
          final name = (p['name'] as String? ?? '').toLowerCase();
          final cat = (p['category'] as String? ?? '').toLowerCase();
          return sub.contains('women') || sub.contains('saree') || sub.contains('kurti') || sub.contains('dress') ||
                 name.contains('women') || name.contains('saree') || name.contains('kurti') || name.contains('dress') || cat.contains('women');
        }).toList();
      } else if (_selectedSubCategory == 'Men') {
        list = list.where((p) {
          final sub = (p['subCategory'] as String? ?? '').toLowerCase();
          final name = (p['name'] as String? ?? '').toLowerCase();
          final cat = (p['category'] as String? ?? '').toLowerCase();
          return sub.contains('men') || sub.contains('shirt') || sub.contains('jean') || sub.contains('trouser') ||
                 name.contains('men') || name.contains('shirt') || name.contains('jean') || cat.contains('men');
        }).toList();
      } else {
        final term = _selectedSubCategory!.toLowerCase().replaceAll('&', '').replaceAll('wear', '').trim();
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

  List get _fashionWholesalers {
    final list = _wholesalers.where((w) {
      final map = w is Map<String, dynamic> ? w : Map<String, dynamic>.from(w);
      return _getWholesalerCategory(map) == 'Fashion';
    }).toList();

    if (list.isNotEmpty) return list;

    // Verified default fashion suppliers if none registered in DB yet
    return [
      {
        'id': 'fashion-mill-1',
        'businessName': 'Surat Silk & Textile Mills',
        'businessAddress': 'Ring Road Textile Market, Surat',
        'categories': ['Fashion'],
      },
      {
        'id': 'fashion-mill-2',
        'businessName': 'Bombay Garment & Apparel Hub',
        'businessAddress': 'Dadar Wholesale Cloth Market, Mumbai',
        'categories': ['Fashion'],
      },
      {
        'id': 'fashion-mill-3',
        'businessName': 'Delhi Raymond & Ethnic Wholesale',
        'businessAddress': 'Chandni Chowk Cloth Mandi, Delhi',
        'categories': ['Fashion'],
      },
      {
        'id': 'fashion-mill-4',
        'businessName': 'Jaipur Kurti & Saree Manufacturers',
        'businessAddress': 'Johari Bazaar Wholesale, Jaipur',
        'categories': ['Fashion'],
      },
    ];
  }

  List get _forYouProducts {
    final fashionProds = _products.where((p) {
      final map = p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p);
      return _isFashionProduct(map);
    }).toList();

    if (fashionProds.isNotEmpty) {
      return fashionProds.take(8).toList();
    }
    return _products.take(8).toList();
  }

  List get _recommendedProducts {
    final fashionProds = _products.where((p) {
      final map = p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p);
      return _isFashionProduct(map);
    }).toList();

    final source = fashionProds.isNotEmpty ? fashionProds : _products;
    final sorted = List.from(source);
    sorted.sort((a, b) {
      final pa = (a['price'] as num?)?.toDouble() ?? 0;
      final pb = (b['price'] as num?)?.toDouble() ?? 0;
      return pb.compareTo(pa);
    });
    return sorted.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final banners = _getDynamicOfferBanners();
    final fashionShops = _fashionWholesalers;
    final forYou = _forYouProducts;
    final recommended = _recommendedProducts;
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
                color: const Color(0xFF6C3BD5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.checkroom_rounded, color: Color(0xFF6C3BD5), size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Fashion Hub',
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
                backgroundColor: const Color(0xFF6C3BD5),
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3BD5)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF6C3BD5),
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
                            hintText: 'Search fashion wear, sarees, kurtis, brands...',
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
                                                b['icon'] as IconData? ?? Icons.checkroom_rounded,
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
                                        ? const Color(0xFF6C3BD5)
                                        : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. FASHION CATEGORIES (2-Row Real Photo Visual Cards)
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
                                  'FASHION CATEGORIES',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF6C3BD5),
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
                              itemCount: _fashionRow1.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (_, colIdx) {
                                final topItem = _fashionRow1[colIdx];
                                final bottomItem = _fashionRow2[colIdx];
                                return Column(
                                  children: [
                                    _buildFashionCategoryTile(topItem),
                                    const SizedBox(height: 12),
                                    _buildFashionCategoryTile(bottomItem),
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
                  if (fashionShops.isNotEmpty && _search.isEmpty)
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
                                    'Fashion Wholesale Shops',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${fashionShops.length} Verified',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6C3BD5),
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
                                itemCount: fashionShops.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, idx) {
                                  final w = fashionShops[idx];
                                  final wId = w['id'].toString();
                                  final profilePic = w['user']?['profilePicture'];
                                  final shopProducts = _products
                                      .where((p) => p['wholesalerId']?.toString() == wId || p['wholesaler']?['id']?.toString() == wId)
                                      .toList();
                                  final productCount = shopProducts.length;

                                  final shopGradients = [
                                    [const Color(0xFF6C3BD5), const Color(0xFFBB4DE0)],
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
                                              child: const Icon(Icons.verified_rounded, color: Color(0xFF6C3BD5), size: 13),
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



                  // 7. ALL FASHION PRODUCTS GRID HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            _selectedSubCategory != null ? _selectedSubCategory!.toUpperCase() : 'ALL FASHION PRODUCTS',
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
                              const Icon(Icons.checkroom_outlined, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text(
                                'No fashion products found',
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
                            return _FashionProductCard(
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

class _FashionProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _FashionProductCard({required this.product, required this.onTap});

  @override
  State<_FashionProductCard> createState() => _FashionProductCardState();
}

class _FashionProductCardState extends State<_FashionProductCard> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cart = context.watch<CartProvider>();
    final pId = p['id'].toString();
    final pName = p['name'] ?? 'Product';
    final brand = p['brand'] ?? 'Fashion Brand';
    final sku = 'SKU: ${p['sku'] ?? p['itemCode'] ?? 'FS-101'}';

    final sellingPrice = _FashionCategoryScreenState.parseDouble(p['price'] ?? p['pricePerUnit'], 0);
    final originalPrice = _FashionCategoryScreenState.parseDouble(p['mrp'] ?? p['originalPrice'], sellingPrice > 0 ? sellingPrice * 1.3 : 1000);
    final bestPrice = _FashionCategoryScreenState.parseDouble(p['bestPrice'], sellingPrice > 0 ? sellingPrice * 0.95 : 950);
    final discount = originalPrice > 0 ? ((originalPrice - sellingPrice) / originalPrice * 100).round() : 0;
    final minQty = _FashionCategoryScreenState.parseInt(p['moq'], 6);
    final moq = 'MOQ: $minQty pcs';
    final offer = p['offer'] ?? (discount > 0 ? '$discount% Off on wholesale bulk' : 'Special Wholesaler Rate');
    final extraDiscount = p['specialOffer'] ?? (discount > 15 ? 'Extra 5% off on 50+ units' : 'Free Shipping above ₹5,000');

    final imageUrl = _FashionCategoryScreenState.getProductImage(p);

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
                            color: const Color(0xFF6C3BD5),
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
                              color: const Color(0xFF6C3BD5),
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
                                    backgroundColor: Color(0xFF6C3BD5),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C3BD5),
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
