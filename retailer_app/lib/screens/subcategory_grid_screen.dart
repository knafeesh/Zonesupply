import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'subcategory_browse_screen.dart';

class SubCategoryGridScreen extends StatefulWidget {
  final String categoryName;
  final ValueChanged<String> onSubCategorySelected;

  const SubCategoryGridScreen({
    super.key,
    required this.categoryName,
    required this.onSubCategorySelected,
  });

  @override
  State<SubCategoryGridScreen> createState() => _SubCategoryGridScreenState();
}

class _SubCategoryGridScreenState extends State<SubCategoryGridScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String? _selectedSubCategoryName;

  // Complete, curated subcategories with realistic product photos for all departments
  static const Map<String, List<Map<String, String>>> _subCategoryData = {
    'Grocery': [
      {
        'name': 'Cold Drinks &\nSoft Drinks',
        'image': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Fruit Juices &\nEnergy Drinks',
        'image': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Atta & Flours\n(Aashirvaad)',
        'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Basmati Rice\n(Daawat/Fortune)',
        'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Edible Oils & Ghee\n(Saffola/Fortune)',
        'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Spices & Masalas\n(Everest/MDH)',
        'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Chips & Snacks\n(Lays/Kurkure)',
        'image': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Biscuits & Cookies\n(Parle/Britannia)',
        'image': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Tea & Coffee\n(Nescafe/Tata)',
        'image': 'https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Home Care': [
      {
        'name': 'Laundry',
        'image': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'House &\nKitchen Cleaning',
        'image': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Home Utilities',
        'image': 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Air & Car\nFresheners',
        'image': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Shoe Care',
        'image': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Pooja Needs',
        'image': 'https://images.unsplash.com/photo-1609710228159-0fa9bd7c0827?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Pet Care',
        'image': 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Beverages': [
      {
        'name': 'Soft Drinks\n(Coca-Cola/Pepsi)',
        'image': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Cold Drinks\n(Thums Up/Sprite)',
        'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Juices & Mango\n(Maaza/Frooti)',
        'image': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Energy Drinks\n(Red Bull/Sting)',
        'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Tea & Coffee\n(Nescafe/Tata)',
        'image': 'https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Packaged Water\n(Bisleri/Kinley)',
        'image': 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Personal Care': [
      {
        'name': 'Skin & Face Care',
        'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Hair Care & Oils',
        'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Bath & Soap',
        'image': 'https://images.unsplash.com/photo-1608248597261-837240c11b02?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Oral Care',
        'image': 'https://images.unsplash.com/photo-1559599101-f09722fb4948?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Shaving & Grooming',
        'image': 'https://images.unsplash.com/photo-1621607512214-68297480165e?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Perfumes & Deos',
        'image': 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Rice, Atta & Dals': [
      {
        'name': 'Wheat Flour (Atta)',
        'image': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Basmati & Rice',
        'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Dals & Pulses',
        'image': 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Poha, Suji & Maida',
        'image': 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Packaged Foods & Dry Fruits': [
      {
        'name': 'Biscuits & Cookies',
        'image': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Noodles & Pasta',
        'image': 'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Chips & Snacks',
        'image': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Dry Fruits & Nuts',
        'image': 'https://images.unsplash.com/photo-1599599810694-b5b37304c03d?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Oil, Sugar & Masalas': [
      {
        'name': 'Edible Oils & Ghee',
        'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Spices & Masalas',
        'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Sugar & Salt',
        'image': 'https://images.unsplash.com/photo-1581074817932-af423ba4566e?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Dairy, Fresh & Frozen': [
      {
        'name': 'Milk & Butter',
        'image': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Paneer & Cheese',
        'image': 'https://images.unsplash.com/photo-1486887396153-fa416525c108?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Frozen Snacks',
        'image': 'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Luggage & Apparel': [
      {
        'name': 'Suitcases & Trolleys',
        'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Backpacks & Bags',
        'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Restaurant Supplies & Houseware': [
      {
        'name': 'Plates & Crockery',
        'image': 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Tissues & Napkins',
        'image': 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e6?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Health & OTC': [
      {
        'name': 'Pain Relief & Balms',
        'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Cold & Cough Care',
        'image': 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'IT, Stationery & Office Furniture': [
      {
        'name': 'Notebooks & Registers',
        'image': 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Pens & Stationery',
        'image': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Kitchen & Home Appliances': [
      {
        'name': 'Mixers & Grinders',
        'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Kettles & Toasters',
        'image': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Fashion': [
      {
        'name': 'Women',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Jeans & Jeggings',
        'image': 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'T-shirts',
        'image': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Tops & Shirts',
        'image': 'https://images.unsplash.com/photo-1598554747436-c9293d6a588f?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Dresses',
        'image': 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Men',
        'image': 'https://images.unsplash.com/photo-1617137984095-74e4e5e3613f?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Shirts',
        'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Jewellery',
        'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Innerwear',
        'image': 'https://images.unsplash.com/photo-1590736969955-71cc94801759?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Trousers & Pants',
        'image': 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Footwear',
        'image': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Beauty',
        'image': 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Trackpants',
        'image': 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Joggers',
        'image': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Cargos',
        'image': 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Co-ords',
        'image': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Fancy Saree',
        'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Kurti / Set',
        'image': 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Electronics': [
      {
        'name': 'Smart TVs & Audio',
        'image': 'https://images.unsplash.com/photo-1593305841991-05c297ba4575?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Smartphones',
        'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Sports': [
      {
        'name': 'Cricket Equipment',
        'image': 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Fitness & Gym',
        'image': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400&auto=format&fit=crop&q=80',
      },
    ],

    'Hardware': [
      {
        'name': 'Power Tools',
        'image': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Hand Tools',
        'image': 'https://images.unsplash.com/photo-1530124560676-105518553fe9?w=400&auto=format&fit=crop&q=80',
      },
    ],
  };

  // Curated Sub-subcategories level mapping with product images
  static const Map<String, List<Map<String, String>>> _subSubCategoryData = {
    'Fashion > Fancy Saree': [
      {
        'name': 'Banarasi Silk Saree',
        'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Kanjeevaram Saree',
        'image': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Bandhani Printed',
        'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Partywear Saree',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Chiffon': [
      {
        'name': 'Floral Printed Chiffon',
        'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Plain Chiffon Border',
        'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Embellished Chiffon',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Suit-Unstitched': [
      {
        'name': 'Cotton Dress Material',
        'image': 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Chanderi Silk Suit',
        'image': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Heavy Partywear Suit',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Georgette': [
      {
        'name': 'Embroidered Georgette',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Printed Georgette',
        'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Georgette Anarkali',
        'image': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Lehenga': [
      {
        'name': 'Bridal Lehenga Choli',
        'image': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Semi-Stitched Lehenga',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Velvet Lehenga Set',
        'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Gowns': [
      {
        'name': 'Designer Evening Gown',
        'image': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Indo-Western Gown',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Long Anarkali Gown',
        'image': 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Kurti / Set': [
      {
        'name': 'Kurti Set with Dupatta',
        'image': 'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Single Kurti',
        'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Coord Set',
        'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Plazo Set',
        'image': 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Short Tops & Tunics',
        'image': 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Fashion > Men\'s Wear': [
      {
        'name': 'T-Shirts (Polo / Round)',
        'image': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Shirts (Formal/Casual)',
        'image': 'https://images.unsplash.com/photo-1603252109303-2751441dd157?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Jeans & Denim',
        'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Trousers & Pants',
        'image': 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Lowers & Shorts',
        'image': 'https://images.unsplash.com/photo-1551854838-212c50b4c184?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Home Care > Laundry': [
      {
        'name': 'Detergent Powder',
        'image': 'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Liquid Detergent',
        'image': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Fabric Conditioner',
        'image': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Detergent Bar',
        'image': 'https://images.unsplash.com/photo-1608248597261-837240c11b02?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Home Care > House & Kitchen Cleaning': [
      {
        'name': 'Toilet Cleaner',
        'image': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Floor Cleaner',
        'image': 'https://images.unsplash.com/photo-1585421514284-efb74c2b69ba?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Dishwash Liquid & Bar',
        'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=400&auto=format&fit=crop&q=80',
      },
    ],
    'Grocery > Cold Drinks & Soft Drinks': [
      {
        'name': 'Cola Drinks (Coke/Pepsi)',
        'image': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Indian Cola (Thums Up)',
        'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Lemon Soda (Sprite/7Up)',
        'image': 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&auto=format&fit=crop&q=80',
      },
      {
        'name': 'Orange Soda (Fanta/Mirinda)',
        'image': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=400&auto=format&fit=crop&q=80',
      },
    ],
  };

  List<Map<String, String>> get _subCategories {
    final query = widget.categoryName.toLowerCase().trim();

    String matchKey = '';
    for (final key in _subCategoryData.keys) {
      final k = key.toLowerCase();
      if (k == query || query.contains(k) || k.contains(query)) {
        matchKey = key;
        break;
      }
    }

    if (matchKey.isEmpty) {
      final firstWord = query.split(RegExp(r'[\s,&]+')).first;
      for (final key in _subCategoryData.keys) {
        if (key.toLowerCase().contains(firstWord)) {
          matchKey = key;
          break;
        }
      }
    }

    final list = _subCategoryData[matchKey] ?? [
      {'name': 'All Products', 'image': 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=400&auto=format&fit=crop&q=80'},
    ];

    if (_searchQuery.isEmpty) return list;
    return list.where((item) => item['name']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<Map<String, String>> get _currentDisplayItems {
    if (_selectedSubCategoryName != null) {
      final fullKey = '${widget.categoryName} > $_selectedSubCategoryName';

      String matchKey = '';
      for (final k in _subSubCategoryData.keys) {
        if (k.toLowerCase() == fullKey.toLowerCase()) {
          matchKey = k;
          break;
        }
      }
      if (matchKey.isEmpty) {
        final subLower = _selectedSubCategoryName!.toLowerCase();
        for (final k in _subSubCategoryData.keys) {
          if (k.toLowerCase().contains(subLower)) {
            matchKey = k;
            break;
          }
        }
      }

      final subSubs = _subSubCategoryData[matchKey];
      if (subSubs != null && subSubs.isNotEmpty) {
        if (_searchQuery.isEmpty) return subSubs;
        return subSubs.where((item) => item['name']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
      }
    }

    return _subCategories;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subList = _currentDisplayItems;
    final String currentTitle = _selectedSubCategoryName != null
        ? '${widget.categoryName} > $_selectedSubCategoryName'
        : widget.categoryName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0071DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_selectedSubCategoryName != null) {
              setState(() {
                _selectedSubCategoryName = null;
                _searchQuery = '';
                _searchCtrl.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(
                currentTitle,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
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
      body: subList.isEmpty
          ? Center(
              child: Text(
                'No items found',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: subList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.72,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemBuilder: (context, index) {
                final item = subList[index];
                return _SubCategoryCard(
                  name: item['name']!,
                  imageUrl: item['image']!,
                  onTap: () {
                    final selectedCleanName = item['name']!.replaceAll('\n', ' ');

                    // Check if sub-subcategories exist for this selected item
                    if (_selectedSubCategoryName == null) {
                      final fullKey = '${widget.categoryName} > $selectedCleanName';
                      final hasSubSub = _subSubCategoryData.keys.any((k) =>
                          k.toLowerCase() == fullKey.toLowerCase() ||
                          k.toLowerCase().contains(selectedCleanName.toLowerCase()));

                      if (hasSubSub) {
                        setState(() {
                          _selectedSubCategoryName = selectedCleanName;
                          _searchQuery = '';
                          _searchCtrl.clear();
                        });
                        return;
                      }
                    }

                    // Otherwise navigate to product list
                    final fullPath = _selectedSubCategoryName != null
                        ? '${widget.categoryName} > $_selectedSubCategoryName > $selectedCleanName'
                        : selectedCleanName;

                    widget.onSubCategorySelected(fullPath);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategoryBrowseScreen(
                          category: widget.categoryName,
                          initialSubCategory: fullPath,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _SubCategoryCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  bool get _isNetwork => imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                child: _isNetwork
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Color(0xFF0071DC),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0071DC)),
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Color(0xFF0071DC),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
