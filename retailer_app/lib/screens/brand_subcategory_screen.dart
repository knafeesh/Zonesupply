import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'subcategory_browse_screen.dart';

class BrandSubCategoryScreen extends StatefulWidget {
  final String brandName;

  const BrandSubCategoryScreen({
    super.key,
    required this.brandName,
  });

  @override
  State<BrandSubCategoryScreen> createState() => _BrandSubCategoryScreenState();
}

class _BrandSubCategoryScreenState extends State<BrandSubCategoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  // Data map for brands and their photo subcategories matching reference design
  static final Map<String, Map<String, dynamic>> _brandData = {
    'Coca-Cola': {
      'category': 'Beverages',
      'sections': [
        {
          'title': 'Cola Flavoured Drink',
          'items': [
            {
              'name': 'COCA COLA',
              'logo': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE50914),
              'textColor': Colors.white,
            },
            {
              'name': 'THUMS UP',
              'logo': 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF111111),
              'textColor': Colors.red,
            },
            {
              'name': 'DIET COKE',
              'logo': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD1D5DB),
              'textColor': const Color(0xFFE50914),
            },
            {
              'name': 'COKE ZERO',
              'logo': 'https://images.unsplash.com/photo-1567103472667-6898f3a79cf2?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF000000),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Lemonade Drink',
          'items': [
            {
              'name': 'FANTA',
              'logo': 'https://images.unsplash.com/photo-1624517452488-04869289c4ca?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF9800),
              'textColor': Colors.white,
            },
            {
              'name': 'SPRITE',
              'logo': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF2E7D32),
              'textColor': Colors.white,
            },
            {
              'name': 'LIMCA',
              'logo': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF4CAF50),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Juices & Fruit Drink',
          'items': [
            {
              'name': 'MAAZA',
              'logo': 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF9800),
              'textColor': Colors.white,
            },
            {
              'name': 'MINUTE MAID',
              'logo': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE65100),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Soda & Energy Drink',
          'items': [
            {
              'name': 'SCHWEPPES',
              'logo': 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFBC02D),
              'textColor': Colors.black,
            },
            {
              'name': 'PREDATOR',
              'logo': 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF212121),
              'textColor': Colors.white,
            },
            {
              'name': 'MONSTER',
              'logo': 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF000000),
              'textColor': const Color(0xFF76FF03),
            },
            {
              'name': 'THUMS UP CHARGED',
              'logo': 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF1B5E20),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Drinking Water',
          'items': [
            {
              'name': 'KINLEY',
              'logo': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE0F7FA),
              'textColor': const Color(0xFF006064),
            },
          ]
        },
      ]
    },
    'Unilever': {
      'category': 'Home Care',
      'sections': [
        {
          'title': 'Laundry & Fabric Care',
          'items': [
            {
              'name': 'SURF EXCEL',
              'logo': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0057D9),
              'textColor': Colors.white,
            },
            {
              'name': 'RIN',
              'logo': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF1565C0),
              'textColor': Colors.white,
            },
            {
              'name': 'WHEEL',
              'logo': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0288D1),
              'textColor': Colors.white,
            },
            {
              'name': 'COMFORT',
              'logo': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF8E24AA),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Soaps & Body Wash',
          'items': [
            {
              'name': 'DOVE',
              'logo': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFF5F5F5),
              'textColor': const Color(0xFF1565C0),
            },
            {
              'name': 'LUX',
              'logo': 'https://images.unsplash.com/photo-1608248597261-5421d55ab385?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD4AF37),
              'textColor': Colors.black,
            },
            {
              'name': 'PEARS',
              'logo': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE65100),
              'textColor': Colors.white,
            },
            {
              'name': 'LIFEBUOY',
              'logo': 'https://images.unsplash.com/photo-1608248597261-5421d55ab385?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFC62828),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Hair Care & Shampoo',
          'items': [
            {
              'name': 'SUNSILK',
              'logo': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE91E63),
              'textColor': Colors.white,
            },
            {
              'name': 'CLINIC PLUS',
              'logo': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF1976D2),
              'textColor': Colors.white,
            },
            {
              'name': 'TRESEMME',
              'logo': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF212121),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Skin Care & Cosmetics',
          'items': [
            {
              'name': 'PONDS',
              'logo': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFF8BBD0),
              'textColor': const Color(0xFF880E4F),
            },
            {
              'name': 'GLOW & LOVELY',
              'logo': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF80AB),
              'textColor': Colors.white,
            },
            {
              'name': 'LAKME',
              'logo': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF000000),
              'textColor': Colors.white,
            },
            {
              'name': 'VASELINE',
              'logo': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0288D1),
              'textColor': Colors.white,
            },
          ]
        },
      ]
    },
    'Nestlé': {
      'category': 'Packaged Foods & Dry Fruits',
      'sections': [
        {
          'title': 'Noodles & Cooking',
          'items': [
            {
              'name': 'MAGGI NOODLES',
              'logo': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFD600),
              'textColor': const Color(0xFFD50000),
            },
            {
              'name': 'MAGGI MASALA-AE-MAGIC',
              'logo': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFDD2C00),
              'textColor': Colors.white,
            },
            {
              'name': 'MAGGI SAUCE',
              'logo': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD50000),
              'textColor': Colors.yellow,
            },
            {
              'name': 'MAGGI PASTA',
              'logo': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF6D00),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Coffee & Beverages',
          'items': [
            {
              'name': 'NESCAFE CLASSIC',
              'logo': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF3E2723),
              'textColor': Colors.white,
            },
            {
              'name': 'NESCAFE SUNRISE',
              'logo': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD84315),
              'textColor': Colors.white,
            },
            {
              'name': 'NESCAFE GOLD',
              'logo': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFD700),
              'textColor': Colors.black,
            },
            {
              'name': 'MILO',
              'logo': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF2E7D32),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Chocolates & Confectionery',
          'items': [
            {
              'name': 'KITKAT',
              'logo': 'https://images.unsplash.com/photo-1582176604856-e822b376c666?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD50000),
              'textColor': Colors.white,
            },
            {
              'name': 'MUNCH',
              'logo': 'https://images.unsplash.com/photo-1582176604856-e822b376c666?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF303F9F),
              'textColor': Colors.white,
            },
            {
              'name': 'MILKYBAR',
              'logo': 'https://images.unsplash.com/photo-1582176604856-e822b376c666?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE0F2F1),
              'textColor': const Color(0xFF006064),
            },
          ]
        },
      ]
    },
    'P&G': {
      'category': 'Home Care',
      'sections': [
        {
          'title': 'Laundry Care',
          'items': [
            {
              'name': 'TIDE',
              'logo': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF6D00),
              'textColor': Colors.blue,
            },
            {
              'name': 'ARIEL',
              'logo': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF00C853),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Baby & Feminine Care',
          'items': [
            {
              'name': 'PAMPERS',
              'logo': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF00B8D4),
              'textColor': Colors.white,
            },
            {
              'name': 'WHISPER',
              'logo': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFAA00FF),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Grooming & Oral Care',
          'items': [
            {
              'name': 'GILLETTE',
              'logo': 'https://images.unsplash.com/photo-1621607512214-68297480165e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0D47A1),
              'textColor': Colors.white,
            },
            {
              'name': 'HEAD & SHOULDERS',
              'logo': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF1565C0),
              'textColor': Colors.white,
            },
            {
              'name': 'PANTENE',
              'logo': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFD700),
              'textColor': Colors.black,
            },
            {
              'name': 'ORAL-B',
              'logo': 'https://images.unsplash.com/photo-1559599101-f09722fb4948?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF01579B),
              'textColor': Colors.white,
            },
          ]
        },
      ]
    },
    'ITC': {
      'category': 'Grocery',
      'sections': [
        {
          'title': 'Atta & Kitchen Staples',
          'items': [
            {
              'name': 'AASHIRVAAD ATTA',
              'logo': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE65100),
              'textColor': Colors.white,
            },
            {
              'name': 'AASHIRVAAD SALT',
              'logo': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0288D1),
              'textColor': Colors.white,
            },
            {
              'name': 'AASHIRVAAD SPICES',
              'logo': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD50000),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Biscuits & Cookies',
          'items': [
            {
              'name': 'DARK FANTASY',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF212121),
              'textColor': const Color(0xFFFFD700),
            },
            {
              'name': 'MOM\'S MAGIC',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF8D6E63),
              'textColor': Colors.white,
            },
            {
              'name': 'SUNFEAST MARIE',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFA000),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Snacks & Noodles',
          'items': [
            {
              'name': 'BINGO CHIPS',
              'logo': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD50000),
              'textColor': Colors.white,
            },
            {
              'name': 'BINGO MAD ANGLES',
              'logo': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF6D00),
              'textColor': Colors.white,
            },
            {
              'name': 'YIPPEE NOODLES',
              'logo': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFAB00),
              'textColor': const Color(0xFFD50000),
            },
          ]
        },
      ]
    },
    'Amul': {
      'category': 'Dairy, Fresh & Frozen',
      'sections': [
        {
          'title': 'Butter, Cheese & Paneer',
          'items': [
            {
              'name': 'AMUL BUTTER',
              'logo': 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFD600),
              'textColor': const Color(0xFFD50000),
            },
            {
              'name': 'AMUL CHEESE SLICES',
              'logo': 'https://images.unsplash.com/photo-1552767059-ce182ead8c1b?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFAB00),
              'textColor': Colors.white,
            },
            {
              'name': 'AMUL PANEER',
              'logo': 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE0F7FA),
              'textColor': const Color(0xFF006064),
            },
          ]
        },
        {
          'title': 'Milk & Dairy Drinks',
          'items': [
            {
              'name': 'AMUL TAAZA MILK',
              'logo': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0288D1),
              'textColor': Colors.white,
            },
            {
              'name': 'AMUL GOLD MILK',
              'logo': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFC62828),
              'textColor': Colors.white,
            },
            {
              'name': 'AMUL KOOL',
              'logo': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF009688),
              'textColor': Colors.white,
            },
          ]
        },
      ]
    },
    'Britannia': {
      'category': 'Packaged Foods & Dry Fruits',
      'sections': [
        {
          'title': 'Cookies & Biscuits',
          'items': [
            {
              'name': 'GOOD DAY',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFA000),
              'textColor': Colors.white,
            },
            {
              'name': 'MARIE GOLD',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF8F00),
              'textColor': Colors.white,
            },
            {
              'name': 'BOURBON',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF3E2723),
              'textColor': Colors.white,
            },
            {
              'name': 'NUTRICHOICE',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF33691E),
              'textColor': Colors.white,
            },
          ]
        },
        {
          'title': 'Cakes & Rusk',
          'items': [
            {
              'name': 'BRITANNIA CAKE',
              'logo': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFD81B60),
              'textColor': Colors.white,
            },
            {
              'name': 'TOASTEA RUSK',
              'logo': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF6D4C41),
              'textColor': Colors.white,
            },
          ]
        },
      ]
    },
    'Parle': {
      'category': 'Packaged Foods & Dry Fruits',
      'sections': [
        {
          'title': 'Biscuits & Cookies',
          'items': [
            {
              'name': 'PARLE-G',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFB300),
              'textColor': const Color(0xFFB71C1C),
            },
            {
              'name': 'MONACO',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFF8F00),
              'textColor': Colors.white,
            },
            {
              'name': 'KRACKJACK',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE65100),
              'textColor': Colors.white,
            },
            {
              'name': 'HIDE & SEEK',
              'logo': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF3E2723),
              'textColor': const Color(0xFFFFD700),
            },
          ]
        },
      ]
    },
    'Dabur': {
      'category': 'Health & OTC',
      'sections': [
        {
          'title': 'Health & Supplements',
          'items': [
            {
              'name': 'CHYAWANPRASH',
              'logo': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFBF360C),
              'textColor': Colors.white,
            },
            {
              'name': 'DABUR HONEY',
              'logo': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFFFA000),
              'textColor': Colors.black,
            },
            {
              'name': 'REAL FRUIT JUICE',
              'logo': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFE65100),
              'textColor': Colors.white,
            },
          ]
        },
      ]
    },
    'Godrej': {
      'category': 'Home Care',
      'sections': [
        {
          'title': 'Home Protection & Wash',
          'items': [
            {
              'name': 'GOOD KNIGHT',
              'logo': 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0D47A1),
              'textColor': Colors.white,
            },
            {
              'name': 'HIT SPRAY',
              'logo': 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFFB71C1C),
              'textColor': Colors.white,
            },
            {
              'name': 'CINTHOL',
              'logo': 'https://images.unsplash.com/photo-1608248597261-5421d55ab385?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF00838F),
              'textColor': Colors.white,
            },
          ]
        },
      ]
    },
  };

  Map<String, dynamic> get _currentBrandInfo {
    return _brandData[widget.brandName] ?? {
      'category': 'Grocery',
      'sections': [
        {
          'title': '${widget.brandName} Products',
          'items': [
            {
              'name': widget.brandName.toUpperCase(),
              'logo': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200&auto=format&fit=crop&q=80',
              'bgColor': const Color(0xFF0057D9),
              'textColor': Colors.white,
            }
          ]
        }
      ]
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = _currentBrandInfo;
    final String mainCategory = info['category'] as String;
    final List sections = info['sections'] as List;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2EDFD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search brand subcategories...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(
                widget.brandName,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFF0F172A)),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchCtrl.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final section = sections[sectionIndex];
          final String title = section['title'] as String;
          final List items = section['items'] as List;

          final filteredItems = _searchQuery.isEmpty
              ? items
              : items.where((item) =>
                  (item['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (filteredItems.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
              ),

              // Horizontal Row of Branded Subcategories (matching screenshot design)
              SizedBox(
                height: 115,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final String name = item['name'] as String;
                    final String logo = item['logo'] as String;
                    final Color bgColor = item['bgColor'] as Color;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubCategoryBrowseScreen(
                              category: mainCategory,
                              initialSubCategory: name,
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 82,
                        child: Column(
                          children: [
                            // Circular Logo / Photo Badge
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: bgColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: item['textColor'] as Color? ?? Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Bold Uppercase Brand Subcategory Label
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF212121),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Light divider separating subcategories
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            ],
          );
        },
      ),
    );
  }
}
