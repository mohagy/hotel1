/**
 * Check Current User's Role and Permissions
 * 
 * This script helps verify what role and permissions a user has
 * Run with: node check_current_user_permissions.js <email>
 * Example: node check_current_user_permissions.js admin@hotel.com
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkUserPermissions(email) {
  try {
    if (!email) {
      console.log('Usage: node check_current_user_permissions.js <email>');
      console.log('Example: node check_current_user_permissions.js admin@hotel.com\n');
      process.exit(1);
    }
    
    console.log(`Checking permissions for: ${email}\n`);
    
    // Find user
    const usersSnapshot = await db.collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();
    
    if (usersSnapshot.empty) {
      console.log(`❌ User not found: ${email}`);
      process.exit(1);
    }
    
    const userDoc = usersSnapshot.docs[0];
    const userData = userDoc.data();
    const userRole = userData.role;
    
    console.log(`✅ Found user:`);
    console.log(`   Email: ${userData.email}`);
    console.log(`   Username: ${userData.username || 'N/A'}`);
    console.log(`   Role: "${userRole}"`);
    console.log(`   Status: ${userData.status || 'N/A'}\n`);
    
    // Capitalize role name (same logic as Flutter app)
    const capitalizedRoleName = userRole && userRole.length > 0
      ? userRole[0].toUpperCase() + userRole.substring(1).toLowerCase()
      : userRole;
    
    console.log(`Looking up role: "${capitalizedRoleName}" (original: "${userRole}")\n`);
    
    // Find role
    const rolesSnapshot = await db.collection('roles')
      .where('name', '==', capitalizedRoleName)
      .limit(1)
      .get();
    
    if (rolesSnapshot.empty) {
      console.log(`❌ Role "${capitalizedRoleName}" not found in Firestore!`);
      process.exit(1);
    }
    
    const roleDoc = rolesSnapshot.docs[0];
    const roleData = roleDoc.data();
    const roleId = roleData.role_id || parseInt(roleDoc.id);
    
    console.log(`✅ Found role: "${roleData.name}" (ID: ${roleId})\n`);
    
    // Get all permissions
    const permissionsSnapshot = await db.collection('permissions').get();
    const idToPermissionKey = new Map();
    
    permissionsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.permission_id && data.key) {
        idToPermissionKey.set(data.permission_id, data.key);
      }
    });
    
    // Get role_permissions
    const rolePermsSnapshot = await db.collection('role_permissions')
      .where('role_id', '==', roleId)
      .get();
    
    console.log(`Permissions for ${capitalizedRoleName} role (${rolePermsSnapshot.size} total):\n`);
    
    const permissionKeys = [];
    rolePermsSnapshot.forEach(doc => {
      const data = doc.data();
      const permissionId = data.permission_id;
      const key = idToPermissionKey.get(permissionId);
      if (key) {
        permissionKeys.push(key);
        console.log(`  ✅ ${key}`);
      }
    });
    
    // Check key permissions
    console.log(`\n=== Key Permission Checks ===`);
    console.log(`Dashboard: ${permissionKeys.includes('dashboard.view') ? '✅' : '❌'}`);
    console.log(`Guests: ${permissionKeys.includes('guests.view') ? '✅' : '❌'}`);
    console.log(`Reservations: ${permissionKeys.includes('reservations.view') ? '✅' : '❌'}`);
    console.log(`Rooms: ${permissionKeys.includes('rooms.view') ? '✅' : '❌'}`);
    console.log(`Billing: ${permissionKeys.includes('billing.view') ? '✅' : '❌'}`);
    console.log(`POS: ${permissionKeys.includes('pos.view') ? '✅' : '❌'}`);
    console.log(`Messages: ${permissionKeys.includes('messages.view') ? '✅' : '❌'}`);
    
    console.log(`\nTotal permissions: ${permissionKeys.length}`);
    console.log(`All permissions: ${permissionKeys.join(', ')}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

const email = process.argv[2];
checkUserPermissions(email);

