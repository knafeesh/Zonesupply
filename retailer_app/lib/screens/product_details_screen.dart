import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'wholesaler_shop_screen.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Set<String> _favoritedIds = {};
  int _activeImgIdx = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadFavorites();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favsData = await ApiService.get('/wholesalers/favorites/my') as List? ?? [];
      if (mounted) {
        setState(() {
          _favoritedIds = favsData.map((w) => w['id'].toString()).toSet();
        });
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
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
              favorited ? 'Added wholesaler to favorites' : 'Removed wholesaler from favorites',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: favorited ? const Color(0xFF8E44AD) : Colors.black87,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  void _openFullScreenViewer(List<String> images, int startIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(
              images: images,
              initialIndex: startIndex,
              tag: 'product_image_$startIndex',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final p = widget.product;
    final inCart = cart.items.any((ci) => ci.productId == p['id']);

    final colors = [
      const Color(0xFF2874F0),
      const Color(0xFFFF9F00),
      const Color(0xFF388E3C),
      const Color(0xFFE056FD),
    ];
    final color = colors[p['name'].toString().length % colors.length];
    final double rating = 3.8 + (p['name'].toString().length % 13) / 10.0;
    final double discount = double.tryParse(p['discount']?.toString() ?? '0') ?? 0;
    final wholesalerId = p['wholesalerId']?.toString() ?? p['wholesaler']?['id']?.toString();
    final wholesalerName = p['wholesaler']?['businessName'] ?? p['wholesaler']?['user']?['name'] ?? 'Wholesale Supplier';

    List<String> imagesList = [];

    void addImage(String url) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && !imagesList.contains(trimmed)) {
        imagesList.add(trimmed);
      }
    }

    if (p['images'] != null) {
      if (p['images'] is List) {
        for (final item in p['images']) {
          if (item != null) {
            final str = item.toString();
            if (str.contains(',')) {
              str.split(',').forEach(addImage);
            } else {
              addImage(str);
            }
          }
        }
      } else if (p['images'] is String) {
        (p['images'] as String).split(',').forEach(addImage);
      }
    }

    if (p['imageUrl'] != null) {
      final mainImg = p['imageUrl'].toString().trim();
      if (mainImg.isNotEmpty) {
        if (imagesList.contains(mainImg)) {
          imagesList.remove(mainImg);
        }
        imagesList.insert(0, mainImg);
      }
    }

    // Resolve full URLs
    final resolvedImages = imagesList.map((url) =>
      url.startsWith('/') ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$url' : url
    ).toList();

    final originalPrice = double.tryParse(p['pricePerUnit']?.toString() ?? '0') ?? 0;
    final discountedPrice = discount > 0 ? originalPrice * (1 - discount / 100) : originalPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Collapsing SliverAppBar with Flipkart-style image carousel
          SliverAppBar(
            expandedHeight: 360.0,
            pinned: true,
            elevation: 0.5,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (imagesList.length > 1)
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_activeImgIdx + 1}/${imagesList.length}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // White background for product images (Flipkart style)
                  Container(color: Colors.white),

                  // Main image PageView carousel
                  resolvedImages.isEmpty
                      ? Center(
                          child: Icon(Icons.inventory_2_outlined,
                              color: color.withAlpha(120), size: 100),
                        )
                      : GestureDetector(
                          onTap: () => _openFullScreenViewer(resolvedImages, _activeImgIdx),
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: resolvedImages.length,
                            onPageChanged: (idx) {
                              setState(() => _activeImgIdx = idx);
                            },
                            itemBuilder: (context, idx) {
                              return Hero(
                                tag: 'product_image_$idx',
                                child: Image.network(
                                  resolvedImages[idx],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(Icons.inventory_2_outlined,
                                        color: color.withAlpha(120), size: 100),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                  // Tap to zoom hint overlay (top right)
                  if (resolvedImages.isNotEmpty)
                    Positioned(
                      top: 60,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _openFullScreenViewer(resolvedImages, _activeImgIdx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.zoom_out_map_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),

                  // Dot indicators (Flipkart style - bottom center)
                  if (resolvedImages.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(resolvedImages.length, (idx) {
                          final isSelected = _activeImgIdx == idx;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(idx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: isSelected ? 20 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isSelected
                                    ? const Color(0xFF2874F0)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Thumbnail strip at bottom (when multiple images)
                  if (resolvedImages.length > 1)
                    Positioned(
                      bottom: 28,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: resolvedImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final isActive = _activeImgIdx == idx;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(idx,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? const Color(0xFF2874F0)
                                        : Colors.grey.shade300,
                                    width: isActive ? 2.5 : 1,
                                  ),
                                  color: Colors.white,
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2874F0).withAlpha(60),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    resolvedImages[idx],
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.inventory_2_outlined,
                                      color: color.withAlpha(120),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Scrollable product details body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag and Wholesaler Owner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (p['category'] as String? ?? 'General').toUpperCase(),
                          style: GoogleFonts.inter(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (p['wholesaler'] != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WholesalerShopScreen(wholesaler: p['wholesaler']),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF2874F0), width: 1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.storefront, color: Color(0xFF2874F0), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Visit Shop',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF2874F0),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product Title
                  Text(
                    p['name'] ?? '',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF212121),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Unit details
                  Text(
                    'Per ${p['unit'] ?? 'unit'}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF878787),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rating and Discount row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C).withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${discount.toStringAsFixed(0)}% OFF WHOLESALE',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF388E3C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Flipkart-style Price Block ──
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${discountedPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (discount > 0) ...[
                              const SizedBox(width: 10),
                              Text(
                                '₹${originalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF878787),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${discount.toStringAsFixed(0)}% off',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF388E3C),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inclusive of all taxes',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF878787),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF388E3C).withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF388E3C).withAlpha(40)),
                            ),
                            child: Text(
                              'You save ₹${(originalPrice - discountedPrice).toStringAsFixed(0)} on this order',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF388E3C),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 18),

                  // Wholesaler Supplier Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF2874F0).withAlpha(10),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF2874F0), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wholesalerName,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF212121),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified wholesale supplier in your zone',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF878787),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // Product Description
                  Text(
                    'Product Description',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF212121),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['description'] != null && p['description'].toString().trim().isNotEmpty
                        ? p['description']
                        : 'No description provided by the wholesaler. This premium quality product is sourced from verified distributors.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF212121),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),

                  // Product Specifications Table
                  if (p['specifications'] != null && (p['specifications'] as Map).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Specifications',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF212121),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(2.0),
                        },
                        children: (p['specifications'] as Map<String, dynamic>).entries.map((entry) {
                          final key = entry.key;
                          final val = entry.value?.toString() ?? '';
                          if (val.trim().isEmpty) return const TableRow(children: [SizedBox.shrink(), SizedBox.shrink()]);

                          final formattedKey = key
                              .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
                              .trim()
                              .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase());

                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  formattedKey,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF878787),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  val,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF212121),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).where((row) => row.children.first is! SizedBox).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 110), // padding for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Flipkart-style Bottom Action Bar ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin top divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Favorite row (wholesaler heart)
            if (wholesalerId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleFavorite(wholesalerId),
                      child: Row(
                        children: [
                          Icon(
                            _favoritedIds.contains(wholesalerId)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _favoritedIds.contains(wholesalerId)
                                ? Colors.red
                                : Colors.grey.shade500,
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _favoritedIds.contains(wholesalerId)
                                ? 'Wishlisted'
                                : 'Wishlist',
                            style: GoogleFonts.inter(
                              color: _favoritedIds.contains(wholesalerId)
                                  ? Colors.red
                                  : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Two full-width buttons ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                  0, wholesalerId != null ? 8 : 0, 0,
                  MediaQuery.of(context).padding.bottom + 0),
              child: Row(
                children: [
                  // ADD TO CART (yellow like Flipkart)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!inCart) {
                          cart.addItem(p);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to cart!',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: const Color(0xFF388E3C),
                              duration: const Duration(seconds: 3),
                              action: SnackBarAction(
                                label: 'GO TO CART',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CartScreen(isTab: false),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(isTab: false),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 54,
                        color: inCart
                            ? const Color(0xFF21A179)
                            : const Color(0xFFFFAC0E),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  inCart
                                      ? Icons.shopping_cart_checkout_rounded
                                      : Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  inCart ? 'GO TO CART' : 'ADD TO CART',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // BUY NOW at ₹price (orange like Flipkart)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Add to cart and show checkout confirmation
                        if (!inCart) cart.addItem(p);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(isTab: false),
                          ),
                        );
                      },
                      child: Container(
                        height: 54,
                        color: const Color(0xFFFF6161),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.flash_on_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'BUY NOW',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'at ₹${discountedPrice.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: Colors.white.withAlpha(220),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

// ──────────────────────────────────────────────────────────────────────────────
// Flipkart-style Full Screen Image Viewer
// ──────────────────────────────────────────────────────────────────────────────
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String tag;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.tag,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late int _currentIndex;
  late PageController _pageController;
  late ScrollController _thumbController;
  final double _thumbWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbController = ScrollController(
      initialScrollOffset: _thumbScrollOffset(widget.initialIndex),
    );
    // Force immersive mode - hide status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbController.dispose();
    // Restore normal UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  double _thumbScrollOffset(int index) {
    return (index * (_thumbWidth + 10)).clamp(0.0, double.infinity);
  }

  void _scrollThumbsTo(int index) {
    if (_thumbController.hasClients) {
      _thumbController.animateTo(
        _thumbScrollOffset(index),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Main swipeable image view ──
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (idx) {
              setState(() => _currentIndex = idx);
              _scrollThumbsTo(idx);
            },
            itemBuilder: (context, idx) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Hero(
                    tag: 'product_image_$idx',
                    child: Image.network(
                      widget.images[idx],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white54,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.white30, size: 80),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Top bar: back button + counter ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Left / Right arrow navigation ──
          if (_currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),

          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),

          // ── Bottom: dot indicators + thumbnail strip ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  if (widget.images.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.images.length, (idx) {
                        final isSelected = _currentIndex == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 20 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isSelected ? Colors.white : Colors.white38,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Thumbnail strip
                  if (widget.images.length > 1)
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        controller: _thumbController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final isActive = _currentIndex == idx;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(idx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _thumbWidth,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white30,
                                  width: isActive ? 2.5 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withAlpha(60),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  widget.images[idx],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        color: Colors.white30, size: 22),
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
