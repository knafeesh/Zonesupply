import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class WholesalerShopScreen extends StatefulWidget {
  final Map<String, dynamic> wholesaler;

  const WholesalerShopScreen({super.key, required this.wholesaler});

  @override
  State<WholesalerShopScreen> createState() => _WholesalerShopScreenState();
}

class _WholesalerShopScreenState extends State<WholesalerShopScreen> {
  List _products = [];
  bool _loading = true;
  bool _isFav = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final wId = widget.wholesaler['id'].toString();
      final pData = await ApiService.get('/products/wholesaler/$wId') as List? ?? [];
      final favsData = await ApiService.get('/wholesalers/favorites/my') as List? ?? [];
      
      final favIds = favsData.map((w) => w['id'].toString()).toSet();
      
      setState(() {
        _products = pData;
        _isFav = favIds.contains(wId);
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading shop data: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final wId = widget.wholesaler['id'].toString();
    try {
      final res = await ApiService.post('/wholesalers/$wId/favorite', {});
      final favorited = res['favorited'] as bool;
      setState(() {
        _isFav = favorited;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            favorited ? 'Shop added to favorites!' : 'Shop removed from favorites',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: favorited ? const Color(0xFF8E44AD) : Colors.black87,
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  String? _selectedCategory; // null = 'All'

  List<String> get _shopCategories {
    final cats = <String>{};
    for (var p in _products) {
      final c = p['category']?.toString().trim();
      if (c != null && c.isNotEmpty) {
        cats.add(c);
      }
    }
    return cats.toList()..sort();
  }

  List get _filteredProducts {
    return _products.where((p) {
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        final cat = p['category']?.toString() ?? '';
        if (cat != _selectedCategory && !cat.startsWith('$_selectedCategory > ')) {
          return false;
        }
      }
      if (_search.isNotEmpty) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final cat = (p['category'] as String? ?? '').toLowerCase();
        final sku = (p['barcode'] as String? ?? p['sku'] as String? ?? '').toLowerCase();
        final q = _search.toLowerCase();
        if (!name.contains(q) && !cat.contains(q) && !sku.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final w = widget.wholesaler;
    final user = w['user'] ?? {};
    final shopPhoto = user['profilePicture'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          w['businessName'] ?? 'Wholesale Shop',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFav ? const Color(0xFF8E44AD) : Colors.white70,
            ),
            tooltip: 'Favorite Shop',
            onPressed: _toggleFavorite,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2874F0)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2874F0),
              child: CustomScrollView(
                slivers: [
                // Shop details header
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop cover picture
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: const Color(0xFF2874F0).withValues(alpha: 0.05),
                          child: shopPhoto != null && shopPhoto.toString().isNotEmpty
                              ? Image.network(
                                  shopPhoto.toString().startsWith('/')
                                      ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$shopPhoto'
                                      : shopPhoto.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.storefront_rounded, color: Color(0xFF2874F0), size: 64),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.storefront_rounded, color: Color(0xFF2874F0), size: 64),
                                ),
                        ),
                        // Shop Profile Card
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w['businessName'] ?? 'Wholesale Supplier',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF212121),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if (w['shopNumber'] != null && w['shopNumber'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Shop Number: ${w['shopNumber']}',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF2874F0),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFav
                                          ? const Color(0xFF8E44AD).withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      foregroundColor: _isFav ? const Color(0xFF8E44AD) : Colors.grey.shade700,
                                      elevation: 0,
                                      side: BorderSide(
                                        color: _isFav ? const Color(0xFF8E44AD) : Colors.grey.shade300,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    onPressed: _toggleFavorite,
                                    icon: Icon(
                                      _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _isFav ? 'FAVORITED' : 'FAVORITE',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              // Location and address
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Color(0xFF878787), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      w['address'] ?? 'No address provided',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF212121),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Contact Person Info
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, color: Color(0xFF878787), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Owner: ${user['name'] ?? 'Supplier'}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF878787),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Contact Phone Info
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, color: Color(0xFF878787), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Contact: ${user['phone'] ?? 'N/A'}',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF878787),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (w['gstNumber'] != null && w['gstNumber'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined, color: Color(0xFF388E3C), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'GST: ${w['gstNumber']}',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF388E3C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Search bar within shop
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(color: Color(0xFF212121), fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search within this shop',
                        hintStyle: TextStyle(color: Color(0xFF878787), fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF878787), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
                // Category filter tabs within shop
                if (_shopCategories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 38,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ChoiceChip(
                            label: Text('All Products (${_products.length})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                            selected: _selectedCategory == null,
                            selectedColor: const Color(0xFF2874F0),
                            labelStyle: TextStyle(color: _selectedCategory == null ? Colors.white : const Color(0xFF212121)),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _selectedCategory == null ? const Color(0xFF2874F0) : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (_) => setState(() => _selectedCategory = null),
                          ),
                          const SizedBox(width: 8),
                          ..._shopCategories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            final count = _products.where((p) => (p['category']?.toString() ?? '') == cat).length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$cat ($count)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                                selected: isSelected,
                                selectedColor: const Color(0xFF2874F0),
                                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF212121)),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: isSelected ? const Color(0xFF2874F0) : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (_) => setState(() => _selectedCategory = isSelected ? null : cat),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                // Products grid list
                _filteredProducts.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                _selectedCategory != null
                                    ? 'No products under "$_selectedCategory"'
                                    : 'No products matching search',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final p = _filteredProducts[idx];
                              final inCart = cart.items.any((ci) => ci.productId == p['id']);
                              return _ProductCard(
                                product: p,
                                inCart: inCart,
                                onAdd: () {
                                  if (!inCart) {
                                    cart.addItem(p);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added to cart!',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                                onTap: () {
                                  final pWithW = Map<String, dynamic>.from(p)..['wholesaler'] = widget.wholesaler;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(product: pWithW),
                                    ),
                                  ).then((_) => _loadData());
                                },
                              );
                            },
                            childCount: _filteredProducts.length,
                          ),
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool inCart;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.inCart,
    required this.onAdd,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isWishlisted = false;

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
            // 1. PRODUCT IMAGE + BADGES
            SizedBox(
              height: 120,
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
                                p['imageUrl'].toString().startsWith('/')
                                    ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}${p['imageUrl']}'
                                    : p['imageUrl'].toString(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 40),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 40),
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
                  // Wishlist Toggle
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

            // 2. ALL PRODUCT DETAILS
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
                        // Brand & Category
                        Row(
                          children: [
                            Expanded(
                              child: Text(
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
                            ),
                            if (p['category'] != null && p['category'].toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2874F0).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  p['category'].toString(),
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF2874F0),
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
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

                        // Selling Price + MRP (cut price)
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

                        // Best Price
                        Text(
                          'Best Price: ₹${bestPrice.toStringAsFixed(0)}/unit',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF16A34A),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // MOQ
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
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.inCart ? const Color(0xFF388E3C) : const Color(0xFF0057D9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: widget.onAdd,
                        child: Text(
                          widget.inCart ? 'GO TO CART' : 'ADD TO CART',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
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

