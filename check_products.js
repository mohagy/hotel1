/**
 * Check Products in Firestore
 * 
 * This script shows products and their mode/type fields
 * Run with: node check_products.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProducts() {
  try {
    console.log('Checking products in Firestore...\n');
    
    // Get first 10 products to see structure
    const productsSnapshot = await db.collection('products')
      .limit(10)
      .get();
    
    console.log(`Found ${productsSnapshot.size} products (showing first 10):\n`);
    
    if (productsSnapshot.empty) {
      console.log('No products found!');
      process.exit(0);
    }
    
    // Check what fields products have
    const sampleProduct = productsSnapshot.docs[0].data();
    console.log('Sample product fields:');
    console.log(Object.keys(sampleProduct).join(', '));
    console.log('\nSample product data:');
    console.log(JSON.stringify(sampleProduct, null, 2));
    console.log('\n');
    
    // Count by mode/type if it exists
    const allProducts = await db.collection('products').get();
    const modeCounts = {};
    const typeCounts = {};
    
    allProducts.forEach(doc => {
      const data = doc.data();
      if (data.mode) {
        modeCounts[data.mode] = (modeCounts[data.mode] || 0) + 1;
      }
      if (data.type) {
        typeCounts[data.type] = (typeCounts[data.type] || 0) + 1;
      }
      if (data.business_mode) {
        modeCounts[data.business_mode] = (modeCounts[data.business_mode] || 0) + 1;
      }
    });
    
    if (Object.keys(modeCounts).length > 0) {
      console.log('Products by mode/business_mode:');
      Object.entries(modeCounts).forEach(([mode, count]) => {
        console.log(`  ${mode}: ${count}`);
      });
    }
    
    if (Object.keys(typeCounts).length > 0) {
      console.log('\nProducts by type:');
      Object.entries(typeCounts).forEach(([type, count]) => {
        console.log(`  ${type}: ${count}`);
      });
    }
    
    // Check categories
    console.log('\n--- Categories ---\n');
    const categoriesSnapshot = await db.collection('categories').limit(10).get();
    console.log(`Found ${categoriesSnapshot.size} categories (showing first 10):\n`);
    
    if (!categoriesSnapshot.empty) {
      const sampleCategory = categoriesSnapshot.docs[0].data();
      console.log('Sample category fields:');
      console.log(Object.keys(sampleCategory).join(', '));
      console.log('\nSample category data:');
      console.log(JSON.stringify(sampleCategory, null, 2));
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkProducts();

