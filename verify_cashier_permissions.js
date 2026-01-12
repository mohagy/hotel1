/**
 * Verify Cashier Role Permissions
 * 
 * This script shows what permissions the Cashier role currently has
 * Run with: node verify_cashier_permissions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyCashierPermissions() {
  try {
    console.log('Verifying Cashier role permissions...\n');
    
    // Find Cashier role
    const rolesSnapshot = await db.collection('roles')
      .where('name', '==', 'Cashier')
      .limit(1)
      .get();
    
    if (rolesSnapshot.empty) {
      console.log('❌ Cashier role not found!');
      process.exit(1);
    }
    
    const cashierRole = rolesSnapshot.docs[0];
    const roleId = cashierRole.data().role_id || parseInt(cashierRole.id);
    console.log(`Found Cashier role with ID: ${roleId}\n`);
    
    // Get all permissions
    const permissionsSnapshot = await db.collection('permissions').get();
    const idToPermissionKey = new Map();
    
    permissionsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.permission_id && data.key) {
        idToPermissionKey.set(data.permission_id, data.key);
      }
    });
    
    // Get role_permissions for Cashier
    const rolePermsSnapshot = await db.collection('role_permissions')
      .where('role_id', '==', roleId)
      .get();
    
    console.log(`Cashier role has ${rolePermsSnapshot.size} permissions:\n`);
    
    const permissionKeys = [];
    rolePermsSnapshot.forEach(doc => {
      const data = doc.data();
      const permissionId = data.permission_id;
      const key = idToPermissionKey.get(permissionId);
      if (key) {
        permissionKeys.push(key);
        console.log(`  - ${key} (ID: ${permissionId})`);
      } else {
        console.log(`  - Unknown permission (ID: ${permissionId})`);
      }
    });
    
    console.log(`\nTotal: ${permissionKeys.length} permissions`);
    console.log(`\nPermission keys: ${permissionKeys.join(', ')}`);
    
    // Check if Dashboard and Messages are present
    const hasDashboard = permissionKeys.includes('dashboard.view');
    const hasMessages = permissionKeys.includes('messages.view');
    const hasPOS = permissionKeys.includes('pos.view') || permissionKeys.includes('pos.sales');
    
    console.log('\n=== Summary ===');
    console.log(`Dashboard: ${hasDashboard ? '✅ YES' : '❌ NO'}`);
    console.log(`Messages: ${hasMessages ? '✅ YES' : '❌ NO'}`);
    console.log(`POS: ${hasPOS ? '✅ YES' : '❌ NO'}`);
    
    if (hasDashboard || hasMessages) {
      console.log('\n⚠️  WARNING: Cashier should NOT have Dashboard or Messages permissions!');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

verifyCashierPermissions();

