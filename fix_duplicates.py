import os
import re

workspace_dir = r'c:\Users\knafe\Zonesupply\retailer_app\lib\screens'
grocery_path = os.path.join(workspace_dir, 'grocery_category_screen.dart')

with open(grocery_path, 'r', encoding='utf-8') as f:
    text = f.read()

# The helpers start with `  static double parseDouble`
# We know the first one is the original, the second one is the injected one.
# But wait, there are other duplicate errors: _getWholesalerCategory, _getDynamicOfferBanners, _hexToColor, _buildGroceryCategoryTile, _filteredProducts, _groceryWholesalers
# Actually, if I just take `grocery_top` which ends right before the first `  @override\n  Widget build(BuildContext context)` in the ORIGINAL file.
# Since my `fix_ui.py` did: `top_match = re.search(r'(.*?)(?=  @override\n  Widget build\(BuildContext context\))', grocery, re.DOTALL)`
# Wait! In `fix_ui.py`, `grocery` already had its `build` method ruined by `sync_ui.py`!
# Ah! `sync_ui.py` replaced from the FIRST `build` to the END OF FILE.
# Which means the original helper methods, if they were below `build`, were DELETED.
# If they were ABOVE `build`, they SURVIVED.
# Let's check where `parseDouble` is. 
# It turns out they were ALL ABOVE `build`!
# So `grocery_top` (everything before `build`) CONTAINS all the helper methods!
# BUT wait! My `sync_ui.py` also injected `grocery_build` AND `_GroceryProductCard`. And maybe `_GroceryProductCard` had `build` methods.
# My `fix_ui.py` grabbed `grocery_top` by searching up to the FIRST `build`, which means it successfully extracted everything BEFORE the `build` of `_GroceryCategoryScreenState`.
# So `grocery_top` is exactly the intact top part of the file, WHICH ALREADY HAS ALL THE HELPERS!
# Then `fix_ui.py` added `helpers` AGAIN! That's why they are duplicated!

# So all I have to do is find the first `  @override\n  Widget build(BuildContext context)` and delete the duplicate `helpers` that I injected just before it.
# The injected helpers start with `  static double parseDouble` and end right before the first `  @override\n  Widget build(BuildContext context)`.
# But wait, `grocery_top` already contains `static double parseDouble`. 
# So there are TWO `static double parseDouble` before the FIRST `build`?
# Yes! Because my script did: `new_grocery = grocery_top + helpers + '\n' + grocery_build + '\n\n' + card_class`

# Let's just find the last `  static double parseDouble` before `build`, and remove everything from there up to `build`!
# Since the injected `helpers` start exactly with `  static double parseDouble`!

build_idx = text.find('  @override\n  Widget build(BuildContext context)')
first_part = text[:build_idx]

# Find the LAST `  static double parseDouble` in first_part
last_parse = first_part.rfind('  static double parseDouble')

if last_parse != -1 and last_parse > 10000: # Ensure we don't delete the first one
    # Remove from last_parse to build_idx
    first_part = first_part[:last_parse]

rest = text[build_idx:]
new_text = first_part + rest

with open(grocery_path, 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Duplicates removed from grocery")

