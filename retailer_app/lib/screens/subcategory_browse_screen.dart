import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'wholesaler_shop_screen.dart';
import 'product_details_screen.dart';
import 'fashion_category_screen.dart';
import 'grocery_category_screen.dart';
import 'category_hub_screen.dart';

class SubCategoryBrowseScreen extends StatefulWidget {
  final String category;
  final String? initialSubCategory;

  const SubCategoryBrowseScreen({
    super.key,
    required this.category,
    this.initialSubCategory,
  });

  @override
  State<SubCategoryBrowseScreen> createState() => _SubCategoryBrowseScreenState();
}

class _SubCategoryBrowseScreenState extends State<SubCategoryBrowseScreen> {
  List _products = [];
  List _wholesalers = [];
  Set<String> _favoritedIds = {};
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  String? _selectedSubCategory;
  String? _selectedSubSubCategory;

  // Curated category colors & icons mapping for branding consistency
  static const Map<String, Map<String, dynamic>> _categoryMeta = {
    'Grocery': {
      'color': Color(0xFFFF9F00),
      'icon': Icons.shopping_basket_outlined,
      'image': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=120&auto=format&fit=crop&q=60',
    },
    'Mobiles': {
      'color': Color(0xFF2874F0),
      'icon': Icons.phone_android_outlined,
      'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=120&auto=format&fit=crop&q=60',
    },
    'Fashion': {
      'color': Color(0xFF388E3C),
      'icon': Icons.checkroom_outlined,
      'image': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=120&auto=format&fit=crop&q=60',
    },
    'Electronics': {
      'color': Color(0xFF00C2FF),
      'icon': Icons.tv_outlined,
      'image': 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=120&auto=format&fit=crop&q=60',
    },
    'Home & Furniture': {
      'color': Color(0xFF8E44AD),
      'icon': Icons.chair_outlined,
      'image': 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=120&auto=format&fit=crop&q=60',
    },
    'Home': {
      'color': Color(0xFF8E44AD),
      'icon': Icons.chair_outlined,
      'image': 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=120&auto=format&fit=crop&q=60',
    },
    'Beauty': {
      'color': Color(0xFFE91E63),
      'icon': Icons.face_retouching_natural_outlined,
      'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=120&auto=format&fit=crop&q=60',
    },
    'Kitchen': {
      'color': Color(0xFFD35400),
      'icon': Icons.restaurant_outlined,
      'image': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=120&auto=format&fit=crop&q=60',
    },
    'Fruits & Vegetables': {
      'color': Color(0xFF2ECC71),
      'icon': Icons.local_florist_outlined,
      'image': 'https://images.unsplash.com/photo-1573244514212-2b3a14736758?w=120&auto=format&fit=crop&q=60',
    },
    'Dairy & Bakery': {
      'color': Color(0xFF3498DB),
      'icon': Icons.cookie_outlined,
      'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=120&auto=format&fit=crop&q=60',
    },
    'Stationery': {
      'color': Color(0xFF16A085),
      'icon': Icons.menu_book_outlined,
      'image': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=120&auto=format&fit=crop&q=60',
    },
    'Sports': {
      'color': Color(0xFFE67E22),
      'icon': Icons.sports_cricket_outlined,
      'image': 'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=120&auto=format&fit=crop&q=60',
    },
    'Hardware': {
      'color': Color(0xFF7F8C8D),
      'icon': Icons.build_outlined,
      'image': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=120&auto=format&fit=crop&q=60',
    },
  };

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
    'Home': ['Bedding & Linens', 'Curtains & Cushions', 'Furniture', 'Home Decor', 'Lighting & Lamps'],
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



