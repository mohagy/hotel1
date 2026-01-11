/**
 * Fix Cashier User Role
 * 
 * This script sets the cashier@gmail.com user's role to "cashier"
 * Run with: node fix_cashier_user_role.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixCashierUserRole() {
  try {
    console.log('Fixing Cashier user role...\n');
    
    // Find cashier user
    const cashierUsers = await db.collection('users')
      .where('email', '==', 'cashier@gmail.com')
      .get();
    
    if (cashierUsers.empty) {
      console.log('❌ Cashier user not found!');
      process.exit(1);
    }
    
    const cashierUser = cashierUsers.docs[0];
    const userData = cashierUser.data();
    const currentRole = userData.role;
    
    console.log(`Found user: ${userData.email}`);
    console.log(`  Current role: "${currentRole}"`);
    console.log(`  User ID: ${cashierUser.id}\n`);
    
    if (currentRole === 'cashier') {
      console.log('✅ Role is already set to "cashier"');
      process.exit(0);
    }
    
    // Update role to "cashier"
    await cashierUser.ref.update({
      role: 'cashier',
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`✅ Updated role from "${currentRole}" to "cashier"`);
    console.log('\nNext steps:');
    console.log('1. Logout and login again as cashier@gmail.com');
    console.log('2. You should now see only POS Management (if permissions are set correctly)');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixCashierUserRole();

