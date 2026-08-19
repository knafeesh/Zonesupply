import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'browse_screen.dart';
import 'category_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  late final List<Widget> _pages;
  final browseKey = GlobalKey<BrowseScreenState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      BrowseScreen(
        key: browseKey,
        onProfileTap: () => setState(() => _idx = 3),
      ),
      CategoryScreen(
        onCategorySelected: (categoryName) {
          setState(() {
            _idx = 0; // Switch to Browse tab
          });
          browseKey.currentState?.selectCategory(categoryName);
        },
      ),
      const CartScreen(isTab: true),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2874F0).withValues(alpha: 0.1),
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.store_outlined, color: Color(0xFF878787)),
            selectedIcon: Icon(Icons.store_rounded, color: Color(0xFF2874F0)),
            label: 'Browse',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: Color(0xFF878787)),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF2874F0)),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: cart.itemCount > 0
                ? Badge(
                    label: Text('${cart.itemCount}'),
                    child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF878787)),
                  )
                : const Icon(Icons.shopping_cart_outlined, color: Color(0xFF878787)),
            selectedIcon: cart.itemCount > 0
                ? Badge(
                    label: Text('${cart.itemCount}'),
                    child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF2874F0)),
                  )
                : const Icon(Icons.shopping_cart_rounded, color: Color(0xFF2874F0)),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFF878787)),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF2874F0)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
