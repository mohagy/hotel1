/**
 * Check User Role in Firestore
 * 
 * This script checks what role a user has in Firestore
 * Run with: node check_user_role.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkUserRole() {
  try {
    console.log('Checking user roles in Firestore...\n');
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    
    console.log(`Found ${usersSnapshot.size} users:\n`);
    
    usersSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`Email: ${data.email || 'N/A'}`);
      console.log(`  User ID: ${doc.id}`);
      console.log(`  Role: "${data.role}"`);
      console.log(`  Username: ${data.username || 'N/A'}`);
      console.log(`  Status: ${data.status || 'N/A'}`);
      console.log('');
    });
    
    // Check for cashier user specifically
    const cashierUsers = await db.collection('users')
      .where('email', '==', 'cashier@gmail.com')
      .get();
    
    if (!cashierUsers.empty) {
      console.log('=== Cashier User Details ===\n');
      cashierUsers.forEach(doc => {
        const data = doc.data();
        console.log(`Email: ${data.email}`);
        console.log(`  User ID: ${doc.id}`);
        console.log(`  Role: "${data.role}"`);
        console.log(`  Expected: "cashier"`);
        if (data.role !== 'cashier') {
          console.log(`  ⚠️  WARNING: Role is "${data.role}" but should be "cashier"!`);
        }
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkUserRole();

