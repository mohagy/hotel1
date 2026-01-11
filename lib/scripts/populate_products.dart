/// Script to populate Firestore with hotel retail products and categories
/// 
/// Run this script using: dart run lib/scripts/populate_products.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/firebase_config.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/product_model.dart';

void main() async {
  print('Initializing Firebase...');
  await FirebaseConfig.initialize();
  print('Firebase initialized successfully\n');

  final productService = ProductService();
  final categoryService = CategoryService();

  // Hotel-specific Categories
  final categories = [
    {'name': 'Snacks & Beverages', 'description': 'Snacks, drinks, and beverages'},
    {'name': 'Toiletries & Personal Care', 'description': 'Personal care items and toiletries'},
    {'name': 'Souvenirs & Gifts', 'description': 'Hotel souvenirs and gift items'},
    {'name': 'Food & Meals', 'description': 'Ready-to-eat meals and food items'},
    {'name': 'Drinks & Alcohol', 'description': 'Alcoholic and non-alcoholic beverages'},
    {'name': 'Room Service Items', 'description': 'Room service menu items'},
    {'name': 'Electronics & Accessories', 'description': 'Electronics and accessories'},
  ];

  print('Creating categories...');
  final categoryIds = <String, int>{};
  int categoryIdCounter = 1;

  for (var categoryData in categories) {
    try {
      // Check if category already exists
      final existingCategories = await categoryService.getCategories();
      final existing = existingCategories.firstWhere(
        (c) => c['name'] == categoryData['name'],
        orElse: () => {},
      );
      
      int categoryId;
      if (existing.isNotEmpty && existing['id'] != null) {
        categoryId = existing['id'] as int;
        print('  ✓ Category already exists: ${categoryData['name']} (ID: $categoryId)');
      } else {
        final category = await categoryService.createCategory({
          'id': categoryIdCounter,
          'name': categoryData['name']!,
          'description': categoryData['description']!,
        });
        categoryId = category['id'] as int;
        print('  ✓ Created category: ${categoryData['name']} (ID: $categoryId)');
        categoryIdCounter++;
      }
      categoryIds[categoryData['name'] as String] = categoryId;
    } catch (e) {
      print('  ✗ Error creating category ${categoryData['name']}: $e');
    }
  }

  print('\nCreating products...');
  
  // Hotel Retail Products
  final products = [
    // Snacks & Beverages
    {'name': 'Bottled Water', 'price': 2.50, 'category': 'Snacks & Beverages', 'code': 'HTL-001', 'stock': 500, 'image': 'water.jpg'},
    {'name': 'Sparkling Water', 'price': 3.00, 'category': 'Snacks & Beverages', 'code': 'HTL-002', 'stock': 200, 'image': 'sparkling_water.jpg'},
    {'name': 'Coca Cola', 'price': 3.50, 'category': 'Snacks & Beverages', 'code': 'HTL-003', 'stock': 300, 'image': 'coke.jpg'},
    {'name': 'Pepsi', 'price': 3.50, 'category': 'Snacks & Beverages', 'code': 'HTL-004', 'stock': 300, 'image': 'pepsi.jpg'},
    {'name': 'Orange Juice', 'price': 4.00, 'category': 'Snacks & Beverages', 'code': 'HTL-005', 'stock': 150, 'image': 'orange_juice.jpg'},
    {'name': 'Apple Juice', 'price': 4.00, 'category': 'Snacks & Beverages', 'code': 'HTL-006', 'stock': 150, 'image': 'apple_juice.jpg'},
    {'name': 'Coffee Pods (6-pack)', 'price': 8.00, 'category': 'Snacks & Beverages', 'code': 'HTL-007', 'stock': 100, 'image': 'coffee_pods.jpg'},
    {'name': 'Tea Bags (20-pack)', 'price': 5.50, 'category': 'Snacks & Beverages', 'code': 'HTL-008', 'stock': 120, 'image': 'tea_bags.jpg'},
    {'name': 'Potato Chips', 'price': 4.50, 'category': 'Snacks & Beverages', 'code': 'HTL-009', 'stock': 200, 'image': 'chips.jpg'},
    {'name': 'Chocolate Bar', 'price': 3.50, 'category': 'Snacks & Beverages', 'code': 'HTL-010', 'stock': 250, 'image': 'chocolate.jpg'},
    {'name': 'Granola Bar', 'price': 2.75, 'category': 'Snacks & Beverages', 'code': 'HTL-011', 'stock': 180, 'image': 'granola_bar.jpg'},
    {'name': 'Mixed Nuts', 'price': 6.00, 'category': 'Snacks & Beverages', 'code': 'HTL-012', 'stock': 100, 'image': 'nuts.jpg'},
    {'name': 'Cookies (Pack)', 'price': 4.00, 'category': 'Snacks & Beverages', 'code': 'HTL-013', 'stock': 150, 'image': 'cookies.jpg'},
    
    // Toiletries & Personal Care
    {'name': 'Shampoo (Travel Size)', 'price': 5.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-101', 'stock': 200, 'image': 'shampoo.jpg'},
    {'name': 'Conditioner (Travel Size)', 'price': 5.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-102', 'stock': 200, 'image': 'conditioner.jpg'},
    {'name': 'Body Soap', 'price': 3.50, 'category': 'Toiletries & Personal Care', 'code': 'HTL-103', 'stock': 300, 'image': 'soap.jpg'},
    {'name': 'Toothpaste', 'price': 4.50, 'category': 'Toiletries & Personal Care', 'code': 'HTL-104', 'stock': 250, 'image': 'toothpaste.jpg'},
    {'name': 'Toothbrush', 'price': 3.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-105', 'stock': 300, 'image': 'toothbrush.jpg'},
    {'name': 'Razor (Disposable)', 'price': 4.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-106', 'stock': 200, 'image': 'razor.jpg'},
    {'name': 'Shaving Cream', 'price': 4.50, 'category': 'Toiletries & Personal Care', 'code': 'HTL-107', 'stock': 150, 'image': 'shaving_cream.jpg'},
    {'name': 'Body Lotion', 'price': 6.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-108', 'stock': 180, 'image': 'lotion.jpg'},
    {'name': 'Deodorant', 'price': 5.50, 'category': 'Toiletries & Personal Care', 'code': 'HTL-109', 'stock': 200, 'image': 'deodorant.jpg'},
    {'name': 'Sunscreen SPF 50', 'price': 8.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-110', 'stock': 120, 'image': 'sunscreen.jpg'},
    {'name': 'Sanitizer (Small)', 'price': 3.00, 'category': 'Toiletries & Personal Care', 'code': 'HTL-111', 'stock': 250, 'image': 'sanitizer.jpg'},
    
    // Souvenirs & Gifts
    {'name': 'Hotel Keychain', 'price': 4.50, 'category': 'Souvenirs & Gifts', 'code': 'HTL-201', 'stock': 150, 'image': 'keychain.jpg'},
    {'name': 'Hotel Coffee Mug', 'price': 12.00, 'category': 'Souvenirs & Gifts', 'code': 'HTL-202', 'stock': 100, 'image': 'mug.jpg'},
    {'name': 'Hotel T-Shirt', 'price': 25.00, 'category': 'Souvenirs & Gifts', 'code': 'HTL-203', 'stock': 80, 'image': 'tshirt.jpg'},
    {'name': 'Hotel Cap', 'price': 15.00, 'category': 'Souvenirs & Gifts', 'code': 'HTL-204', 'stock': 60, 'image': 'cap.jpg'},
    {'name': 'Postcards (Set of 5)', 'price': 3.00, 'category': 'Souvenirs & Gifts', 'code': 'HTL-205', 'stock': 200, 'image': 'postcards.jpg'},
    {'name': 'Local Map', 'price': 2.50, 'category': 'Souvenirs & Gifts', 'code': 'HTL-206', 'stock': 100, 'image': 'map.jpg'},
    {'name': 'Puzzle (Local Theme)', 'price': 18.00, 'category': 'Souvenirs & Gifts', 'code': 'HTL-207', 'stock': 40, 'image': 'puzzle.jpg'},
    {'name': 'Magnets (Set of 3)', 'price': 6.50, 'category': 'Souvenirs & Gifts', 'code': 'HTL-208', 'stock': 120, 'image': 'magnets.jpg'},
    
    // Food & Meals
    {'name': 'Club Sandwich', 'price': 12.00, 'category': 'Food & Meals', 'code': 'HTL-301', 'stock': 50, 'image': 'club_sandwich.jpg'},
    {'name': 'Caesar Salad', 'price': 10.00, 'category': 'Food & Meals', 'code': 'HTL-302', 'stock': 40, 'image': 'caesar_salad.jpg'},
    {'name': 'Pizza Slice', 'price': 8.50, 'category': 'Food & Meals', 'code': 'HTL-303', 'stock': 60, 'image': 'pizza_slice.jpg'},
    {'name': 'Chicken Burger', 'price': 11.00, 'category': 'Food & Meals', 'code': 'HTL-304', 'stock': 50, 'image': 'chicken_burger.jpg'},
    {'name': 'Fruit Bowl', 'price': 7.00, 'category': 'Food & Meals', 'code': 'HTL-305', 'stock': 30, 'image': 'fruit_bowl.jpg'},
    {'name': 'Yogurt Parfait', 'price': 6.50, 'category': 'Food & Meals', 'code': 'HTL-306', 'stock': 40, 'image': 'yogurt.jpg'},
    {'name': 'Breakfast Sandwich', 'price': 9.00, 'category': 'Food & Meals', 'code': 'HTL-307', 'stock': 45, 'image': 'breakfast_sandwich.jpg'},
    {'name': 'Soup of the Day', 'price': 8.00, 'category': 'Food & Meals', 'code': 'HTL-308', 'stock': 35, 'image': 'soup.jpg'},
    
    // Drinks & Alcohol
    {'name': 'Beer (Local)', 'price': 6.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-401', 'stock': 200, 'image': 'beer.jpg'},
    {'name': 'Wine (Red, Bottle)', 'price': 25.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-402', 'stock': 80, 'image': 'wine_red.jpg'},
    {'name': 'Wine (White, Bottle)', 'price': 25.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-403', 'stock': 80, 'image': 'wine_white.jpg'},
    {'name': 'Champagne (Mini)', 'price': 15.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-404', 'stock': 60, 'image': 'champagne.jpg'},
    {'name': 'Cocktail (House)', 'price': 12.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-405', 'stock': 100, 'image': 'cocktail.jpg'},
    {'name': 'Whiskey (Shot)', 'price': 8.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-406', 'stock': 150, 'image': 'whiskey.jpg'},
    {'name': 'Vodka (Shot)', 'price': 8.00, 'category': 'Drinks & Alcohol', 'code': 'HTL-407', 'stock': 150, 'image': 'vodka.jpg'},
    
    // Room Service Items
    {'name': 'Room Service Breakfast', 'price': 18.00, 'category': 'Room Service Items', 'code': 'HTL-501', 'stock': 999, 'image': 'room_service_breakfast.jpg'},
    {'name': 'Room Service Lunch', 'price': 22.00, 'category': 'Room Service Items', 'code': 'HTL-502', 'stock': 999, 'image': 'room_service_lunch.jpg'},
    {'name': 'Room Service Dinner', 'price': 28.00, 'category': 'Room Service Items', 'code': 'HTL-503', 'stock': 999, 'image': 'room_service_dinner.jpg'},
    {'name': 'Midnight Snack Pack', 'price': 15.00, 'category': 'Room Service Items', 'code': 'HTL-504', 'stock': 999, 'image': 'midnight_snack.jpg'},
    {'name': 'Late Night Pizza', 'price': 16.00, 'category': 'Room Service Items', 'code': 'HTL-505', 'stock': 999, 'image': 'late_night_pizza.jpg'},
    
    // Electronics & Accessories
    {'name': 'Phone Charger (Universal)', 'price': 12.00, 'category': 'Electronics & Accessories', 'code': 'HTL-601', 'stock': 100, 'image': 'charger.jpg'},
    {'name': 'USB Cable', 'price': 8.00, 'category': 'Electronics & Accessories', 'code': 'HTL-602', 'stock': 150, 'image': 'usb_cable.jpg'},
    {'name': 'Headphones (Basic)', 'price': 15.00, 'category': 'Electronics & Accessories', 'code': 'HTL-603', 'stock': 80, 'image': 'headphones.jpg'},
    {'name': 'Power Bank', 'price': 25.00, 'category': 'Electronics & Accessories', 'code': 'HTL-604', 'stock': 60, 'image': 'power_bank.jpg'},
    {'name': 'Travel Adapter', 'price': 10.00, 'category': 'Electronics & Accessories', 'code': 'HTL-605', 'stock': 90, 'image': 'adapter.jpg'},
  ];

  int productIdCounter = 1;
  int added = 0;
  int errors = 0;

  for (var productData in products) {
    try {
      final categoryId = categoryIds[productData['category'] as String];
      if (categoryId == null) {
        print('  ✗ Category not found: ${productData['category']}');
        errors++;
        continue;
      }

      final product = ProductModel(
        id: productIdCounter,
        name: productData['name'] as String,
        price: (productData['price'] as num).toDouble(),
        imageUrl: productData['image'] as String,
        categoryId: categoryId,
        upc: productData['code'] as String,
        stock: productData['stock'] as int,
        isAvailable: true,
      );

      await productService.createProduct(product);
      print('  ✓ Added: ${productData['name']} (${productData['code']}) - \$${productData['price']}');
      added++;
      productIdCounter++;
    } catch (e) {
      print('  ✗ Error adding ${productData['name']}: $e');
      errors++;
    }
  }

  print('\n=== Summary ===');
  print('Categories created: ${categories.length}');
  print('Products added: $added');
  print('Errors: $errors');
  print('\nDone!');
}

