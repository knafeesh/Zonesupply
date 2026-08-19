import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'wholesaler_shop_screen.dart';
import 'subcategory_browse_screen.dart';
import 'fashion_category_screen.dart';
import 'grocery_category_screen.dart';
import 'category_hub_screen.dart';
import 'brand_subcategory_screen.dart';
import 'package:core/widgets/app_header.dart';
import 'profile_screen.dart';

class BrowseScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const BrowseScreen({super.key, this.onProfileTap});
  @override
  State<BrowseScreen> createState() => BrowseScreenState();
}

class BrowseScreenState extends State<BrowseScreen> {
  List _products = [];
  List _wholesalers = [];
  Set<String> _favoritedIds = {};
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  int _notificationCount = 4;
  final List<Map<String, dynamic>> _notificationsList = [
    {
      'id': '1',
      'title': 'Order Dispatched',
      'body': 'Order #ZS-8891 has been dispatched and is on the way.',
      'time': '2 mins ago',
      'isRead': false,
      'icon': Icons.local_shipping_outlined,
      'color': const Color(0xFF0057D9),
    },
    {
      'id': '2',
      'title': 'Payment Confirmed',
      'body': 'Payment of ₹1,250.00 for Order #ZS-8843 has been confirmed.',
      'time': '1 hour ago',
      'isRead': false,
      'icon': Icons.check_circle_outline_rounded,
      'color': const Color(0xFF388E3C),
    },
    {
      'id': '3',
      'title': 'New Bulk Discount',
      'body': 'Wholesaler added a 15% bulk discount on Wheat Flour in your zone.',
      'time': '5 hours ago',
      'isRead': false,
      'icon': Icons.local_offer_outlined,
      'color': const Color(0xFFFF9F00),
    },
    {
      'id': '4',
      'title': 'Zone Pool Consolidated',
      'body': 'Your group order with 3 nearby shops is consolidated. Saving ₹120!',
      'time': '1 day ago',
      'isRead': false,
      'icon': Icons.people_outline_rounded,
      'color': const Color(0xFF8E44AD),
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Grocery',
      'icon': Icons.shopping_basket_outlined,
      'color': const Color(0xFFFF9F00),
      'image': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Mobiles',
      'icon': Icons.phone_android_outlined,
      'color': const Color(0xFF2874F0),
      'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Fashion',
      'icon': Icons.checkroom_outlined,
      'color': const Color(0xFF388E3C),
      'image': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Electronics',
      'icon': Icons.tv_outlined,
      'color': const Color(0xFF00C2FF),
      'image': 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Home & Furniture',
      'icon': Icons.chair_outlined,
      'color': const Color(0xFF8E44AD),
      'image': 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Beauty',
      'icon': Icons.face_retouching_natural_outlined,
      'color': const Color(0xFFE91E63),
      'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Kitchen',
      'icon': Icons.restaurant_outlined,
      'color': const Color(0xFFD35400),
      'image': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Fruits & Vegetables',
      'icon': Icons.local_florist_outlined,
      'color': const Color(0xFF2ECC71),
      'image': 'https://images.unsplash.com/photo-1573244514212-2b3a14736758?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Dairy & Bakery',
      'icon': Icons.cookie_outlined,
      'color': const Color(0xFF3498DB),
      'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Stationery',
      'icon': Icons.menu_book_outlined,
      'color': const Color(0xFF16A085),
      'image': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_cricket_outlined,
      'color': const Color(0xFFE67E22),
      'image': 'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=120&auto=format&fit=crop&q=60'
    },
    {
      'name': 'Hardware',
      'icon': Icons.build_outlined,
      'color': const Color(0xFF7F8C8D),
      'image': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=120&auto=format&fit=crop&q=60'
    },
  ];

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Bulk Discounts',
      'subtitle': 'Big Savings on Brand Mobiles, Grocery, Fashion & Electronics',
      'image': 'assets/images/bulk_discounts.jpg',
      'color': const Color(0xFF2874F0),
    },
    {
      'title': 'Super Saver Offers',
      'subtitle': 'Check our daily super savings on all categories',
      'image': 'assets/images/super_saver.jpg',
      'color': const Color(0xFFFB641B),
    },
    {
      'title': 'Free Delivery Campaign',
      'subtitle': 'Consolidated zero-fee delivery in your zone',
      'image': 'assets/images/free_delivery.jpg',
      'color': const Color(0xFF388E3C),
    },
  ];

  final List<Map<String, dynamic>> _brands = [
    {
      'name': 'Coca-Cola',
      'category': 'Beverages',
      'tagline': 'Soft Drinks',
      'logo': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFFE50914),
    },
    {
      'name': 'Unilever',
      'category': 'Home Care',
      'tagline': 'Personal & Home',
      'logo': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFF0057D9),
    },
    {
      'name': 'Nestlé',
      'category': 'Packaged Foods & Dry Fruits',
      'tagline': 'Maggi & Foods',
      'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFFD32F2F),
    },
    {
      'name': 'P&G',
      'category': 'Home Care',
      'tagline': 'Laundry & Care',
      'logo': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFF1976D2),
    },
    {
      'name': 'ITC',
      'category': 'Grocery',
      'tagline': 'Aashirvaad & Foods',
      'logo': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFF388E3C),
    },
    {
      'name': 'Amul',
      'category': 'Dairy, Fresh & Frozen',
      'tagline': 'Dairy & Butter',
      'logo': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFF0288D1),
    },
    {
      'name': 'Britannia',
      'category': 'Packaged Foods & Dry Fruits',
      'tagline': 'Biscuits & Cookies',
      'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFFE65100),
    },
    {
      'name': 'Parle',
      'category': 'Packaged Foods & Dry Fruits',
      'tagline': 'Parle-G & Snacks',
      'logo': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFFF57C00),
    },
    {
      'name': 'Dabur',
      'category': 'Health & OTC',
      'tagline': 'Health & Juices',
      'logo': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFF2E7D32),
    },
    {
      'name': 'Godrej',
      'category': 'Home Care',
      'tagline': 'Home & Hygiene',
      'logo': 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=300&auto=format&fit=crop&q=80',
      'color': const Color(0xFF6A1B9A),
    },
  ];


  @override
  void initState() {
    super.initState();
    _load();
    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
        });
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
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

      setState(() {
        _products = productsData;
        _wholesalers = wholesalersData;
        _favoritedIds = favIds;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => _loading = false);
    }
  }

  // selectCategory is kept for compatibility with HomeScreen's category tab navigation.
  // Category filtering is now handled by SubCategoryBrowseScreen.
  void selectCategory(String? categoryName) {}

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
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: Colors.red,
        ));
      }
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

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Grocery': return const Color(0xFFFF9F00);
      case 'Mobiles': return const Color(0xFF2874F0);
      case 'Fashion': return const Color(0xFF388E3C);
      case 'Electronics': return const Color(0xFF00C2FF);
      case 'Home & Furniture':
      case 'Home': return const Color(0xFF8E44AD);
      case 'Beauty': return const Color(0xFFE91E63);
      case 'Kitchen': return const Color(0xFFD35400);
      case 'Fruits & Vegetables': return const Color(0xFF2ECC71);
      case 'Dairy & Bakery': return const Color(0xFF3498DB);
      case 'Stationery': return const Color(0xFF16A085);
      case 'Sports': return const Color(0xFFE67E22);
      case 'Hardware': return const Color(0xFF7F8C8D);
      default: return const Color(0xFF878787);
    }
  }


  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (_notificationCount > 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _notificationCount = 0;
                              for (var n in _notificationsList) {
                                n['isRead'] = true;
                              }
                            });
                            setModalState(() {});
                          },
                          child: Text(
                            'Mark all as read',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0057D9),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_notificationsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No notifications yet',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _notificationsList.length,
                        separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final n = _notificationsList[index];
                          final bool isUnread = !n['isRead'];
                          return InkWell(
                            onTap: () {
                              if (isUnread) {
                                setState(() {
                                  n['isRead'] = true;
                                  _notificationCount = (_notificationCount - 1).clamp(0, 99);
                                });
                                setModalState(() {});
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (n['color'] as Color).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      n['icon'] as IconData,
                                      color: n['color'] as Color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              n['title'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                                color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              n['time'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n['body'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: isUnread ? const Color(0xFF334155) : const Color(0xFF64748B),
                                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isUnread) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0057D9),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?['name'] ?? 'Retailer';
    final profileInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'R';

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2874F0)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF2874F0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: AppHeader(
                      appName: "ZONESUPPLY",
                      tagline: "Retail, Simplified",
                      userName: userName,
                      subtitleLabel: "${userName}'s Store",
                      subtitleIcon: Icons.store_outlined,
                      notificationCount: _notificationCount,
                      profileInitial: profileInitial,
                      isCompact: true,
                      isLight: true,
                      logoImagePath: 'assets/images/zonesupply_logo.png',
                      onNotificationTap: _showNotificationsBottomSheet,
                       onProfileTap: () {
                         if (widget.onProfileTap != null) {
                           widget.onProfileTap!();
                         } else {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => const ProfileScreen()),
                           );
                         }
                       },
                     ),
                   ),
                   // Search bar header
                   SliverToBoxAdapter(
                     child: Container(
                       color: const Color(0xFFF8FAFC),
                       padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                       child: Container(
                         height: 44,
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                         ),
                          child: TextField(
                            controller: _searchCtrl,
                            onSubmitted: (v) {
                              if (v.trim().isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubCategoryBrowseScreen(category: 'Grocery', initialSubCategory: v.trim()),
                                  ),
                                );
                              }
                            },
                           style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                           decoration: const InputDecoration(
                             hintText: 'Search for products, brands and more',
                             hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                             prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.symmetric(vertical: 11),
                           ),
                         ),
                       ),
                     ),
                   ),

                  // Horizontal category bar
                  SliverToBoxAdapter(
                    child: Container(
                      height: 124,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE2EDFD), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ALL CATEGORIES',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              separatorBuilder: (_, index) => const SizedBox(width: 24),
                              itemBuilder: (_, idx) {
                                final cat = _categories[idx];
                                return GestureDetector(
                                  onTap: () {
                                    final catName = cat['name'].toString().toLowerCase();
                                    if (catName == 'fashion') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const FashionCategoryScreen(),
                                        ),
                                      ).then((_) => _load());
                                      return;
                                    } else if (catName.contains('grocery') || catName.contains('rice') || catName.contains('atta') || catName.contains('oil') || catName.contains('beverage') || catName.contains('food') || catName.contains('dairy')) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const GroceryCategoryScreen(),
                                        ),
                                      ).then((_) => _load());
                                      return;
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryHubScreen(category: cat['name']),
                                        ),
                                      ).then((_) => _load());
                                      return;
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: cat['color'].withValues(alpha: 0.1),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(22),
                                          child: Image.network(
                                            cat['image'] ?? '',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                cat['icon'],
                                                color: cat['color'],
                                                size: 22,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cat['name'],
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sliding banner
                  SliverToBoxAdapter(
                    child: Container(
                      height: 160,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _banners.length,
                        onPageChanged: (idx) {
                          setState(() {
                            _currentBannerIndex = idx;
                          });
                        },
                        itemBuilder: (_, idx) {
                          final banner = _banners[idx];
                          final imgPath = banner['image'] as String;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: banner['color'],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                imgPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Dot Indicators
                  SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (idx) {
                        return Container(
                          width: _currentBannerIndex == idx ? 12 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: _currentBannerIndex == idx
                                ? const Color(0xFF2874F0)
                                : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Shop by Brands Section
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SHOP BY BRANDS',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Top FMCG & Consumer Brands Direct to Store',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _brands.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final brand = _brands[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BrandSubCategoryScreen(
                                        brandName: brand['name'] as String,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE4F0FD),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0071DC).withValues(alpha: 0.06),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(26),
                                          child: Image.network(
                                            brand['logo'] as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  (brand['name'] as String).substring(0, 1),
                                                  style: TextStyle(
                                                    color: brand['color'] as Color,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      brand['name'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. Wholesale Shops Horizontal Scroll
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wholesale Shops',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF212121),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Direct from verified wholesale suppliers',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF878787),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _wholesalers.isEmpty
                            ? Container(
                                height: 100,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'No wholesale shops in your area yet',
                                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 160,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _wholesalers.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                                  itemBuilder: (context, index) {
                                    final w = _wholesalers[index];
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
                                                color: Colors.black.withValues(alpha: 0.02),
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
                                                    backgroundColor: const Color(0xFF2874F0).withValues(alpha: 0.05),
                                                    backgroundImage: profilePic != null && profilePic.toString().isNotEmpty
                                                        ? NetworkImage(
                                                            profilePic.toString().startsWith('/')
                                                                ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$profilePic'
                                                                : profilePic.toString(),
                                                          )
                                                        : null,
                                                    child: profilePic == null || profilePic.toString().isEmpty
                                                        ? const Icon(Icons.storefront_rounded, color: Color(0xFF2874F0), size: 20)
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
                                                      color: _getCategoryColor(shopCat).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      shopCat.toUpperCase(),
                                                      style: GoogleFonts.inter(
                                                        color: _getCategoryColor(shopCat),
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
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 2. DEAL ZONE SECTION
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0071DC).withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_offer_rounded, color: Color(0xFF0071DC), size: 18),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text(
                                      'DEAL ZONE',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0071DC),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'JACKPOT & MARKET BEST DEALS',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.card_giftcard_rounded, color: Color(0xFF0071DC), size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDealCard(
                                  context,
                                  topLabel: 'HIDDEN',
                                  mainBanner: 'DEALS',
                                  bottomLabel: 'JACKPOT',
                                  icon: Icons.card_giftcard_rounded,
                                  dealType: 'Hidden Deals',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDealCard(
                                  context,
                                  topLabel: 'BEST',
                                  mainBanner: 'RATES',
                                  bottomLabel: 'IN MARKET',
                                  icon: Icons.local_offer_rounded,
                                  dealType: 'Best Rates',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDealCard(
                                  context,
                                  topLabel: 'BEST',
                                  mainBanner: 'SELLER',
                                  bottomLabel: 'IN YOUR ZONE',
                                  icon: Icons.verified_user_rounded,
                                  dealType: 'Best Seller',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDealCard(
                                  context,
                                  topLabel: 'DEALS ON',
                                  mainBanner: 'BULK',
                                  bottomLabel: 'PACKS',
                                  icon: Icons.inventory_2_rounded,
                                  dealType: 'Bulk Packs',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. MIN. DISCOUNT STORE SECTION (2x2 Grid)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5FF),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_offer_outlined, color: Color(0xFF0071DC), size: 18),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    Text(
                                      'MIN. DISCOUNT STORE',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0057D9),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'MORE ORDER • MORE DISCOUNT',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0071DC), size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDiscountTierCard(
                                  context,
                                  tierText: '20%-40%',
                                  filterType: '20%-40% OFF',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDiscountTierCard(
                                  context,
                                  tierText: '40%-60%',
                                  filterType: '40%-60% OFF',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDiscountTierCard(
                                  context,
                                  tierText: '60%-80%',
                                  filterType: '60%-80% OFF',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDiscountTierCard(
                                  context,
                                  tierText: '80% AND ABOVE',
                                  filterType: '80% OFF',
                                  isAbove: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. TRUST BADGES FOOTER BAR (Matching bottom of reference image)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTrustItem(Icons.workspace_premium_rounded, 'BEST QUALITY', 'Guaranteed'),
                          _buildTrustItem(Icons.verified_user_rounded, 'SAFE PAYMENT', '100% Secure'),
                          _buildTrustItem(Icons.local_shipping_rounded, 'FAST DELIVERY', 'On Time'),
                          _buildTrustItem(Icons.headset_mic_rounded, '24/7 SUPPORT', "We're Here"),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),

                ],
              ),
            ),
    );
  }

  Widget _buildDealCard(
    BuildContext context, {
    required String topLabel,
    required String mainBanner,
    required String bottomLabel,
    required IconData icon,
    required String dealType,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubCategoryBrowseScreen(
              category: 'Deal Zone',
              initialSubCategory: dealType,
            ),
          ),
        );
      },
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          color: const Color(0xFFEBF4FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0071DC).withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0071DC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Text(
                    topLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC700),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    mainBanner,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0057D9),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0071DC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Text(
                    bottomLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071DC).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF0071DC), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountTierCard(
    BuildContext context, {
    required String tierText,
    required String filterType,
    bool isAbove = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubCategoryBrowseScreen(
              category: 'Min. Discount Store',
              initialSubCategory: filterType,
            ),
          ),
        );
      },
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: Color(0xFF0071DC), size: 28),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071DC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'MINIMUM',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tierText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0057D9),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    isAbove ? 'AND ABOVE' : 'OFF',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: isAbove ? const Color(0xFF0057D9) : const Color(0xFF64748B),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

  Widget _buildTrustItem(IconData icon, String line1, String line2) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0071DC), size: 18),
        const SizedBox(height: 3),
        Text(
          line1,
          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
        ),
        Text(
          line2,
          style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }
}
