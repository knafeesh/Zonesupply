export interface CategoryItem {
  name: string;
  subcategories: string[];
}

export const PRODUCT_CATEGORIES: CategoryItem[] = [
  {
    name: 'Grocery',
    subcategories: [
      'Cold Drinks & Soft Drinks',
      'Fruit Juices & Energy Drinks',
      'Atta & Flours',
      'Basmati Rice',
      'Edible Oils & Ghee',
      'Spices & Masalas',
      'Chips & Snacks',
      'Biscuits & Cookies',
      'Tea & Coffee',
    ],
  },
  {
    name: 'Rice, Atta & Dals',
    subcategories: [
      'Wheat Flour (Atta)',
      'Basmati & Rice',
      'Dals & Pulses',
      'Poha, Suji & Maida',
    ],
  },
  {
    name: 'Oil, Sugar & Masalas',
    subcategories: [
      'Edible Oils & Ghee',
      'Spices & Masalas',
      'Sugar & Salt',
    ],
  },
  {
    name: 'Packaged Foods & Dry Fruits',
    subcategories: [
      'Biscuits & Cookies',
      'Noodles & Pasta',
      'Chips & Snacks',
      'Dry Fruits & Nuts',
    ],
  },
  {
    name: 'Beverages',
    subcategories: [
      'Soft Drinks',
      'Cold Drinks',
      'Juices & Mango',
      'Energy Drinks',
      'Tea & Coffee',
      'Packaged Water',
    ],
  },
  {
    name: 'Dairy, Fresh & Frozen',
    subcategories: [
      'Milk & Butter',
      'Paneer & Cheese',
      'Frozen Snacks',
    ],
  },
  {
    name: 'Personal Care',
    subcategories: [
      'Skin & Face Care',
      'Hair Care & Oils',
      'Bath & Soap',
      'Oral Care',
      'Shaving & Grooming',
      'Perfumes & Deos',
    ],
  },
  {
    name: 'Home Care',
    subcategories: [
      'Laundry',
      'House & Kitchen Cleaning',
      'Home Utilities',
      'Air & Car Fresheners',
      'Shoe Care',
      'Pooja Needs',
      'Pet Care',
    ],
  },
  {
    name: 'Health & OTC',
    subcategories: [
      'Pain Relief & Balms',
      'Cold & Cough Care',
    ],
  },
  {
    name: 'IT, Stationery & Office Furniture',
    subcategories: [
      'Notebooks & Registers',
      'Pens & Stationery',
    ],
  },
  {
    name: 'Kitchen & Home Appliances',
    subcategories: [
      'Mixers & Grinders',
      'Kettles & Toasters',
    ],
  },
  {
    name: 'Fashion',
    subcategories: [
      'Fancy Saree',
      'Chiffon',
      'Suit-Unstitched',
      'Georgette',
      'Lehenga',
      'Gowns',
      'Kurti / Set',
      "Men's Wear",
    ],
  },
  {
    name: 'Luggage & Apparel',
    subcategories: [
      'Suitcases & Trolleys',
      'Backpacks & Bags',
    ],
  },
  {
    name: 'Restaurant Supplies & Houseware',
    subcategories: [
      'Plates & Crockery',
      'Tissues & Napkins',
    ],
  },
  {
    name: 'Electronics',
    subcategories: [
      'Smart TVs & Audio',
      'Smartphones',
    ],
  },
  {
    name: 'Sports',
    subcategories: [
      'Cricket Equipment',
      'Fitness & Gym',
    ],
  },
  {
    name: 'Hardware',
    subcategories: [
      'Power Tools',
      'Hand Tools',
    ],
  },
];

// Flat category names list for simple dropdowns
export const ALL_CATEGORY_NAMES: string[] = PRODUCT_CATEGORIES.map((c) => c.name);

// All Category + Subcategory combined options (e.g., "Grocery > Atta & Flours")
export const ALL_CATEGORY_PATHS: string[] = PRODUCT_CATEGORIES.flatMap((c) => [
  c.name,
  ...c.subcategories.map((sub) => `${c.name} > ${sub}`),
]);