  static const Map<String, String> _subCategoryImages = {
    // Grocery
    'Rice & Grains': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=100&auto=format&fit=crop&q=60',
    'Atta & Flours': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=100&auto=format&fit=crop&q=60',
    'Edible Oils': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=100&auto=format&fit=crop&q=60',
    'Spices & Masalas': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=100&auto=format&fit=crop&q=60',
    'Snacks & Packaged Food': 'https://images.unsplash.com/photo-1599490659213-e2b9527bc087?w=100&auto=format&fit=crop&q=60',
    'Beverages': 'https://images.unsplash.com/photo-1527960656306-fffe3c6120c8?w=100&auto=format&fit=crop&q=60',
    // Mobiles
    'Smartphones': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=100&auto=format&fit=crop&q=60',
    'Keypad Phones': 'https://images.unsplash.com/photo-1523206489230-c012c64b2b48?w=100&auto=format&fit=crop&q=60',
    'Mobile Chargers': 'https://images.unsplash.com/photo-1622445262465-2481c4574875?w=100&auto=format&fit=crop&q=60',
    'Earphones & Headphones': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=100&auto=format&fit=crop&q=60',
    'Power Banks': 'https://images.unsplash.com/photo-1609592424085-78e762c2f602?w=100&auto=format&fit=crop&q=60',
    'Cases & Covers': 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=100&auto=format&fit=crop&q=60',
    // Fashion
    'Fancy Saree': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=100&auto=format&fit=crop&q=60',
    'Chiffon': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=100&auto=format&fit=crop&q=60',
    'Suit-Unistitched': 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=100&auto=format&fit=crop&q=60',
    'Georgette': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=100&auto=format&fit=crop&q=60',
    'Silk': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=100&auto=format&fit=crop&q=60',
    'Cotton': 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=100&auto=format&fit=crop&q=60',
    'Lehenga': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=100&auto=format&fit=crop&q=60',
    'Gowns': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=100&auto=format&fit=crop&q=60',
    'Kurti/Set': 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=100&auto=format&fit=crop&q=60',
    'Men': 'https://images.unsplash.com/photo-1488161628813-04466f872be2?w=100&auto=format&fit=crop&q=60',
    // Electronics
    'Smart TVs': 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=100&auto=format&fit=crop&q=60',
    'Speakers & Audio': 'https://images.unsplash.com/photo-1545454675-3531b543be5d?w=100&auto=format&fit=crop&q=60',
    'Cameras': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=100&auto=format&fit=crop&q=60',
    'Power & Charging': 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=100&auto=format&fit=crop&q=60',
    'Home Appliances': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=100&auto=format&fit=crop&q=60',
    // Home & Furniture
    'Bedding & Linens': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=100&auto=format&fit=crop&q=60',
    'Curtains & Cushions': 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e6?w=100&auto=format&fit=crop&q=60',
    'Furniture': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=100&auto=format&fit=crop&q=60',
    'Home Decor': 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=100&auto=format&fit=crop&q=60',
    'Lighting & Lamps': 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=100&auto=format&fit=crop&q=60',
    // Beauty
    'Makeup & Cosmetics': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=100&auto=format&fit=crop&q=60',
    'Skincare': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=100&auto=format&fit=crop&q=60',
    'Haircare': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=100&auto=format&fit=crop&q=60',
    'Perfumes & Deos': 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=100&auto=format&fit=crop&q=60',
    'Personal Care': 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=100&auto=format&fit=crop&q=60',
    // Kitchen
    'Cookware & Pots': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=100&auto=format&fit=crop&q=60',
    'Tableware & Plates': 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=100&auto=format&fit=crop&q=60',
    'Gas Stoves': 'https://images.unsplash.com/photo-1522836924445-4478bdeb860c?w=100&auto=format&fit=crop&q=60',
    'Water Bottles': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=100&auto=format&fit=crop&q=60',
    'Kitchen Tools': 'https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?w=100&auto=format&fit=crop&q=60',
    // Fruits & Vegetables
    'Fresh Vegetables': 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=100&auto=format&fit=crop&q=60',
    'Fresh Fruits': 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?w=100&auto=format&fit=crop&q=60',
    'Organic Greens': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=100&auto=format&fit=crop&q=60',
    'Exotic Produce': 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?w=100&auto=format&fit=crop&q=60',
    // Dairy & Bakery
    'Milk & Cream': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=100&auto=format&fit=crop&q=60',
    'Butter & Cheese': 'https://images.unsplash.com/photo-1486887396153-fa416525c108?w=100&auto=format&fit=crop&q=60',
    'Paneer & Tofu': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&auto=format&fit=crop&q=60',
    'Fresh Bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=100&auto=format&fit=crop&q=60',
    'Cakes & Muffins': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=100&auto=format&fit=crop&q=60',
    // Stationery
    'Notebooks & Diaries': 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=100&auto=format&fit=crop&q=60',
    'Pens & Pencils': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=100&auto=format&fit=crop&q=60',
    'Office Supplies': 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=100&auto=format&fit=crop&q=60',
    'Art & Craft': 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=100&auto=format&fit=crop&q=60',
    'School Kits': 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?w=100&auto=format&fit=crop&q=60',
    // Sports
    'Cricket Gear': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=100&auto=format&fit=crop&q=60',
    'Fitness & Gym': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=100&auto=format&fit=crop&q=60',
    'Badminton & Tennis': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=100&auto=format&fit=crop&q=60',
    'Indoor Games': 'https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=100&auto=format&fit=crop&q=60',
    'Sports Wear': 'https://images.unsplash.com/photo-1483721310020-03333e577078?w=100&auto=format&fit=crop&q=60',
    // Hardware
    'Power Tools': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=100&auto=format&fit=crop&q=60',
    'Hand Tools': 'https://images.unsplash.com/photo-1530124560676-105518553fe9?w=100&auto=format&fit=crop&q=60',
    'Screws & Nails': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=100&auto=format&fit=crop&q=60',
    'Electrical Supplies': 'https://images.unsplash.com/photo-1558346490-a72e53ae2d4f?w=100&auto=format&fit=crop&q=60',
    'Plumbing Fittings': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=100&auto=format&fit=crop&q=60',
    // Sub-subcategories (Fashion > Kurti/Set)
    'Kurti Set': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=100&auto=format&fit=crop&q=60',
    'Kurti': 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=100&auto=format&fit=crop&q=60',
    'Coord Set': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=100&auto=format&fit=crop&q=60',
    'Plazo Set': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=100&auto=format&fit=crop&q=60',
    'Tops': 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=100&auto=format&fit=crop&q=60',
    // Sub-subcategories (Fashion > Men)
    'T Shirt': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=100&auto=format&fit=crop&q=60',
    'Pent': 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=100&auto=format&fit=crop&q=60',
    'Shirts': 'https://images.unsplash.com/photo-1603252109303-2751441dd157?w=100&auto=format&fit=crop&q=60',
    'Lower': 'https://images.unsplash.com/photo-1551854838-212c50b4c184?w=100&auto=format&fit=crop&q=60',
    'Jeans': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=100&auto=format&fit=crop&q=60',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty) {
      _selectedSubCategory = widget.initialSubCategory;
    }
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final productsData = await ApiService.get('/products') as List? ?? [];
      final wholesalersData = await ApiService.get('/wholesalers') as List? ?? [];
      final favsData = await ApiService.get('/wholesalers/favorites/my') as List? ?? [];

