/**
 * Initialize Permissions and Roles in Firestore
 * 
 * This script initializes all permissions and assigns them to roles
 * Run with: node init_permissions.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Default permissions based on permissions_init_service.dart
const defaultPermissions = [
  // Dashboard
  { name: 'View Dashboard', key: 'dashboard.view', category: 'dashboard', description: 'View the main dashboard' },
  
  // Guests
  { name: 'View Guests', key: 'guests.view', category: 'guests', description: 'View guest list and details' },
  { name: 'Create Guests', key: 'guests.create', category: 'guests', description: 'Create new guest records' },
  { name: 'Edit Guests', key: 'guests.edit', category: 'guests', description: 'Edit existing guest records' },
  { name: 'Delete Guests', key: 'guests.delete', category: 'guests', description: 'Delete guest records' },
  
  // Rooms
  { name: 'View Rooms', key: 'rooms.view', category: 'rooms', description: 'View room list and details' },
  { name: 'Create Rooms', key: 'rooms.create', category: 'rooms', description: 'Create new room records' },
  { name: 'Edit Rooms', key: 'rooms.edit', category: 'rooms', description: 'Edit existing room records' },
  { name: 'Delete Rooms', key: 'rooms.delete', category: 'rooms', description: 'Delete room records' },
  
  // Reservations
  { name: 'View Reservations', key: 'reservations.view', category: 'reservations', description: 'View reservation list and details' },
  { name: 'Create Reservations', key: 'reservations.create', category: 'reservations', description: 'Create new reservations' },
  { name: 'Edit Reservations', key: 'reservations.edit', category: 'reservations', description: 'Edit existing reservations' },
  { name: 'Check-in Reservations', key: 'reservations.checkin', category: 'reservations', description: 'Check-in guests' },
  { name: 'Check-out Reservations', key: 'reservations.checkout', category: 'reservations', description: 'Check-out guests' },
  { name: 'Cancel Reservations', key: 'reservations.cancel', category: 'reservations', description: 'Cancel reservations' },
  
  // Billing
  { name: 'View Billing', key: 'billing.view', category: 'billing', description: 'View billing records' },
  { name: 'Create Billing', key: 'billing.create', category: 'billing', description: 'Create billing records' },
  { name: 'Edit Billing', key: 'billing.edit', category: 'billing', description: 'Edit billing records' },
  { name: 'Process Payments', key: 'billing.payment', category: 'billing', description: 'Process payments' },
  
  // POS
  { name: 'View POS', key: 'pos.view', category: 'pos', description: 'Access POS system' },
  { name: 'POS Sales', key: 'pos.sales', category: 'pos', description: 'Process POS sales' },
  { name: 'Manage POS Products', key: 'pos.products', category: 'pos', description: 'Manage POS products' },
  
  // Reports
  { name: 'View Reports', key: 'reports.view', category: 'reports', description: 'View reports' },
  { name: 'Export Reports', key: 'reports.export', category: 'reports', description: 'Export reports' },
  
  // Messages
  { name: 'View Messages', key: 'messages.view', category: 'messages', description: 'View messages' },
  
  // Users
  { name: 'View Users', key: 'users.view', category: 'users', description: 'View user list' },
  { name: 'Create Users', key: 'users.create', category: 'users', description: 'Create new users' },
  { name: 'Edit Users', key: 'users.edit', category: 'users', description: 'Edit users' },
  { name: 'Delete Users', key: 'users.delete', category: 'users', description: 'Delete users' },
  
  // Roles
  { name: 'Manage Roles', key: 'roles.manage', category: 'roles', description: 'Manage roles and permissions' },
  
  // Settings
  { name: 'View Settings', key: 'settings.view', category: 'settings', description: 'View settings' },
  { name: 'Edit Settings', key: 'settings.edit', category: 'settings', description: 'Edit settings' },
];

// Default roles with their permissions (based on permissions_init_service.dart)
const defaultRolesPermissions = {
  'Owner': [
    'dashboard.view',
    'guests.view', 'guests.create', 'guests.edit', 'guests.delete',
    'rooms.view', 'rooms.create', 'rooms.edit', 'rooms.delete',
    'reservations.view', 'reservations.create', 'reservations.edit',
    'reservations.checkin', 'reservations.checkout', 'reservations.cancel',
    'billing.view', 'billing.create', 'billing.edit', 'billing.payment',
    'pos.view', 'pos.sales', 'pos.products',
    'reports.view', 'reports.export',
    'messages.view',
    'users.view', 'users.create', 'users.edit', 'users.delete', 'roles.manage',
    'settings.view', 'settings.edit',
  ],
  'Admin': [
    'dashboard.view',
    'guests.view', 'guests.create', 'guests.edit', 'guests.delete',
    'rooms.view', 'rooms.create', 'rooms.edit', 'rooms.delete',
    'reservations.view', 'reservations.create', 'reservations.edit',
    'reservations.checkin', 'reservations.checkout', 'reservations.cancel',
    'billing.view', 'billing.create', 'billing.edit', 'billing.payment',
    'pos.view', 'pos.sales', 'pos.products',
    'reports.view', 'reports.export',
    'messages.view',
    'users.view', 'users.create', 'users.edit', 'users.delete', 'roles.manage',
    'settings.view', 'settings.edit',
  ],
  'Manager': [
    'dashboard.view',
    'guests.view', 'guests.create', 'guests.edit',
    'rooms.view', 'rooms.create', 'rooms.edit',
    'reservations.view', 'reservations.create', 'reservations.edit',
    'reservations.checkin', 'reservations.checkout',
    'billing.view', 'billing.create', 'billing.edit', 'billing.payment',
    'pos.view', 'pos.sales',
    'reports.view', 'reports.export',
    'messages.view',
    'users.view',
    'settings.view',
  ],
  'Receptionist': [
    'dashboard.view',
    'guests.view', 'guests.create', 'guests.edit',
    'rooms.view',
    'reservations.view', 'reservations.create', 'reservations.edit',
    'reservations.checkin', 'reservations.checkout',
    'billing.view', 'billing.create', 'billing.payment',
    'messages.view',
  ],
  'Cashier': [
    'dashboard.view',
    'pos.view', 'pos.sales',
    'messages.view',
  ],
  'Staff': [
    'dashboard.view',
    'guests.view',
    'rooms.view',
    'reservations.view',
    'messages.view',
  ],
};

async function initializePermissions() {
  console.log('Initializing permissions...');
  
  // Get existing permissions to create a map of key to permission_id
  const existingPermsSnapshot = await db.collection('permissions').get();
  const keyToPermissionId = new Map();
  
  existingPermsSnapshot.forEach(doc => {
    const data = doc.data();
    if (data.key && data.permission_id) {
      keyToPermissionId.set(data.key, data.permission_id);
    }
  });
  
  // Create or update permissions
  let nextPermissionId = 1;
  if (existingPermsSnapshot.size > 0) {
    const ids = [];
    existingPermsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.permission_id) {
        ids.push(data.permission_id);
      }
    });
    nextPermissionId = Math.max(...ids) + 1;
  }
  
  for (const perm of defaultPermissions) {
    if (!keyToPermissionId.has(perm.key)) {
      // Create new permission
      const docRef = db.collection('permissions').doc(nextPermissionId.toString());
      await docRef.set({
        permission_id: nextPermissionId,
        name: perm.name,
        key: perm.key,
        category: perm.category,
        description: perm.description,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      keyToPermissionId.set(perm.key, nextPermissionId);
      console.log(`Created permission: ${perm.key} (ID: ${nextPermissionId})`);
      nextPermissionId++;
    } else {
      console.log(`Permission already exists: ${perm.key}`);
    }
  }
  
  console.log(`\nTotal permissions: ${keyToPermissionId.size}`);
  return keyToPermissionId;
}

async function initializeRoles(permissionKeyToId) {
  console.log('\nInitializing roles...');
  
  // Get existing roles
  const existingRolesSnapshot = await db.collection('roles').get();
  const nameToRole = new Map();
  
  existingRolesSnapshot.forEach(doc => {
    const data = doc.data();
    const roleId = data.role_id || parseInt(doc.id);
    nameToRole.set(data.name, { roleId, docId: doc.id });
  });
  
  // Get next role_id
  let nextRoleId = 1;
  if (existingRolesSnapshot.size > 0) {
    const ids = [];
    existingRolesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.role_id) {
        ids.push(data.role_id);
      }
    });
    if (ids.length > 0) {
      nextRoleId = Math.max(...ids) + 1;
    }
  }
  
  // Create or update roles and assign permissions
  for (const [roleName, permissionKeys] of Object.entries(defaultRolesPermissions)) {
    let roleId;
    let roleDocId;
    
    if (nameToRole.has(roleName)) {
      // Role exists
      const role = nameToRole.get(roleName);
      roleId = role.roleId;
      roleDocId = role.docId;
      console.log(`\nRole exists: ${roleName} (ID: ${roleId})`);
    } else {
      // Create new role
      roleDocId = nextRoleId.toString();
      roleId = nextRoleId;
      const docRef = db.collection('roles').doc(roleDocId);
      await docRef.set({
        role_id: roleId,
        name: roleName,
        description: `Default ${roleName} role`,
        is_system_role: true,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`\nCreated role: ${roleName} (ID: ${roleId})`);
      nextRoleId++;
    }
    
    // Delete existing role_permissions for this role
    const existingRolePerms = await db.collection('role_permissions')
      .where('role_id', '==', roleId)
      .get();
    
    const batch = db.batch();
    existingRolePerms.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log(`  Deleted ${existingRolePerms.size} existing permission assignments`);
    
    // Assign permissions to role
    const permissionIds = permissionKeys
      .map(key => permissionKeyToId.get(key))
      .filter(id => id !== undefined);
    
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
    console.log(`  Assigned ${permissionIds.length} permissions to ${roleName}`);
  }
  
  console.log('\nRoles initialization complete!');
}

async function main() {
  try {
    console.log('Starting permissions and roles initialization...\n');
    
    const permissionKeyToId = await initializePermissions();
    await initializeRoles(permissionKeyToId);
    
    console.log('\n✅ Initialization complete!');
    console.log('\nNext steps:');
    console.log('1. Logout and login again in the app');
    console.log('2. You should now see all menu items for Admin role');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();

