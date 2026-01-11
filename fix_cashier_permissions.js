/**
 * Fix Cashier Role Permissions - Only POS Access
 * 
 * This script updates the Cashier role to only have POS permissions
 * Run with: node fix_cashier_permissions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixCashierPermissions() {
  try {
    console.log('Fixing Cashier role permissions...\n');
    
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
    
    // Get permission IDs for the permissions we want
    const desiredPermissions = ['dashboard.view', 'pos.view', 'pos.sales', 'messages.view'];
    
    const permissionsSnapshot = await db.collection('permissions').get();
    const keyToPermissionId = new Map();
    
    permissionsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.key && data.permission_id) {
        keyToPermissionId.set(data.key, data.permission_id);
      }
    });
    
    const permissionIds = desiredPermissions
      .map(key => keyToPermissionId.get(key))
      .filter(id => id !== undefined);
    
    console.log(`Desired permissions: ${desiredPermissions.join(', ')}`);
    console.log(`Permission IDs: ${permissionIds.join(', ')}\n`);
    
    // Delete existing role_permissions for Cashier
    const existingRolePerms = await db.collection('role_permissions')
      .where('role_id', '==', roleId)
      .get();
    
    const batch = db.batch();
    existingRolePerms.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`Deleted ${existingRolePerms.size} existing permission assignments\n`);
    
    // Assign new permissions
    const rolePermBatch = db.batch();
    for (const permissionId of permissionIds) {
      const docRef = db.collection('role_permissions').doc();
      rolePermBatch.set(docRef, {
        role_id: roleId,
        permission_id: permissionId,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await rolePermBatch.commit();
    console.log(`✅ Assigned ${permissionIds.length} permissions to Cashier role:`);
    permissionIds.forEach((id, index) => {
      console.log(`   - ${desiredPermissions[index]} (ID: ${id})`);
    });
    
    console.log('\n✅ Cashier permissions updated successfully!');
    console.log('\nNext steps:');
    console.log('1. Logout and login again as Cashier user');
    console.log('2. You should now only see: Dashboard, POS Management, Messages');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixCashierPermissions();

