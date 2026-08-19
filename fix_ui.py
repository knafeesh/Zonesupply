import os
import re

workspace_dir = r'c:\Users\knafe\Zonesupply\retailer_app\lib\screens'
fashion_path = os.path.join(workspace_dir, 'fashion_category_screen.dart')
grocery_path = os.path.join(workspace_dir, 'grocery_category_screen.dart')
hub_path = os.path.join(workspace_dir, 'category_hub_screen.dart')

with open(fashion_path, 'r', encoding='utf-8') as f:
    fashion = f.read()

# Get helper methods from fashion (from `static double parseDouble` to right before `@override\n  Widget build`)
helpers_match = re.search(r'(  static double parseDouble.*?)(?=  @override\n  Widget build\(BuildContext context\))', fashion, re.DOTALL)
helpers = helpers_match.group(1) if helpers_match else ""
helpers = helpers.replace('_FashionCategoryScreenState', '_GroceryCategoryScreenState')
helpers = helpers.replace('_buildFashionCategoryTile', '_buildGroceryCategoryTile')
helpers = helpers.replace('Fashion', 'Grocery').replace('fashion', 'grocery')

# Get build method from fashion
build_match = re.search(r'  @override\n  Widget build\(BuildContext context\) \{.*?\n  \}\n\}', fashion, re.DOTALL)
build_method = build_match.group(0)

# Adapt build method for grocery
grocery_build = build_method \
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
    .replace('Icons.checkroom_outlined', 'Icons.local_grocery_store_outlined') \
    .replace('final forYou = _forYouProducts;\n    final recommended = _recommendedProducts;\n', '')

# Remove FOR YOU and RECOMMENDED UI blocks from grocery_build
# The fashion build might have them commented or not. I'll just regex remove them if they exist.
# They start with `// 5. FOR YOU` and `// 6. RECOMMENDED`
grocery_build = re.sub(r'                  // 5\. FOR YOU.*?                  // 7\. ALL GROCERY PRODUCTS GRID HEADER', '                  // 7. ALL GROCERY PRODUCTS GRID HEADER', grocery_build, flags=re.DOTALL)

# Get the _FashionProductCard class from fashion
card_match = re.search(r'class _FashionProductCard extends StatefulWidget \{.*', fashion, re.DOTALL)
card_class = card_match.group(0)
card_class = card_class.replace('_FashionProductCard', '_GroceryProductCard')
card_class = card_class.replace('_FashionCategoryScreenState', '_GroceryCategoryScreenState')
card_class = card_class.replace('Color(0xFF6C3BD5)', 'Color(0xFF16A34A)')
card_class = card_class.replace('Icons.checkroom_outlined', 'Icons.local_grocery_store_outlined')

# Read original grocery top part
with open(grocery_path, 'r', encoding='utf-8') as f:
    grocery = f.read()

# Extract from start up to the first `  @override\n  Widget build`
top_match = re.search(r'(.*?)(?=  @override\n  Widget build\(BuildContext context\))', grocery, re.DOTALL)
grocery_top = top_match.group(1) if top_match else grocery

# Reconstruct grocery
new_grocery = grocery_top + helpers + '\n' + grocery_build + '\n\n' + card_class

with open(grocery_path, 'w', encoding='utf-8') as f:
    f.write(new_grocery)

# Now fix category_hub_screen.dart
# The top part of category hub is valid. We need its build method.
hub_build = build_method \
    .replace('final fashionShops = _fashionWholesalers;', "final wholesalers = _filteredWholesalers;\n    final cfg = _getHubConfig();\n    final primaryColor = cfg['primaryColor'] as Color;\n    final List<Map<String, dynamic>> row1 = cfg['row1'] as List<Map<String, dynamic>>;\n    final List<Map<String, dynamic>> row2 = cfg['row2'] as List<Map<String, dynamic>>; ") \
    .replace('fashionShops', 'wholesalers') \
    .replace('const Color(0xFF6C3BD5)', 'primaryColor') \
    .replace('Color(0xFF6C3BD5)', 'primaryColor') \
    .replace("const Icon(Icons.checkroom_rounded, color: primaryColor, size: 20)", "Icon(cfg['icon'] as IconData, color: primaryColor, size: 20)") \
    .replace("'Fashion Hub'", "cfg['title'] as String") \
    .replace("'Search fashion wear, sarees, kurtis, brands...'", "cfg['searchHint'] as String") \
    .replace("'FASHION CATEGORIES'", "'POPULAR DEPARTMENTS'") \
    .replace('_fashionRow1', 'row1') \
    .replace('_fashionRow2', 'row2') \
    .replace('_buildFashionCategoryTile', '_buildCategoryTile') \
    .replace('_buildCategoryTile(topItem)', '_buildCategoryTile(topItem, primaryColor)') \
    .replace('_buildCategoryTile(bottomItem)', '_buildCategoryTile(bottomItem, primaryColor)') \
    .replace("'Fashion Wholesale Shops'", "'VERIFIED WHOLESALE DISTRIBUTORS'") \
    .replace('Icons.checkroom_rounded', "cfg['icon'] as IconData") \
    .replace('final forYou = _forYouProducts;\n    final recommended = _recommendedProducts;\n', '') \
    .replace('final catalog = _filteredProducts;\n', '')

hub_build = re.sub(r'                  // 5\. FOR YOU.*?                  // 7\. ALL FASHION PRODUCTS GRID HEADER', '                  // 7. ALL FASHION PRODUCTS GRID HEADER', hub_build, flags=re.DOTALL)
hub_build = re.sub(r'                  // 7\. ALL FASHION PRODUCTS GRID HEADER.*', '                  const SliverToBoxAdapter(child: SizedBox(height: 40)),\n                ],\n              ),\n            ),\n    );\n  }\n}', hub_build, flags=re.DOTALL)

with open(hub_path, 'r', encoding='utf-8') as f:
    hub = f.read()

# Extract from start up to the first `  @override\n  Widget build`
hub_top_match = re.search(r'(.*?)(?=  @override\n  Widget build\(BuildContext context\))', hub, re.DOTALL)
hub_top = hub_top_match.group(1) if hub_top_match else hub

# We also need the helper _buildCategoryTile in hub if it's not there, but it is in the top?
# Actually, I need to check if _buildCategoryTile exists in hub_top.
if '_buildCategoryTile' not in hub_top:
    # Just copy it from helpers and change primaryColor
    hub_helpers = helpers_match.group(1) if helpers_match else ""
    # We only need the tile builder
    tile_match = re.search(r'  Widget _buildFashionCategoryTile\(Map<String, dynamic> item\) \{.*?  \}', hub_helpers, re.DOTALL)
    if tile_match:
        tile = tile_match.group(0).replace('_buildFashionCategoryTile', '_buildCategoryTile').replace('item)', 'item, Color primaryColor)').replace('const Color(0xFF6C3BD5)', 'primaryColor')
        hub_top += tile + '\n\n'

new_hub = hub_top + hub_build

with open(hub_path, 'w', encoding='utf-8') as f:
    f.write(new_hub)

print("Fix completed")
