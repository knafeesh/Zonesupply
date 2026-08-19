import os
import re

workspace_dir = r'c:\Users\knafe\Zonesupply\retailer_app\lib\screens'
fashion_path = os.path.join(workspace_dir, 'fashion_category_screen.dart')
grocery_path = os.path.join(workspace_dir, 'grocery_category_screen.dart')
hub_path = os.path.join(workspace_dir, 'category_hub_screen.dart')

with open(fashion_path, 'r', encoding='utf-8') as f:
    fashion = f.read()

# Extract the build method from fashion
build_match = re.search(r'  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\}', fashion, re.DOTALL)
if not build_match:
    print("Could not find build method in fashion")
    exit(1)

fashion_build = build_match.group(0)

# Also extract the _FashionProductCard class
card_match = re.search(r'class _FashionProductCard extends StatefulWidget \{.*?\}', fashion, re.DOTALL)
if not card_match:
    print("Could not find _FashionProductCard")
    exit(1)
fashion_card = card_match.group(0)

# Now, we need to adapt fashion_build for grocery
# In fashion:
# final fashionShops = _fashionWholesalers;
# final forYou = _forYouProducts;
# final recommended = _recommendedProducts;
# final catalog = _filteredProducts;
#
# color: const Color(0xFF6C3BD5) -> color: const Color(0xFF16A34A)
# 'Fashion Hub' -> 'GROCERY HUB'
# Icons.checkroom_rounded -> Icons.local_grocery_store_rounded
# 'Search fashion wear, sarees, kurtis, brands...' -> 'Search atta, rice, oil, spices, drinks...'
# 'FASHION CATEGORIES' -> 'GROCERY CATEGORIES'
# _fashionRow1 -> _groceryRow1
# _fashionRow2 -> _groceryRow2
# _buildFashionCategoryTile -> _buildGroceryCategoryTile
# 'Fashion Wholesale Shops' -> 'Wholesale Grocery Shops & Mills'
# fashionShops -> wholesalers
# 'ALL FASHION PRODUCTS' -> 'ALL GROCERY PRODUCTS'
# _FashionProductCard -> _GroceryProductCard
# const Color(0xFF0F172A) -> keep
# 'No fashion products found' -> 'No grocery products found'

grocery_build = fashion_build \
    .replace('final fashionShops = _fashionWholesalers;', 'final wholesalers = _groceryWholesalers;') \
    .replace('fashionShops', 'wholesalers') \
    .replace('Color(0xFF6C3BD5)', 'Color(0xFF16A34A)') \
    .replace('Fashion Hub', 'GROCERY HUB') \
    .replace('Icons.checkroom_rounded', 'Icons.local_grocery_store_rounded') \
    .replace('Search fashion wear, sarees, kurtis, brands...', 'Search atta, rice, oil, spices, drinks...') \
    .replace('FASHION CATEGORIES', 'GROCERY DEPARTMENTS') \
    .replace('_fashionRow1', '_groceryRow1') \
    .replace('_fashionRow2', '_groceryRow2') \
    .replace('_buildFashionCategoryTile', '_buildGroceryCategoryTile') \
    .replace('Fashion Wholesale Shops', 'Wholesale Grocery Shops & Mills') \
    .replace('ALL FASHION PRODUCTS', 'ALL GROCERY PRODUCTS') \
    .replace('_FashionProductCard', '_GroceryProductCard') \
    .replace('No fashion products found', 'No grocery products found') \
    .replace('Icons.checkroom_outlined', 'Icons.local_grocery_store_outlined')

# Also modify _GroceryProductCard
grocery_card = fashion_card \
    .replace('_FashionProductCard', '_GroceryProductCard') \
    .replace('Color(0xFF6C3BD5)', 'Color(0xFF16A34A)') \
    .replace('Icons.checkroom_outlined', 'Icons.local_grocery_store_outlined')

with open(grocery_path, 'r', encoding='utf-8') as f:
    grocery = f.read()

# Remove For You and Recommended from Grocery
grocery = grocery.replace('final forYou = catalog.take(8).toList();\n    final recommended = catalog.skip(2).take(8).toList();', '')

# Replace build in grocery
grocery = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\}', grocery_build, grocery, flags=re.DOTALL)

# Find if _GroceryProductCard already exists, if not append, else replace
if 'class _GroceryProductCard extends StatefulWidget' in grocery:
    grocery = re.sub(r'class _GroceryProductCard extends StatefulWidget \{.*?\}', grocery_card, grocery, flags=re.DOTALL)
else:
    grocery += '\n\n' + grocery_card

with open(grocery_path, 'w', encoding='utf-8') as f:
    f.write(grocery)

# Now adapt for category hub
# 'Fashion Hub' -> cfg['title'] as String
# Icon -> Icon(cfg['icon'] as IconData
# Color(0xFF6C3BD5) -> primaryColor
# etc.
hub_build = fashion_build \
    .replace('final fashionShops = _fashionWholesalers;', "final wholesalers = _filteredWholesalers;\n    final cfg = _getHubConfig();\n    final primaryColor = cfg['primaryColor'] as Color;\n    final List<Map<String, dynamic>> row1 = cfg['row1'] as List<Map<String, dynamic>>;\n    final List<Map<String, dynamic>> row2 = cfg['row2'] as List<Map<String, dynamic>>; ") \
    .replace('final forYou = _forYouProducts;', '') \
    .replace('final recommended = _recommendedProducts;', '') \
    .replace('final catalog = _filteredProducts;', '') \
    .replace('fashionShops', 'wholesalers') \
    .replace('const Color(0xFF6C3BD5)', 'primaryColor') \
    .replace("const Icon(Icons.checkroom_rounded, color: Color(0xFF6C3BD5), size: 20)", "Icon(cfg['icon'] as IconData, color: primaryColor, size: 20)") \
    .replace("'Fashion Hub'", "cfg['title'] as String") \
    .replace("'Search fashion wear, sarees, kurtis, brands...'", "cfg['searchHint'] as String") \
    .replace("'FASHION CATEGORIES'", "'POPULAR DEPARTMENTS'") \
    .replace('_fashionRow1', 'row1') \
    .replace('_fashionRow2', 'row2') \
    .replace('_buildFashionCategoryTile(topItem)', '_buildCategoryTile(topItem, primaryColor)') \
    .replace('_buildFashionCategoryTile(bottomItem)', '_buildCategoryTile(bottomItem, primaryColor)') \
    .replace("'Fashion Wholesale Shops'", "'VERIFIED WHOLESALE DISTRIBUTORS'") \
    .replace('Icons.checkroom_rounded', "cfg['icon'] as IconData")

# Remove product grid from hub_build since category hub doesn't have it (no catalog)
hub_build = re.sub(r'                  // 7\. ALL FASHION PRODUCTS GRID HEADER.*', '                  const SliverToBoxAdapter(child: SizedBox(height: 40)),\n                ],\n              ),\n            ),\n    );\n  }\n}', hub_build, flags=re.DOTALL)

with open(hub_path, 'r', encoding='utf-8') as f:
    hub = f.read()

hub = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\}', hub_build, hub, flags=re.DOTALL)

with open(hub_path, 'w', encoding='utf-8') as f:
    f.write(hub)

print("Done updating UI")