      final favIds = favsData.map((w) => w['id'].toString()).toSet();

      if (!mounted) return;
      setState(() {
        _products = productsData;
        _wholesalers = wholesalersData;
        _favoritedIds = favIds;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading products for category: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(String wholesalerId) async {
    try {
      final res = await ApiService.post('/wholesalers/$wholesalerId/favorite', {});
      final favorited = res['favorited'] as bool;
      if (!mounted) return;
      setState(() {
        if (favorited) {
          _favoritedIds.add(wholesalerId);
        } else {
          _favoritedIds.remove(wholesalerId);
        }
      });
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  String _getWholesalerCategory(Map<String, dynamic> w) {
    final wId = w['id'].toString();
    final wProducts = _products.where((p) => p['wholesalerId']?.toString() == wId || p['wholesaler']?['id']?.toString() == wId).toList();
    if (wProducts.isNotEmpty) {
      final counts = <String, int>{};
      for (final p in wProducts) {
        final cat = p['category']?.toString() ?? '';
        final mainCat = cat.split(' > ').first;
        if (mainCat.isNotEmpty) {
          counts[mainCat] = (counts[mainCat] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        var bestCat = '';
        var maxCount = 0;
        counts.forEach((cat, count) {
          if (count > maxCount) {
            maxCount = count;
            bestCat = cat;
          }
        });
        return bestCat;
      }
    }
    
    final name = (w['businessName'] as String? ?? '').toLowerCase();
    if (name.contains('fashion') || name.contains('wear') || name.contains('clothing')) return 'Fashion';
    if (name.contains('grocery') || name.contains('mart') || name.contains('store')) return 'Grocery';
    if (name.contains('mobile') || name.contains('phone')) return 'Mobiles';
    if (name.contains('electro')) return 'Electronics';
    if (name.contains('kitchen') || name.contains('cook')) return 'Kitchen';
    if (name.contains('beauty') || name.contains('cosmetic')) return 'Beauty';
    if (name.contains('fruit') || name.contains('veg')) return 'Fruits & Vegetables';
    if (name.contains('dairy') || name.contains('bake')) return 'Dairy & Bakery';
    if (name.contains('station') || name.contains('book')) return 'Stationery';
    if (name.contains('sport') || name.contains('fit')) return 'Sports';
    if (name.contains('hardware') || name.contains('tool')) return 'Hardware';
    return 'Wholesale';
  }



  List get _filteredWholesalers {
    final target = widget.category.toLowerCase();
    return _wholesalers.where((w) {
      final cat = _getWholesalerCategory(w).toLowerCase();
      if (target == 'home' || target == 'home & furniture') {
        return cat == 'home' || cat == 'home & furniture';
      }
      return cat == target;
    }).toList();
  }

  List get _filteredProducts {
    return _products.where((p) {
      final pCat = (p['category'] as String? ?? '').toLowerCase();
      final mainSel = widget.category.toLowerCase();
      
      bool matchesMain = pCat == mainSel || pCat.startsWith('$mainSel > ');
      if (mainSel.contains('deal') || mainSel.contains('discount') || mainSel == 'all') {
        matchesMain = true;
      } else if (!matchesMain && (mainSel == 'home' || mainSel == 'home & furniture')) {
        matchesMain = pCat.startsWith('home > ') || pCat.startsWith('home & furniture > ') || pCat == 'home' || pCat == 'home & furniture';
      }

      if (!matchesMain) return false;

      if (_selectedSubCategory != null) {
        final subSel = _selectedSubCategory!.toLowerCase();
        if (subSel.contains('20%-40%')) {
          final double disc = double.tryParse(p['discount']?.toString() ?? '0') ?? (((p['name'] as String? ?? '').length * 3) % 25.0 + 15.0);
          if (disc < 15 || disc > 45) return false;
        } else if (subSel.contains('40%-60%')) {
          final double disc = double.tryParse(p['discount']?.toString() ?? '0') ?? (((p['name'] as String? ?? '').length * 4) % 30.0 + 35.0);
          if (disc < 35 || disc > 65) return false;
        } else if (subSel.contains('60%-80%')) {
          final double disc = double.tryParse(p['discount']?.toString() ?? '0') ?? (((p['name'] as String? ?? '').length * 5) % 30.0 + 55.0);
          if (disc < 55 || disc > 85) return false;
        } else if (subSel.contains('80%')) {
          final double disc = double.tryParse(p['discount']?.toString() ?? '0') ?? 85.0;
          if (disc < 75) return false;
        } else {
          final matchesSub = pCat.startsWith('$mainSel > $subSel') || pCat == '$mainSel > $subSel' || pCat.contains(subSel) || (p['name'] as String? ?? '').toLowerCase().contains(subSel);
          if (!matchesSub) return false;
        }

        if (_selectedSubSubCategory != null) {
          final subSubSel = _selectedSubSubCategory!.toLowerCase();
          final matchesSubSub = pCat == '$mainSel > $subSel > $subSubSel' || (p['name'] as String? ?? '').toLowerCase().contains(subSubSel);
          if (!matchesSubSub) return false;
        }
      }

      if (_search.isNotEmpty) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        if (!name.contains(_search.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final catLower = widget.category.toLowerCase();
    if (catLower == 'fashion') {
      return FashionCategoryScreen(initialSubCategory: widget.initialSubCategory);
    } else if (catLower.contains('grocery') || catLower.contains('rice') || catLower.contains('atta') || catLower.contains('oil') || catLower.contains('beverage') || catLower.contains('food') || catLower.contains('dairy')) {
      return GroceryCategoryScreen(initialSubCategory: widget.initialSubCategory);
    } else {
      return CategoryHubScreen(category: widget.category, initialSubCategory: widget.initialSubCategory);
    }

    final cart = context.watch<CartProvider>();
    final meta = _categoryMeta[widget.category] ?? {'color': const Color(0xFF2874F0), 'icon': Icons.category_outlined};
    final Color themeColor = meta['color'];
    final IconData titleIcon = meta['icon'];

    final subs = _subCategories[widget.category] ?? [];

    List<String> subSubs = [];
    if (_selectedSubCategory != null) {
      final nestedKey = '${widget.category} > $_selectedSubCategory';
      subSubs = _subSubCategories[nestedKey] ?? [];
    }

    final filtered = _filteredProducts;
    final filteredShops = _filteredWholesalers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2EDFD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Row(
          children: [
            Icon(titleIcon, color: const Color(0xFF0057D9), size: 22),
            const SizedBox(width: 8),
            Text(
              widget.category,
              style: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2874F0)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF2874F0),
              child: CustomScrollView(
                slivers: [
                // 1. Search header (same style as BrowseScreen but category themed)
                SliverToBoxAdapter(
                  child: Container(
                    color: const Color(0xFFE2EDFD),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Search in this category',
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

                // 2. Horizontal Subcategory chips bar
                if (subs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 50,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: subs.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == 0) {
                            final isSelected = _selectedSubCategory == null;
                            final parentImage = meta['image'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Image.network(
                                      parentImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            titleIcon,
                                            size: 10,
                                            color: isSelected ? Colors.white : themeColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                label: Text(
                                  'All ${widget.category}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF212121),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSubCategory = null;
                                    _selectedSubSubCategory = null;
                                  });
                                },
                                selectedColor: themeColor,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: isSelected ? themeColor : Colors.grey.shade300),
                                ),
                              ),
                            );
                          }

                          final sub = subs[idx - 1];
                          final isSelected = _selectedSubCategory == sub;
                          final imageUrl = _subCategoryImages[sub] ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(Icons.category_outlined, size: 14, color: isSelected ? Colors.white : themeColor),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              label: Text(
                                sub,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF212121),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedSubCategory = sub;
                                  _selectedSubSubCategory = null;
                                });
                              },
                              selectedColor: themeColor,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: isSelected ? themeColor : Colors.grey.shade300),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // 3. Second tier of chips: Sub-subcategories (nested)
                if (_selectedSubCategory != null && subSubs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 44,
                      color: Colors.grey.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: subSubs.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == 0) {
                            final isSelected = _selectedSubSubCategory == null;
                            final subImage = _subCategoryImages[_selectedSubCategory] ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Image.network(
                                      subImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(Icons.category_outlined, size: 14, color: themeColor),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                label: Text(
                                  'All $_selectedSubCategory',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? themeColor : Colors.grey.shade700,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSubSubCategory = null;
                                  });
                                },
                                selectedColor: themeColor.withAlpha(25),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: isSelected ? themeColor : Colors.transparent),
                                ),
                              ),
                            );
                          }

                          final subSub = subSubs[idx - 1];
                          final isSelected = _selectedSubSubCategory == subSub;
                          final imageUrl = _subCategoryImages[subSub] ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(Icons.category_outlined, size: 14, color: isSelected ? themeColor : Colors.grey.shade600),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              label: Text(
                                subSub,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? themeColor : Colors.grey.shade700,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedSubSubCategory = subSub;
                                });
                              },
                              selectedColor: themeColor.withAlpha(25),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: isSelected ? themeColor : Colors.transparent),
                                ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // 4. Horizontal scroll of filtered Wholesaler Shops matching this category
                if (filteredShops.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wholesale ${widget.category} Shops',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF212121),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Direct suppliers for ${widget.category} products',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF878787),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredShops.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final w = filteredShops[index];
                          final wId = w['id'].toString();
                          final isFav = _favoritedIds.contains(wId);
                          final profilePic = w['user']?['profilePicture'];
                          final shopCat = _getWholesalerCategory(w);

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
                              width: 125,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: themeColor.withAlpha(15),
                                        backgroundImage: profilePic != null && profilePic.toString().isNotEmpty
                                            ? NetworkImage(
                                                profilePic.toString().startsWith('/')
                                                    ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$profilePic'
                                                    : profilePic.toString(),
                                              )
                                            : null,
                                        child: profilePic == null || profilePic.toString().isEmpty
                                            ? Icon(Icons.storefront_rounded, color: themeColor, size: 20)
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              w['businessName'] ?? 'Wholesaler',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF212121),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.verified, color: Colors.blue, size: 10),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: themeColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          shopCat.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            color: themeColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 9),
                                          const SizedBox(width: 2),
                                          Text(
                                            (3.8 + (w['businessName']?.toString().length ?? 0) % 13 / 10).toStringAsFixed(1),
                                            style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: GestureDetector(
                                      onTap: () => _toggleFavorite(wId),
                                      child: CircleAvatar(
                                        radius: 11,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: isFav ? Colors.red : Colors.grey.shade400,
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // 5. Category products section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedSubCategory == null
                              ? 'All ${widget.category} Products'
                              : _selectedSubSubCategory == null
                                  ? '$_selectedSubCategory Products'
                                  : '$_selectedSubSubCategory Styles',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: const Color(0xFF212121),
                          ),
                        ),
                        Text(
                          '${filtered.length} items',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF878787),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 6. Products list grid
                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No products found in this category',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try clearing search filters or checking other departments',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final p = filtered[idx];
                              final inCart = cart.items.any((ci) => ci.productId == p['id']);
                              return _ProductCard(
                                product: p,
                                inCart: inCart,
                                onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(product: p),
                                      ),
                                    ).then((_) => _load());
                                },
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool inCart;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.inCart,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isWishlisted = false;

  Widget _buildAddQtyButton(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartItems = cart.items.where((ci) => ci.productId == widget.product['id']).toList();
    final qty = cartItems.isNotEmpty ? cartItems.first.quantity : 0;

    if (qty == 0) {
      return GestureDetector(
        onTap: () {
          context.read<CartProvider>().addItem(widget.product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${widget.product['name']} to cart'),
              backgroundColor: const Color(0xFF0057D9),
              duration: const Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFE2EDFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0057D9).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Color(0xFF0057D9), size: 12),
              const SizedBox(width: 2),
              Text(
                'ADD',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0057D9),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFF0057D9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => context.read<CartProvider>().decrement(widget.product['id']),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.remove, color: Colors.white, size: 12),
            ),
          ),
          Text(
            '$qty',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          GestureDetector(
            onTap: () => context.read<CartProvider>().addItem(widget.product),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.add, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final String pName = p['name'] ?? 'Wholesale Product';
    final double originalPrice = double.tryParse(p['pricePerUnit']?.toString() ?? '0') ?? 150.0;
    final double discount = double.tryParse(p['discount']?.toString() ?? '0') ?? 15.0;
    final double sellingPrice = discount > 0 ? originalPrice * (1 - discount / 100) : originalPrice;
    final double bestPrice = sellingPrice * 0.90;
    final String brand = p['brand'] ?? (p['category']?.toString().split(' > ').first ?? 'Zone Brand');
    final String sku = p['sku'] ?? 'SKU: ZON-${(pName.length * 147) % 8999 + 1000}';
    final String moq = p['moq'] ?? 'MOQ: ${(pName.length % 5) + 5} Units';
    final String offer = p['offer'] ?? (discount > 20 ? 'Buy 10 Get 1 Free' : '5% Cashback');
    final String extraDiscount = p['extraDiscount'] ?? 'Extra ₹15 Off on Prepaid';
    final bool inStock = p['stock'] == null ? true : (p['stock'] is int ? (p['stock'] as int) > 0 : true);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // 1. PRODUCT IMAGE + BADGES (Wishlist, Discount %, Stock Status)
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty
                            ? Image.network(
                                p['imageUrl'].startsWith('/')
                                    ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}${p['imageUrl']}'
                                    : p['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 36),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 36),
                              ),
                      ),
                    ),
                  ),
                  // Discount % Badge
                  if (discount > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${discount.toStringAsFixed(0)}% OFF',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  // Stock Status Badge
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: inStock ? const Color(0xFF16A34A) : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Wishlist Heart Icon Toggle
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
            ),

            // 2. PRODUCT DETAILS CONTAINER (All 14 fields)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand
                        Text(
                          brand.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0071DC),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        // Product Name
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
                        // SKU Item Number
                        Text(
                          sku,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Selling Price & MRP (Cut Price)
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

                        // Best Price Tag
                        Text(
                          'Best Price: ₹${bestPrice.toStringAsFixed(0)}/unit',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF16A34A),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // MOQ Tag
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

                        // Offer Applicable
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

                        // Extra Discount
                        Text(
                          '$extraDiscount',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2563EB),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Add to Cart Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildAddQtyButton(context),
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
