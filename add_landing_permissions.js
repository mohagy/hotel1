/**
 * Add Landing Page Permissions to Existing Roles
 * 
 * This script adds landing page permissions to existing roles in Firestore
 * Run with: node add_landing_permissions.js
 * 
 * This is useful if you already have roles set up and want to add the new
 * landing page permissions without reinitializing all permissions.
 */

const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Landing page permissions to add
const landingPermissions = ['landing.view', 'landing.manage'];

// Roles that should get landing page permissions
const rolesToUpdate = ['Owner', 'Admin', 'Manager'];

async function addLandingPermissions() {
  console.log('Adding landing page permissions to existing roles...\n');
  
  try {
    // First, ensure the permissions exist
    console.log('1. Checking/creating landing page permissions...');
    const permissionsToCreate = [
      { name: 'View Landing Page', key: 'landing.view', category: 'landing', description: 'View the public landing page' },
      { name: 'Manage Landing Page', key: 'landing.manage', category: 'landing', description: 'Manage landing page content, media, and settings' },
    ];
    
    for (const perm of permissionsToCreate) {
      const existingPerms = await db.collection('permissions')
        .where('key', '==', perm.key)
        .limit(1)
        .get();
      
      if (existingPerms.empty) {
        // Get the next permission_id
        const allPerms = await db.collection('permissions').get();
        let maxId = 0;
        allPerms.forEach(doc => {
          const data = doc.data();
          if (data.permission_id && data.permission_id > maxId) {
            maxId = data.permission_id;
          }
        });
        
        await db.collection('permissions').add({
          ...perm,
          permission_id: maxId + 1,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`   ✓ Created permission: ${perm.key}`);
      } else {
        console.log(`   ✓ Permission already exists: ${perm.key}`);
      }
    }
    
    // Get permission IDs
    const permIds = {};
    for (const key of landingPermissions) {
      const permDocs = await db.collection('permissions')
        .where('key', '==', key)
        .limit(1)
        .get();
      
      if (!permDocs.empty) {
        permIds[key] = permDocs.docs[0].data().permission_id;
      }
    }
    
    console.log('\n2. Updating roles...');
    
    // Update each role
    for (const roleName of rolesToUpdate) {
      console.log(`\n   Processing role: ${roleName}`);
      
      // Find role by name
      const roleQuery = await db.collection('roles')
        .where('name', '==', roleName)
        .limit(1)
        .get();
      
      if (roleQuery.empty) {
        console.log(`   ⚠️  Role "${roleName}" not found. Skipping...`);
        continue;
      }
      
      const roleDoc = roleQuery.docs[0];
      const roleData = roleDoc.data();
      const currentPermissions = roleData.permissions || [];
      
      // Check which permissions need to be added
      const permissionsToAdd = [];
      for (const key of landingPermissions) {
        if (!currentPermissions.includes(key)) {
          permissionsToAdd.push(key);
        }
      }
      
      if (permissionsToAdd.length === 0) {
        console.log(`   ✓ Role "${roleName}" already has all landing page permissions`);
        continue;
      }
      
      // Add new permissions
      const updatedPermissions = [...currentPermissions, ...permissionsToAdd];
      
      await roleDoc.ref.update({
        permissions: updatedPermissions,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`   ✓ Added permissions to "${roleName}": ${permissionsToAdd.join(', ')}`);
      console.log(`   ✓ Total permissions for "${roleName}": ${updatedPermissions.length}`);
    }
    
    console.log('\n✅ Successfully added landing page permissions to roles!');
    console.log('\nNote: Users may need to log out and log back in for permission changes to take effect.');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Run the script
addLandingPermissions()
  .then(() => {
    console.log('\nScript completed successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(1);
  });

