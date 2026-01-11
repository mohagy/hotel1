/**
 * Create Restaurant Products in Firestore
 * 
 * This script creates restaurant menu items (with is_restaurant_item: 1)
 * Run with: node create_restaurant_products.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createRestaurantProducts() {
  try {
    console.log('Creating restaurant products in Firestore...\n');
    
    // First, get or create restaurant categories
    console.log('Step 1: Creating restaurant categories...');
    const restaurantCategories = [
      { name: 'Appetizers', description: 'Starters and appetizers' },
      { name: 'Main Course', description: 'Main dishes' },
      { name: 'Desserts', description: 'Desserts and sweets' },
      { name: 'Beverages', description: 'Drinks and beverages' },
    ];
    
    const categoryIds = {};
    let categoryIdCounter = 100; // Start from 100 to avoid conflicts with retail categories
    
    for (const catData of restaurantCategories) {
      try {
        // Check if category exists
        const existingQuery = await db.collection('categories')
          .where('name', '==', catData.name)
          .limit(1)
          .get();
        
        let categoryId;
        if (!existingQuery.empty) {
          categoryId = parseInt(existingQuery.docs[0].id);
          console.log(`  ✓ Category "${catData.name}" already exists (ID: ${categoryId})`);
        } else {
          categoryId = categoryIdCounter++;
          await db.collection('categories').doc(categoryId.toString()).set({
            name: catData.name,
            description: catData.description,
            product_count: 0,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`  ✓ Created category "${catData.name}" (ID: ${categoryId})`);
        }
        categoryIds[catData.name] = categoryId;
      } catch (error) {
        console.error(`  ✗ Error with category ${catData.name}:`, error.message);
      }
    }
    
    console.log(`\nTotal categories: ${Object.keys(categoryIds).length}\n`);
    
    // Restaurant menu items
    console.log('Step 2: Creating restaurant products...');
    const restaurantProducts = [
      // Appetizers
      { name: 'Bruschetta', price: 8.99, category: 'Appetizers', description: 'Toasted bread with tomatoes and basil' },
      { name: 'Calamari Fritti', price: 12.99, category: 'Appetizers', description: 'Fried calamari rings' },
      { name: 'Shrimp Cocktail', price: 14.99, category: 'Appetizers', description: 'Chilled shrimp with cocktail sauce' },
      { name: 'Caesar Salad', price: 10.99, category: 'Appetizers', description: 'Classic Caesar salad' },
      
      // Main Course
      { name: 'Filet Mignon', price: 35.99, category: 'Main Course', description: 'Prime beef filet, cooked to perfection' },
      { name: 'Grilled Salmon', price: 28.99, category: 'Main Course', description: 'Fresh grilled salmon with herbs' },
      { name: 'Pasta Carbonara', price: 18.99, category: 'Main Course', description: 'Creamy pasta with bacon and eggs' },
      { name: 'Vegetable Risotto', price: 16.99, category: 'Main Course', description: 'Creamy risotto with seasonal vegetables' },
      { name: 'Chicken Burger', price: 14.99, category: 'Main Course', description: 'Grilled chicken burger with fries' },
      { name: 'Club Sandwich', price: 12.99, category: 'Main Course', description: 'Triple-decker club sandwich' },
      
      // Desserts
      { name: 'Chocolate Lava Cake', price: 9.99, category: 'Desserts', description: 'Warm chocolate cake with molten center' },
      { name: 'Panna Cotta', price: 8.99, category: 'Desserts', description: 'Italian cream dessert with berry sauce' },
      { name: 'Tiramisu', price: 8.99, category: 'Desserts', description: 'Classic Italian tiramisu' },
      { name: 'Cheesecake', price: 9.99, category: 'Desserts', description: 'New York style cheesecake' },
      
      // Beverages
      { name: 'House Wine (Glass)', price: 8.99, category: 'Beverages', description: 'House wine selection' },
      { name: 'Cocktail (House)', price: 12.99, category: 'Beverages', description: 'House special cocktail' },
      { name: 'Fresh Juice', price: 6.99, category: 'Beverages', description: 'Fresh squeezed juice' },
      { name: 'Espresso', price: 3.99, category: 'Beverages', description: 'Single shot espresso' },
      { name: 'Cappuccino', price: 4.99, category: 'Beverages', description: 'Italian cappuccino' },
    ];
    
    let productIdCounter = 1000; // Start from 1000 to avoid conflicts
    let createdCount = 0;
    let skippedCount = 0;
    
    for (const productData of restaurantProducts) {
      try {
        const categoryId = categoryIds[productData.category];
        if (!categoryId) {
          console.log(`  ✗ Category not found: ${productData.category}`);
          continue;
        }
        
        // Check if product exists by name
        const existingQuery = await db.collection('products')
          .where('name', '==', productData.name)
          .limit(1)
          .get();
        
        let productId;
        if (!existingQuery.empty) {
          // Update existing product to be restaurant item
          const existingDoc = existingQuery.docs[0];
          productId = parseInt(existingDoc.id);
          await existingDoc.ref.update({
            is_restaurant_item: 1,
            category_id: categoryId,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`  ✓ Updated product "${productData.name}" to restaurant item (ID: ${productId})`);
        } else {
          // Get next available product ID
          const allProducts = await db.collection('products').get();
          const existingIds = allProducts.docs.map(doc => parseInt(doc.id)).filter(id => !isNaN(id));
          productId = existingIds.length > 0 ? Math.max(...existingIds) + 1 : productIdCounter++;
          
          await db.collection('products').doc(productId.toString()).set({
            name: productData.name,
            price: productData.price,
            description: productData.description || '',
            category_id: categoryId,
            is_restaurant_item: 1, // IMPORTANT: This marks it as a restaurant item
            is_available: 1,
            stock: 999, // Restaurant items typically don't have stock limits
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`  ✓ Created restaurant product "${productData.name}" (ID: ${productId}) - $${productData.price}`);
        }
        createdCount++;
      } catch (error) {
        console.error(`  ✗ Error with product ${productData.name}:`, error.message);
      }
    }
    
    console.log(`\n✅ Created/Updated ${createdCount} restaurant products`);
    console.log('\n✅ Restaurant products creation complete!');
    console.log('\nNext steps:');
    console.log('1. Refresh your app (F5)');
    console.log('2. Go to Restaurant mode - you should now see restaurant products and categories');
    console.log('3. Go to Retail mode - you should see retail products');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createRestaurantProducts();

