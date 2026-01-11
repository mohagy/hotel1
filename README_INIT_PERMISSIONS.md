# Initialize Permissions Script

This script initializes all permissions and roles in Firestore.

## Usage

```bash
cd Flutter_hotel
node init_permissions.js
```

## What it does

1. Creates all default permissions (if they don't exist)
2. Creates all default roles (if they don't exist)
3. Assigns permissions to each role according to the permission matrix

## Roles Created

- **Owner**: All 32 permissions
- **Admin**: All 32 permissions  
- **Manager**: 23 permissions
- **Receptionist**: 14 permissions
- **Cashier**: 9 permissions
- **Staff**: 5 permissions

## After Running

1. Logout from the app
2. Login again
3. Permissions should now be loaded correctly
4. Admin users should see all menu items

## Requirements

- Node.js installed
- Firebase Admin SDK installed (`npm install firebase-admin`)
- `firebase-service-account.json` in the parent directory (root of project)

## Troubleshooting

If you get an error about the service account file:
- Make sure `firebase-service-account.json` exists in the root directory (parent of Flutter_hotel)
- Or update the path in `init_permissions.js` to point to your service account file

