# Permission Caching Explanation

## How Permissions Work

1. **Permissions are saved to Firestore** - When you update permissions in the UI, they ARE saved correctly to the database
2. **Permissions are cached** - For performance, permissions are cached in the app
3. **Cache is cleared on logout/login** - Users need to logout and login again to see permission changes

## Why You're Seeing Old Permissions

When you update permissions in the permission matrix UI:
- ✅ The changes ARE saved to Firestore correctly
- ❌ BUT users who are currently logged in have cached permissions
- ❌ They won't see the changes until they logout and login again

## Solution

### After Updating Permissions in the UI:

1. **Tell users to logout and login again**
2. **Or** clear browser cache and refresh
3. **Or** wait - cache will clear on next login

### To Verify Permissions Are Saved:

1. Go to Firebase Console → Firestore Database
2. Go to `role_permissions` collection
3. Filter by `role_id` = (Cashier role_id, which is 5)
4. Count the permission entries
5. They should match what you set in the UI

## The Code is Correct

The permission saving code is working correctly:
- `updateRolePermissions()` in `role_service.dart` deletes old permissions and adds new ones
- It uses Firestore batch operations
- Changes are committed to Firestore

The only "issue" is that permissions are cached for performance, which requires logout/login to see changes.

## Best Practice

When updating permissions:
1. Make the changes in the UI
2. Wait for "Permissions updated successfully" message
3. Tell affected users to logout and login again
4. They will see the updated permissions

This is normal behavior - caching improves performance, and logout/login ensures fresh data.

