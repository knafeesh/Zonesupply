import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'wholesaler_shop_screen.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class CategoryHubScreen extends StatefulWidget {
  final String category;
  final String? initialSubCategory;

  const CategoryHubScreen({
    super.key,
    required this.category,
    this.initialSubCategory,
  });

  @override
  State<CategoryHubScreen> createState() => _CategoryHubScreenState();
}

class _CategoryHubScreenState extends State<CategoryHubScreen> {
  List _products = [];
  List _wholesalers = [];
  List _backendBanners = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  Set<String> _favoritedIds = {};

  late PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  String? _selectedSubCategory;

  // --- Department Configuration Definition ---
  Map<String, dynamic> _getHubConfig() {
    final cat = widget.category.toLowerCase();

    if (cat.contains('home care') || cat.contains('personal care') || cat.contains('beauty') || cat.contains('hygiene')) {
      return {
        'title': 'HOME & PERSONAL CARE',
        'subtitle': 'Bulk Detergents, Cleaners, Skincare & Daily Hygiene',
        'icon': Icons.clean_hands_rounded,
        'primaryColor': const Color(0xFF0284C7),
        'gradient': [const Color(0xFF0369A1), const Color(0xFF0284C7), const Color(0xFF38BDF8)],
        'searchHint': 'Search wholesale suppliers, detergents, soaps, cleaners...',
        'row1': [
          {'name': 'Detergent Powders', 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', 'query': 'detergent'},
          {'name': 'Dishwash Gels', 'image': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?w=400&auto=format&fit=crop&q=80', 'query': 'dishwash'},
          {'name': 'Floor Cleaners', 'image': 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=400&auto=format&fit=crop&q=80', 'query': 'cleaner'},
          {'name': 'Toilet Care', 'image': 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=400&auto=format&fit=crop&q=80', 'query': 'toilet'},
          {'name': 'Glass Sprays', 'image': 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=400&auto=format&fit=crop&q=80', 'query': 'spray'},
          {'name': 'Air Fresheners', 'image': 'https://images.unsplash.com/photo-1615397349754-cfa2066a298e?w=400&auto=format&fit=crop&q=80', 'query': 'freshener'},
          {'name': 'Mosquito Repellents', 'image': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400&auto=format&fit=crop&q=80', 'query': 'mosquito'},
          {'name': 'Garbage Bags', 'image': 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=400&auto=format&fit=crop&q=80', 'query': 'bag'},
          {'name': 'Scrubbers & Mops', 'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400&auto=format&fit=crop&q=80', 'query': 'mop'},
          {'name': 'Plastic Buckets', 'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&auto=format&fit=crop&q=80', 'query': 'bucket'},
        ],
        'row2': [
          {'name': 'Offers', 'isOffer': true, 'text': 'Min. 30% Off', 'query': 'offer'},
          {'name': 'Shampoos', 'image': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=400&auto=format&fit=crop&q=80', 'query': 'shampoo'},
          {'name': 'Bath Soaps', 'image': 'https://images.unsplash.com/photo-1607006314144-880ea8b628ec?w=400&auto=format&fit=crop&q=80', 'query': 'soap'},
          {'name': 'Toothpaste', 'image': 'https://images.unsplash.com/photo-1559591937-e1112b339474?w=400&auto=format&fit=crop&q=80', 'query': 'toothpaste'},
          {'name': 'Facewash', 'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&auto=format&fit=crop&q=80', 'query': 'facewash'},
          {'name': 'Men Grooming', 'image': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400&auto=format&fit=crop&q=80', 'query': 'shave'},
          {'name': 'Hair Oils', 'image': 'https://images.unsplash.com/photo-1608248597359-54bc6700c25a?w=400&auto=format&fit=crop&q=80', 'query': 'hair'},
          {'name': 'Baby Care', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&auto=format&fit=crop&q=80', 'query': 'baby'},
          {'name': 'Hand Sanitizers', 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', 'query': 'handwash'},
          {'name': 'Deodorants', 'image': 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=400&auto=format&fit=crop&q=80', 'query': 'deodorant'},
        ],
        'defaultBanners': [
          {
            'title': 'Detergent & Hygiene Mega Margins',
            'subtitle': 'Surf, Ariel, Vim, Colin bulk sacks & cartons — Extra 15% wholesale discount',
            'tag': 'BULK HYGIENE',
            'gradient': [Color(0xFF0369A1), Color(0xFF0284C7)],
            'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=80',
          },
          {
            'title': 'Skin & Hair Care Wholesale Fest',
            'subtitle': 'Dove, Nivea, Tresemme, Himalaya factory pricing for verified retailers',
            'tag': 'PERSONAL CARE',
            'gradient': [Color(0xFF4338CA), Color(0xFF6366F1)],
            'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=600&auto=format&fit=crop&q=80',
          },
        ],
      };
    } else if (cat.contains('apparel') || cat.contains('luggage') || cat.contains('accessory') || cat.contains('bag')) {
      return {
        'title': 'ACCESSORIES & APPAREL',
        'subtitle': 'Luggage, Trolleys, Bags, Belts, Watches & Apparel',
        'icon': Icons.luggage_rounded,
        'primaryColor': const Color(0xFF854D0E),
        'gradient': [const Color(0xFF713F12), const Color(0xFF854D0E), const Color(0xFFCA8A04)],
        'searchHint': 'Search wholesale suppliers, trolleys, backpacks, belts...',
        'row1': [
          {'name': 'Hard Trolleys', 'image': 'https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=400&auto=format&fit=crop&q=80', 'query': 'trolley'},
          {'name': 'Backpacks', 'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&auto=format&fit=crop&q=80', 'query': 'backpack'},
          {'name': 'Laptop Bags', 'image': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400&auto=format&fit=crop&q=80', 'query': 'laptop'},
          {'name': 'Handbags', 'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400&auto=format&fit=crop&q=80', 'query': 'handbag'},
          {'name': 'Duffel Bags', 'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&auto=format&fit=crop&q=80', 'query': 'duffel'},
          {'name': 'Wallets', 'image': 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=400&auto=format&fit=crop&q=80', 'query': 'wallet'},
          {'name': 'Leather Belts', 'image': 'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=400&auto=format&fit=crop&q=80', 'query': 'belt'},
          {'name': 'Sunglasses', 'image': 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&auto=format&fit=crop&q=80', 'query': 'eyewear'},
          {'name': 'Watches', 'image': 'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=400&auto=format&fit=crop&q=80', 'query': 'watch'},
          {'name': 'Caps & Hats', 'image': 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400&auto=format&fit=crop&q=80', 'query': 'cap'},
        ],
        'row2': [
          {'name': 'Offers', 'isOffer': true, 'text': 'Min. 30% Off', 'query': 'offer'},
          {'name': 'Formal Shirts', 'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&auto=format&fit=crop&q=80', 'query': 'shirt'},
          {'name': 'Polo T-Shirts', 'image': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&auto=format&fit=crop&q=80', 'query': 't-shirt'},
          {'name': 'Denim Jeans', 'image': 'https://images.unsplash.com/photo-1542272604-780c96856592?w=400&auto=format&fit=crop&q=80', 'query': 'jean'},
          {'name': 'Trackpants', 'image': 'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0?w=400&auto=format&fit=crop&q=80', 'query': 'trackpant'},
          {'name': 'Jackets', 'image': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&auto=format&fit=crop&q=80', 'query': 'jacket'},
          {'name': 'Socks', 'image': 'https://images.unsplash.com/photo-1586350977771-b3b0abd50c82?w=400&auto=format&fit=crop&q=80', 'query': 'sock'},
          {'name': 'Innerwear', 'image': 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=400&auto=format&fit=crop&q=80', 'query': 'inner'},
          {'name': 'Umbrellas', 'image': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=400&auto=format&fit=crop&q=80', 'query': 'umbrella'},
          {'name': 'Casual Footwear', 'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&auto=format&fit=crop&q=80', 'query': 'shoe'},
        ],
        'defaultBanners': [
          {
            'title': 'Travel Luggage & Trolleys Bulk Fest',
            'subtitle': 'Safari, American Tourister, VIP trolley bags & duffels at direct factory rates',
            'tag': 'LUGGAGE BULK',
            'gradient': [Color(0xFF713F12), Color(0xFF854D0E)],
            'image': 'https://images.unsplash.com/photo-1565026057447-bc90a3dceb87?w=600&auto=format&fit=crop&q=80',
          },
          {
            'title': 'Leather Accessories & Watches',
            'subtitle': 'Genuine leather wallets, formal belts & smartwatches wholesale cartons',
            'tag': 'ACCESSORIES',
            'gradient': [Color(0xFF1E293B), Color(0xFF334155)],
            'image': 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=600&auto=format&fit=crop&q=80',
          },
        ],
      };
    } else if (cat.contains('restaurant') || cat.contains('houseware') || cat.contains('cookware') || cat.contains('kitchen storage')) {
      return {
        'title': 'RESTAURANT SUPPLIES & HOUSEWARE',
        'subtitle': 'Commercial Cookware, Disposables, Melamine & Kitchen Ware',
        'icon': Icons.restaurant_rounded,
        'primaryColor': const Color(0xFFC2410C),
        'gradient': [const Color(0xFF9A3412), const Color(0xFFC2410C), const Color(0xFFF97316)],
        'searchHint': 'Search wholesale suppliers, cookware, handis, disposables...',
        'row1': [
          {'name': 'Commercial Pots', 'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=400&auto=format&fit=crop&q=80', 'query': 'cookware'},
          {'name': 'Steel Handis', 'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&auto=format&fit=crop&q=80', 'query': 'handi'},
          {'name': 'Cast Iron Tawa', 'image': 'https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?w=400&auto=format&fit=crop&q=80', 'query': 'tawa'},
          {'name': 'Chef Knives', 'image': 'https://images.unsplash.com/photo-1593618998160-e34014e67546?w=400&auto=format&fit=crop&q=80', 'query': 'knife'},
          {'name': 'Steel Kadhais', 'image': 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=400&auto=format&fit=crop&q=80', 'query': 'kadhai'},
          {'name': 'Storage Drums', 'image': 'https://images.unsplash.com/photo-1584269600519-112d071b35e6?w=400&auto=format&fit=crop&q=80', 'query': 'storage'},
          {'name': 'Oil Dispensers', 'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80', 'query': 'dispenser'},
          {'name': 'Cutlery Spoons', 'image': 'https://images.unsplash.com/photo-1584345604476-8ec5e12e42dd?w=400&auto=format&fit=crop&q=80', 'query': 'cutlery'},
          {'name': 'Insulated Jugs', 'image': 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=400&auto=format&fit=crop&q=80', 'query': 'jug'},
          {'name': 'Condiment Jars', 'image': 'https://images.unsplash.com/photo-1589135233689-d5615a20c388?w=400&auto=format&fit=crop&q=80', 'query': 'jar'},
        ],
        'row2': [
          {'name': 'Offers', 'isOffer': true, 'text': 'Min. 30% Off', 'query': 'offer'},
          {'name': 'Meal Boxes', 'image': 'https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=400&auto=format&fit=crop&q=80', 'query': 'box'},
          {'name': 'Paper Cups', 'image': 'https://images.unsplash.com/photo-1577937927133-66ef06acdf18?w=400&auto=format&fit=crop&q=80', 'query': 'cup'},
          {'name': 'Tissue Rolls', 'image': 'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?w=400&auto=format&fit=crop&q=80', 'query': 'tissue'},
          {'name': 'Melamine Sets', 'image': 'https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?w=400&auto=format&fit=crop&q=80', 'query': 'dinner'},
          {'name': 'Aluminium Foils', 'image': 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=400&auto=format&fit=crop&q=80', 'query': 'foil'},
          {'name': 'Glassware', 'image': 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400&auto=format&fit=crop&q=80', 'query': 'glass'},
          {'name': 'Dish Cleaning', 'image': 'https://images.unsplash.com/photo-1585421514738-01798e348b17?w=400&auto=format&fit=crop&q=80', 'query': 'clean'},
          {'name': 'Serving Trays', 'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=400&auto=format&fit=crop&q=80', 'query': 'tray'},
          {'name': 'Gloves & Aprons', 'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=400&auto=format&fit=crop&q=80', 'query': 'apron'},
        ],
        'defaultBanners': [
          {
            'title': 'Commercial Cookware & Biryani Handis',
            'subtitle': 'Heavy-gauge aluminium & stainless steel bulk cookware for hotels & restaurants',
            'tag': 'RESTAURANT BULK',
            'gradient': [Color(0xFF9A3412), Color(0xFFC2410C)],
            'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=600&auto=format&fit=crop&q=80',
          },
          {
            'title': 'Disposable Meal Containers & Paper Bowls',
            'subtitle': 'Microwave-safe delivery containers, paper cups & aluminium packaging',
            'tag': 'PACKAGING',
            'gradient': [Color(0xFF0F766E), Color(0xFF14B8A6)],
            'image': 'https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=600&auto=format&fit=crop&q=80',
          },
        ],
      };
    } else if (cat.contains('health') || cat.contains('otc') || cat.contains('medical') || cat.contains('wellness')) {
      return {
        'title': 'HEALTH & OTC WELLNESS',
        'subtitle': 'Vitamins, Supplements, First Aid, Ayurvedic & Daily Healthcare',
        'icon': Icons.medical_services_rounded,
        'primaryColor': const Color(0xFF059669),
        'gradient': [const Color(0xFF047857), const Color(0xFF059669), const Color(0xFF10B981)],
        'searchHint': 'Search wholesale suppliers, vitamins, first aid, ayurveda...',
        'row1': [
          {'name': 'Multivitamins', 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', 'query': 'vitamin'},
          {'name': 'Protein Nutrition', 'image': 'https://images.unsplash.com/photo-1579722820308-d74e571900a9?w=400&auto=format&fit=crop&q=80', 'query': 'protein'},
          {'name': 'Ayurvedic Care', 'image': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&auto=format&fit=crop&q=80', 'query': 'ayurveda'},
          {'name': 'Chyawanprash', 'image': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400&auto=format&fit=crop&q=80', 'query': 'immunity'},
          {'name': 'Omega-3 Oils', 'image': 'https://images.unsplash.com/photo-1577401239170-897942555fb3?w=400&auto=format&fit=crop&q=80', 'query': 'omega'},
          {'name': 'Calcium D3', 'image': 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=400&auto=format&fit=crop&q=80', 'query': 'calcium'},
          {'name': 'Herbal Green Tea', 'image': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&auto=format&fit=crop&q=80', 'query': 'tea'},
          {'name': 'Diabetic Care', 'image': 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400&auto=format&fit=crop&q=80', 'query': 'diabetic'},
          {'name': 'Digestive Antacids', 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', 'query': 'digest'},
          {'name': 'Electrolyte Drinks', 'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80', 'query': 'electrolyte'},
        ],
        'row2': [
          {'name': 'Offers', 'isOffer': true, 'text': 'Min. 30% Off', 'query': 'offer'},
          {'name': 'Bandages & Strips', 'image': 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=400&auto=format&fit=crop&q=80', 'query': 'bandage'},
          {'name': 'Antiseptic Gels', 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', 'query': 'antiseptic'},
          {'name': 'Pain Relief Sprays', 'image': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400&auto=format&fit=crop&q=80', 'query': 'pain'},
          {'name': 'BP Monitors', 'image': 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=400&auto=format&fit=crop&q=80', 'query': 'monitor'},
          {'name': 'Surgical Masks', 'image': 'https://images.unsplash.com/photo-1584634731339-252c581abfc5?w=400&auto=format&fit=crop&q=80', 'query': 'mask'},
          {'name': 'Eye & Ear Drops', 'image': 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=400&auto=format&fit=crop&q=80', 'query': 'drop'},
          {'name': 'Cough Syrups', 'image': 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400&auto=format&fit=crop&q=80', 'query': 'cough'},
          {'name': 'Hot Gel Packs', 'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&auto=format&fit=crop&q=80', 'query': 'gel'},
          {'name': 'Medical Cotton', 'image': 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=400&auto=format&fit=crop&q=80', 'query': 'cotton'},
        ],
        'defaultBanners': [
          {
            'title': 'Daily Multivitamins & Immunity Boosters',
            'subtitle': 'Vitamin C, Zinc, Protein & Omega supplements with bulk retailer discounts',
            'tag': 'WELLNESS',
            'gradient': [Color(0xFF047857), Color(0xFF059669)],
            'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=80',
          },
          {
            'title': 'First Aid & Pain Relief Direct Mills',
            'subtitle': 'Bandages, pain sprays, antiseptics & clinical health monitors at factory prices',
            'tag': 'FIRST AID',
            'gradient': [Color(0xFFB91C1C), Color(0xFFDC2626)],
            'image': 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=600&auto=format&fit=crop&q=80',
          },
        ],
      };
    } else {
      // Kitchen & Home Appliances / Hardware / Electronics default
      return {
        'title': 'KITCHEN & HOME APPLIANCES',
        'subtitle': 'Mixer Grinders, Cooktops, Kettles, Fans & Home Electronics',
        'icon': Icons.kitchen_rounded,
        'primaryColor': const Color(0xFF4F46E5),
        'gradient': [const Color(0xFF3730A3), const Color(0xFF4F46E5), const Color(0xFF818CF8)],
        'searchHint': 'Search wholesale suppliers, mixer grinders, kettles, fans...',
        'row1': [
          {'name': 'Mixer Grinders', 'image': 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&auto=format&fit=crop&q=80', 'query': 'mixer'},
          {'name': 'Induction Stoves', 'image': 'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?w=400&auto=format&fit=crop&q=80', 'query': 'induction'},
          {'name': 'Electric Kettles', 'image': 'https://images.unsplash.com/photo-1594213114663-d94db9b17125?w=400&auto=format&fit=crop&q=80', 'query': 'kettle'},
          {'name': 'Air Fryers', 'image': 'https://images.unsplash.com/photo-1544233726-9f1d2b27be8b?w=400&auto=format&fit=crop&q=80', 'query': 'fryer'},
          {'name': 'Toaster Makers', 'image': 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=400&auto=format&fit=crop&q=80', 'query': 'toaster'},
          {'name': 'Rice Cookers', 'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&auto=format&fit=crop&q=80', 'query': 'cooker'},
          {'name': 'Hand Choppers', 'image': 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&auto=format&fit=crop&q=80', 'query': 'blender'},
          {'name': 'Coffee Makers', 'image': 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=400&auto=format&fit=crop&q=80', 'query': 'coffee'},
          {'name': 'Chimneys & Hobs', 'image': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=400&auto=format&fit=crop&q=80', 'query': 'chimney'},
          {'name': 'Water Purifiers', 'image': 'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?w=400&auto=format&fit=crop&q=80', 'query': 'purifier'},
        ],
        'row2': [
          {'name': 'Offers', 'isOffer': true, 'text': 'Min. 30% Off', 'query': 'offer'},
          {'name': 'Ceiling Fans', 'image': 'https://images.unsplash.com/photo-1618941716939-553df3c6c278?w=400&auto=format&fit=crop&q=80', 'query': 'fan'},
          {'name': 'Steam Irons', 'image': 'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?w=400&auto=format&fit=crop&q=80', 'query': 'iron'},
          {'name': 'Vacuum Cleaners', 'image': 'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=400&auto=format&fit=crop&q=80', 'query': 'vacuum'},
          {'name': 'Room Heaters', 'image': 'https://images.unsplash.com/photo-1585659722983-3a675dabf23d?w=400&auto=format&fit=crop&q=80', 'query': 'heater'},
          {'name': 'LED Lighting', 'image': 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400&auto=format&fit=crop&q=80', 'query': 'led'},
          {'name': 'Extension Plugs', 'image': 'https://images.unsplash.com/photo-1558346490-a72e53ae2d4f?w=400&auto=format&fit=crop&q=80', 'query': 'plug'},
          {'name': 'Emergency Torches', 'image': 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400&auto=format&fit=crop&q=80', 'query': 'torch'},
          {'name': 'Mosquito Traps', 'image': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=400&auto=format&fit=crop&q=80', 'query': 'mosquito'},
          {'name': 'Hair Dryers', 'image': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&auto=format&fit=crop&q=80', 'query': 'dryer'},
        ],
        'defaultBanners': [
          {
            'title': 'Mixer Grinders & Cooktops Mega Deal',
            'subtitle': 'Bajaj, Philips, Prestige 750W & 1000W wholesale cartons at distributor rates',
            'tag': 'APPLIANCES BULK',
            'gradient': [Color(0xFF3730A3), Color(0xFF4F46E5)],
            'image': 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=600&auto=format&fit=crop&q=80',
          },
          {
            'title': 'Ceiling Fans & Irons Wholesale Fest',
            'subtitle': 'Crompton, Havells, Usha high-speed appliances with manufacturer warranty',
            'tag': 'HOME ELECTRONICS',
            'gradient': [Color(0xFF0F172A), Color(0xFF334155)],
            'image': 'https://images.unsplash.com/photo-1618941716939-553df3c6c278?w=600&auto=format&fit=crop&q=80',
          },
        ],
      };
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSubCategory != null && widget.initialSubCategory!.isNotEmpty) {
      _selectedSubCategory = widget.initialSubCategory;
    }

    _load();

    _bannerController = PageController();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final total = _getDynamicOfferBanners().length;
        if (total > 0) {
          _currentBannerIndex = (_currentBannerIndex + 1) % total;
          _bannerController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
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
      final wholesalersData = await ApiService.get('/wholesalers?category=${Uri.encodeComponent(widget.category)}') as List? ?? [];
      final favsData = await ApiService.get('/wholesalers/favorites/my') as List? ?? [];
      final favIds = favsData.map((w) => w['id'].toString()).toSet();

      List bannersData = [];
      try {
        final res = await ApiService.get('/banners?category=${Uri.encodeComponent(widget.category)}');
        if (res is List) bannersData = res;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _products = productsData;
          _wholesalers = wholesalersData;
          _backendBanners = bannersData;
          _favoritedIds = favIds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _matchesCategory(Map<String, dynamic> p) {
    final cat = (p['category'] as String? ?? '').toLowerCase();
    final subCat = (p['subCategory'] as String? ?? '').toLowerCase();
    final name = (p['name'] as String? ?? '').toLowerCase();
    final target = widget.category.toLowerCase();

    // Direct match or parent category prefix
    bool matchesMain = cat == target || cat.startsWith('$target > ') || cat.contains(target);

    // Department synonyms
    if (target.contains('home care') || target.contains('personal care') || target.contains('beauty') || target.contains('hygiene')) {
      matchesMain = cat.contains('home') || cat.contains('care') || cat.contains('detergent') || cat.contains('soap') || cat.contains('beauty') || subCat.contains('detergent') || subCat.contains('soap') || name.contains('soap') || name.contains('detergent');
    } else if (target.contains('luggage') || target.contains('apparel') || target.contains('accessory') || target.contains('bag')) {
      matchesMain = cat.contains('luggage') || cat.contains('bag') || cat.contains('belt') || cat.contains('trolley') || subCat.contains('bag') || subCat.contains('trolley') || name.contains('bag') || name.contains('trolley') || name.contains('wallet');
    } else if (target.contains('restaurant') || target.contains('houseware') || target.contains('cookware')) {
      matchesMain = cat.contains('restaurant') || cat.contains('cookware') || cat.contains('kitchen') || subCat.contains('cookware') || name.contains('handi') || name.contains('tawa') || name.contains('kadhai');
    } else if (target.contains('health') || target.contains('otc') || target.contains('medical') || target.contains('wellness')) {
      matchesMain = cat.contains('health') || cat.contains('otc') || cat.contains('medical') || cat.contains('wellness') || subCat.contains('vitamin') || name.contains('vitamin');
    } else if (target.contains('kitchen') || target.contains('appliance')) {
      matchesMain = cat.contains('appliance') || cat.contains('mixer') || cat.contains('kettle') || subCat.contains('mixer') || name.contains('mixer') || name.contains('kettle') || name.contains('fan');
    } else if (target.contains('electronic')) {
      matchesMain = cat.contains('electronic') || subCat.contains('tv') || subCat.contains('speaker') || name.contains('speaker') || name.contains('cable');
    } else if (target.contains('mobile')) {
      matchesMain = cat.contains('mobile') || cat.contains('phone') || subCat.contains('phone') || name.contains('mobile') || name.contains('charger');
    } else if (target.contains('hardware')) {
      matchesMain = cat.contains('hardware') || cat.contains('tool') || subCat.contains('tool');
    } else if (target.contains('sport')) {
      matchesMain = cat.contains('sport') || cat.contains('gym') || subCat.contains('cricket');
    }

    // Exclude strictly fashion if department is non-fashion
    if (!target.contains('fashion') && !target.contains('apparel') && (cat.startsWith('fashion > ') || cat == 'fashion')) {
      return false;
    }

    if (!matchesMain) return false;

    // Filter by selected subcategory if active
    if (_selectedSubCategory != null && _selectedSubCategory!.isNotEmpty) {
      final subTarget = _selectedSubCategory!.toLowerCase();
      final matchesSub = cat.contains(subTarget) || subCat.contains(subTarget) || name.contains(subTarget);
      if (!matchesSub) return false;
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return name.contains(q) || cat.contains(q) || subCat.contains(q);
    }

    return true;
  }

  List get _filteredProducts {
    return _products.where((p) {
      final map = p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p);
      return _matchesCategory(map);
    }).toList();
  }

  List<Map<String, dynamic>> _getDynamicOfferBanners() {
    final List<Map<String, dynamic>> dynamicBanners = [];
    final cfg = _getHubConfig();

    for (var b in _backendBanners) {
      final title = b['title']?.toString() ?? 'Special Wholesale Deal';
      final subtitle = b['subtitle']?.toString() ?? 'Direct manufacturer wholesale rates';
      final tag = b['tag']?.toString() ?? 'SELLER OFFER';
      final img = b['imageUrl']?.toString() ?? '';
      final gStartHex = b['gradientStart']?.toString() ?? '#0284C7';
      final gEndHex = b['gradientEnd']?.toString() ?? '#38BDF8';

      final Color gStart = _hexToColor(gStartHex, cfg['primaryColor']);
      final Color gEnd = _hexToColor(gEndHex, cfg['primaryColor']);

      final shopName = b['wholesaler']?['businessName']?.toString();

      dynamicBanners.add({
        'title': title,
        'subtitle': subtitle,
        'tag': shopName != null && shopName.isNotEmpty ? '$tag • $shopName' : tag,
        'gradient': [gStart, gEnd],
        'image': img.startsWith('/') ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$img' : img,
        'wholesalerId': b['wholesalerId']?.toString(),
        'wholesaler': b['wholesaler'],
        'subCategory': b['subCategory'],
      });
    }

    if (dynamicBanners.isNotEmpty) return dynamicBanners;
    return List<Map<String, dynamic>>.from(cfg['defaultBanners'] ?? []);
  }

  Color _hexToColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  Widget _buildCategoryTile(Map<String, dynamic> item, Color primaryColor) {
    final name = item['name'] as String;
    final isOffer = item['isOffer'] == true;
    final isSelected = _selectedSubCategory == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSubCategory == name) {
            _selectedSubCategory = null;
          } else {
            _selectedSubCategory = name;
          }
        });
      },
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isOffer ? const Color(0xFFE50914) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? Border.all(color: primaryColor, width: 2.5)
                    : Border.all(color: Colors.transparent, width: 2.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isOffer
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Min.',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '30%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Off',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ],
                      )
                    : Image.network(
                        item['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: Center(
                            child: Icon(Icons.category_rounded, color: primaryColor, size: 28),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryColor : const Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isMatchingCategoryWholesaler(Map<String, dynamic> w) {
    final catLower = widget.category.toLowerCase().trim();

    if (w['categories'] is List) {
      for (var c in w['categories'] as List) {
        final cl = c.toString().toLowerCase();
        if (cl.contains(catLower) || catLower.contains(cl)) return true;
      }
    }

    final bName = (w['businessName'] as String? ?? '').toLowerCase();
    if (catLower.contains('home') || catLower.contains('personal') || catLower.contains('care')) {
      return bName.contains('care') || bName.contains('hygiene') || bName.contains('clean') || bName.contains('fmcg') || bName.contains('detergent');
    } else if (catLower.contains('luggage') || catLower.contains('apparel') || catLower.contains('bag') || catLower.contains('accessories')) {
      return bName.contains('luggage') || bName.contains('bag') || bName.contains('leather') || bName.contains('accessory') || bName.contains('apparel') || bName.contains('trolley');
    } else if (catLower.contains('restaurant') || catLower.contains('houseware') || catLower.contains('cookware')) {
      return bName.contains('restaurant') || bName.contains('hotel') || bName.contains('cookware') || bName.contains('utensil') || bName.contains('crockery') || bName.contains('pack');
    } else if (catLower.contains('health') || catLower.contains('otc') || catLower.contains('medical') || catLower.contains('wellness')) {
      return bName.contains('pharma') || bName.contains('health') || bName.contains('medical') || bName.contains('ayurved') || bName.contains('wellness') || bName.contains('otc');
    } else if (catLower.contains('appliance') || catLower.contains('kitchen') || catLower.contains('electronic')) {
      return bName.contains('appliance') || bName.contains('electronic') || bName.contains('electrical') || bName.contains('kitchen');
    }

    return bName.contains(catLower);
  }

  List<Map<String, dynamic>> _getDefaultCategoryWholesalers() {
    final catLower = widget.category.toLowerCase().trim();
    if (catLower.contains('home') || catLower.contains('personal') || catLower.contains('care')) {
      return [
        {
          'id': 'home-wholesaler-1',
          'businessName': 'Hindustan Care & Hygiene Wholesale Depo',
          'businessAddress': 'Industrial Area Phase 2, Gurugram',
          'categories': ['Home Care', 'Personal Care'],
        },
        {
          'id': 'home-wholesaler-2',
          'businessName': 'Godrej & Dabur Direct FMCG Distributors',
          'businessAddress': 'Wholesale Mandi Complex, Delhi',
          'categories': ['Home Care', 'Personal Care'],
        },
        {
          'id': 'home-wholesaler-3',
          'businessName': 'Reckitt Cleaners & Surface Hygiene Traders',
          'businessAddress': 'Transport Hub Sector 37, Noida',
          'categories': ['Home Care'],
        },
      ];
    } else if (catLower.contains('luggage') || catLower.contains('apparel') || catLower.contains('bag') || catLower.contains('accessories')) {
      return [
        {
          'id': 'acc-wholesaler-1',
          'businessName': 'VIP & Samsonite Direct Luggage Depo',
          'businessAddress': 'Leather Goods Complex, Dharavi, Mumbai',
          'categories': ['Luggage & Apparel'],
        },
        {
          'id': 'acc-wholesaler-2',
          'businessName': 'American Tourister & Safari Bags Wholesale',
          'businessAddress': 'Pahar Ganj Bag Market, New Delhi',
          'categories': ['Luggage & Apparel'],
        },
        {
          'id': 'acc-wholesaler-3',
          'businessName': 'Royal Leather Belts & Wallets Manufacturing',
          'businessAddress': 'Jajmau Leather Cluster, Kanpur',
          'categories': ['Luggage & Apparel'],
        },
      ];
    } else if (catLower.contains('restaurant') || catLower.contains('houseware') || catLower.contains('cookware')) {
      return [
        {
          'id': 'rest-wholesaler-1',
          'businessName': 'Commercial Cookware & Handi Mills',
          'businessAddress': 'Chawri Bazar Brass & Utensil Mandi, Delhi',
          'categories': ['Restaurant Supplies & Houseware'],
        },
        {
          'id': 'rest-wholesaler-2',
          'businessName': 'EcoPack Food Containers & Disposables Depo',
          'businessAddress': 'Packaging Cluster, Okhla Phase 1, New Delhi',
          'categories': ['Restaurant Supplies & Houseware'],
        },
        {
          'id': 'rest-wholesaler-3',
          'businessName': 'Hotelware & Melamine Crockery Traders',
          'businessAddress': 'Sadar Bazar Wholesale Crockery Yard, Delhi',
          'categories': ['Restaurant Supplies & Houseware'],
        },
      ];
    } else if (catLower.contains('health') || catLower.contains('otc') || catLower.contains('medical') || catLower.contains('wellness')) {
      return [
        {
          'id': 'health-wholesaler-1',
          'businessName': 'Cipla & Apollo OTC Wellness Distributors',
          'businessAddress': 'Bhagirath Palace Medicine Market, Delhi',
          'categories': ['Health & OTC'],
        },
        {
          'id': 'health-wholesaler-2',
          'businessName': 'Dabur & Baidyanath Ayurvedic Depo',
          'businessAddress': 'Herbal Mandi Complex, Haridwar',
          'categories': ['Health & OTC'],
        },
        {
          'id': 'health-wholesaler-3',
          'businessName': 'Clinical First Aid & Healthcare Traders',
          'businessAddress': 'Dawa Mandi Sector 12, Chandigarh',
          'categories': ['Health & OTC'],
        },
      ];
    } else {
      return [
        {
          'id': 'app-wholesaler-1',
          'businessName': 'Bajaj & Prestige Wholesale Appliances',
          'businessAddress': 'Electrical Market, Chandni Chowk, Delhi',
          'categories': ['Kitchen & Home Appliances'],
        },
        {
          'id': 'app-wholesaler-2',
          'businessName': 'Philips & Havells Direct Electronics Hub',
          'businessAddress': 'Lamington Road Wholesale Yard, Mumbai',
          'categories': ['Kitchen & Home Appliances'],
        },
        {
          'id': 'app-wholesaler-3',
          'businessName': 'Crompton & Orient Home Electronics Depo',
          'businessAddress': 'Electronic Complex, SP Road, Bengaluru',
          'categories': ['Kitchen & Home Appliances'],
        },
      ];
    }
  }

  List get _filteredWholesalers {
    var list = _wholesalers.where((w) {
      final map = w is Map<String, dynamic> ? w : Map<String, dynamic>.from(w);
      return _isMatchingCategoryWholesaler(map);
    }).toList();

    if (list.isEmpty) {
      list = _getDefaultCategoryWholesalers();
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((w) {
        final bName = (w['businessName'] as String? ?? '').toLowerCase();
        final addr = (w['businessAddress'] as String? ?? w['address'] as String? ?? '').toLowerCase();
        return bName.contains(q) || addr.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final banners = _getDynamicOfferBanners();
    final wholesalers = _filteredWholesalers;
    final cfg = _getHubConfig();
    final primaryColor = cfg['primaryColor'] as Color;
    final List<Map<String, dynamic>> row1 = cfg['row1'] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> row2 = cfg['row2'] as List<Map<String, dynamic>>; 
        
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cfg['icon'] as IconData, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              cfg['title'] as String,
              style: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Consumer<CartProvider>(
              builder: (_, cart, __) => Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                backgroundColor: primaryColor,
                child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0F172A)),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: primaryColor,
              child: CustomScrollView(
                slivers: [
                  // 1. Search Bar
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: cfg['searchHint'] as String,
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Color(0xFF878787)),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _search = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. FASHION OFFER SLIDESHOW
                  if (banners.isNotEmpty && _search.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 190,
                              child: PageView.builder(
                                controller: _bannerController,
                                itemCount: banners.length,
                                onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                                itemBuilder: (_, idx) {
                                  final b = banners[idx];
                                  return GestureDetector(
                                    onTap: () {
                                      if (b['wholesaler'] != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => WholesalerShopScreen(wholesaler: b['wholesaler']),
                                          ),
                                        ).then((_) => _load());
                                      } else if (b['subCategory'] != null && b['subCategory'].toString().isNotEmpty) {
                                        setState(() {
                                          _selectedSubCategory = b['subCategory'].toString();
                                        });
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (b['gradient'] as List<Color>)[0].withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              b['image'] as String,
                                              fit: BoxFit.cover,
                                              color: Colors.black.withValues(alpha: 0.4),
                                              colorBlendMode: BlendMode.darken,
                                              errorBuilder: (_, __, ___) => Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: b['gradient'] as List<Color>,
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.25),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                                    ),
                                                    child: Text(
                                                      b['tag'] as String,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    b['title'] as String,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w900,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    b['subtitle'] as String,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              right: 16,
                                              child: Icon(
                                                b['icon'] as IconData? ?? cfg['icon'] as IconData,
                                                color: Colors.white.withValues(alpha: 0.8),
                                                size: 32,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Dot indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(banners.length, (idx) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentBannerIndex == idx ? 18 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: _currentBannerIndex == idx
                                        ? primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 3. FASHION CATEGORIES (2-Row Real Photo Visual Cards)
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  'POPULAR DEPARTMENTS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedSubCategory != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedSubCategory = null),
                                    child: Text(
                                      'Clear Filter ✕',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFD4367C),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: row1.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (_, colIdx) {
                                final topItem = row1[colIdx];
                                final bottomItem = row2[colIdx];
                                return Column(
                                  children: [
                                    _buildCategoryTile(topItem, primaryColor),
                                    const SizedBox(height: 12),
                                    _buildCategoryTile(bottomItem, primaryColor),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. FASHION WHOLESALE SHOPS SECTION
                  if (wholesalers.isNotEmpty && _search.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text(
                                    'VERIFIED WHOLESALE DISTRIBUTORS',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${wholesalers.length} Verified',
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: wholesalers.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, idx) {
                                  final w = wholesalers[idx];
                                  final profilePic = w['user']?['profilePicture'];
                                  final productCount = w['productCount'] ?? (w['products'] is List ? (w['products'] as List).length : 0);

                                  final shopGradients = [
                                    [primaryColor, const Color(0xFFBB4DE0)],
                                    [const Color(0xFFD4367C), const Color(0xFFFF8A65)],
                                    [const Color(0xFF1565C0), const Color(0xFF00ACC1)],
                                    [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                                    [const Color(0xFFE65100), const Color(0xFFFFB300)],
                                    [const Color(0xFF4527A0), const Color(0xFF7E57C2)],
                                  ];
                                  final gradient = shopGradients[idx % shopGradients.length];

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
                                      width: 145,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradient[0].withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                                                  backgroundImage: profilePic != null && profilePic.toString().isNotEmpty
                                                      ? NetworkImage(
                                                          profilePic.toString().startsWith('/')
                                                              ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}$profilePic'
                                                              : profilePic.toString(),
                                                        )
                                                      : null,
                                                  child: profilePic == null || profilePic.toString().isEmpty
                                                      ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 22)
                                                      : null,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  w['businessName'] ?? 'Fashion Store',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 11),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '$productCount items',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Text(
                                                    'Visit Shop →',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.verified_rounded, color: primaryColor, size: 13),
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
                    ),



                  // 5. CATEGORY PRODUCTS (Strict Category & SubCategory Products)
                  if (_filteredProducts.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'PRODUCTS IN ${widget.category.toUpperCase()}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_filteredProducts.length} Items',
                              style: GoogleFonts.inter(
                                color: primaryColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            final pName = p['name'] ?? 'Product';
                            final originalPrice = double.tryParse(p['pricePerUnit']?.toString() ?? '0') ?? 150.0;
                            final discount = double.tryParse(p['discount']?.toString() ?? '0') ?? 15.0;
                            final sellingPrice = discount > 0 ? originalPrice * (1 - discount / 100) : originalPrice;
                            final wName = p['wholesaler']?['businessName'] ?? 'Verified Seller';
                            final categoryTag = p['category'] ?? widget.category;

                            return Container(
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
                                  // Product image
                                  SizedBox(
                                    height: 120,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty
                                                ? Image.network(
                                                    p['imageUrl'].toString().startsWith('/')
                                                        ? '${ApiService.baseUrl.replaceAll('/api/v1', '')}${p['imageUrl']}'
                                                        : p['imageUrl'].toString(),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Center(
                                                      child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 40),
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 40),
                                                  ),
                                          ),
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
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Details
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
                                              // Category Chip
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  categoryTag.toString(),
                                                  style: GoogleFonts.inter(
                                                    color: primaryColor,
                                                    fontSize: 7.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                pName,
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFF0F172A),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'By $wName',
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFF64748B),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
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
                                            ],
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 28,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: inCart ? const Color(0xFF16A34A) : primaryColor,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.zero,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: () {
                                                if (!inCart) {
                                                  cart.addItem(p);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Added to cart!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                                      backgroundColor: const Color(0xFF16A34A),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                } else {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => const CartScreen(isTab: false)),
                                                  );
                                                }
                                              },
                                              child: Text(
                                                inCart ? 'IN CART' : 'ADD TO CART',
                                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }
}