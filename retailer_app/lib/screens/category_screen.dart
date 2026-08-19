import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:core/widgets/app_header.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'subcategory_grid_screen.dart';
import 'fashion_category_screen.dart';
import 'grocery_category_screen.dart';
import 'category_hub_screen.dart';

class CategoryScreen extends StatefulWidget {
  final ValueChanged<String> onCategorySelected;

  const CategoryScreen({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchText = '';

  // Categories matching reference design with high quality images
  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Grocery',
      'image': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Home Care',
      'image': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Personal Care',
      'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Fashion',
      'image': 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Luggage & Apparel',
      'image': 'https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Restaurant Supplies & Houseware',
      'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Health & OTC',
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Kitchen & Home Appliances',
      'image': 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Beverages',
      'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Rice, Atta & Dals',
      'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Packaged Foods & Dry Fruits',
      'image': 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Oil, Sugar & Masalas',
      'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Dairy, Fresh & Frozen',
      'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'IT, Stationery & Office Furniture',
      'image': 'https://images.unsplash.com/photo-1585776245991-cf89dd7fc73a?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Electronics',
      'image': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Hardware',
      'image': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&auto=format&fit=crop&q=80',
    },
    {
      'name': 'Sports',
      'image': 'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff?w=400&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchText.isEmpty) return _categories;
    return _categories
        .where((cat) =>
            (cat['name'] as String).toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
  }

  void _handleCategoryTap(String categoryName) {
    final catLower = categoryName.toLowerCase();
    if (catLower == 'fashion') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FashionCategoryScreen(),
        ),
      );
      return;
    } else if (catLower.contains('grocery') || catLower.contains('rice') || catLower.contains('atta') || catLower.contains('oil') || catLower.contains('beverage') || catLower.contains('food') || catLower.contains('dairy')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GroceryCategoryScreen(),
        ),
      );
      return;
    } else {
      // Route all other major departments (Home Care, Personal Care, Luggage & Apparel, Restaurant, Health, Appliances, IT, Electronics, Hardware, Sports) to CategoryHubScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryHubScreen(category: categoryName),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?['name'] ?? 'Retailer';
    final profileInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'R';

    final filtered = _filteredCategories;
    final List<List<Map<String, dynamic>>> rows = [];
    for (int i = 0; i < filtered.length; i += 2) {
      if (i + 1 < filtered.length) {
        rows.add([filtered[i], filtered[i + 1]]);
      } else {
        rows.add([filtered[i]]);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. App Header (matching BrowseScreen header UI)
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
              logoImagePath: 'assets/images/zonesupply_logo.png',
              onNotificationTap: () {},
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ),

          // 2. Search bar header (matching BrowseScreen search bar)
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
                  onChanged: (val) => setState(() => _searchText = val),
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
          ),

          // 3. Section Title Bar (matching BrowseScreen banner styling)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                    'ALL CATEGORIES',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} Departments',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Category Grid as a table with dividers
          SliverToBoxAdapter(
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No categories match your search.')),
                  )
                : Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                        ...List.generate(rows.length, (rowIndex) {
                          final row = rows[rowIndex];
                          return Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Left cell
                                    Expanded(
                                      child: _CategoryCell(
                                        category: row[0],
                                        onTap: () => _handleCategoryTap(row[0]['name'] as String),
                                      ),
                                    ),
                                    // Vertical divider
                                    Container(width: 1, color: const Color(0xFFEEEEEE)),
                                    // Right cell (or empty)
                                    Expanded(
                                      child: row.length > 1
                                          ? _CategoryCell(
                                              category: row[1],
                                              onTap: () => _handleCategoryTap(row[1]['name'] as String),
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                            ],
                          );
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const _CategoryCell({required this.category, required this.onTap});

  bool get _isNetwork => (category['image'] as String).startsWith('http');

  @override
  Widget build(BuildContext context) {
    final imageUrl = category['image'] as String;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image — large, centered
            SizedBox(
              height: 130,
              width: double.infinity,
              child: _isNetwork
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.category_rounded, size: 54, color: Color(0xFF2874F0)),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: Icon(Icons.category_rounded, size: 54, color: Color(0xFF2874F0)),
                        );
                      },
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.category_rounded, size: 54, color: Color(0xFF2874F0)),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Category name
            Text(
              category['name'] as String,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
