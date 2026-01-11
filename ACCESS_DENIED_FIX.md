# Fix "Access Denied" for Admin Users

## Problem
You're logged in as admin@hotel.com with Admin role showing in the sidebar, but getting "Access Denied" when trying to access pages.

## Root Causes

### 1. User Role in Firestore is Wrong
**Most Common Issue:** Your user document in Firestore has `role: "staff"` instead of `role: "admin"`

**Check Browser Console:**
Look for this line:
```
PermissionProvider: Loaded permissions for user admin (role: staff): [...]
```

If it says `role: staff`, that's the problem!

**Fix:**
1. Go to Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find your user (admin@hotel.com)
4. Change `role` field from `"staff"` to `"admin"` (lowercase)
5. Save
6. **Clear browser cache** (Ctrl+Shift+R)
7. Logout and login again

### 2. Permission Cache Issue
If you just changed the role in Firestore, the app might be using cached permissions.

**Fix:**
1. Clear browser cache (Ctrl+Shift+R or Ctrl+F5)
2. Or logout and login again
3. The code now automatically clears cache on login

### 3. Admin Role Has No Permissions
The Admin role exists but doesn't have permissions assigned.

**Check Browser Console:**
```
PermissionChecker: Loaded 0 permissions: []
```

**Fix:**
1. Go to Firebase Console → Firestore Database
2. Check `roles` collection - find role with `name: "Admin"`
3. Note the `role_id`
4. Check `role_permissions` collection - filter by that `role_id`
5. If there are no entries, you need to assign permissions:
   - Try accessing `/roles` page in the app (if possible)
   - Or manually add permission entries in Firestore
   - Or use the "Initialize Permissions & Roles" feature

### 4. Admin Role Has Few Permissions
Admin should have 28+ permissions, but only has a few.

**Check Browser Console:**
```
PermissionProvider: Total permissions loaded: 5
⚠️ WARNING: Admin user has only 5 permissions. Expected 28+.
```

**Fix:**
1. Go to Roles & Permissions page in the app
2. Click on Admin role
3. Click "Manage Permissions"
4. Check ALL permission checkboxes
5. Save
6. Logout and login again

## Quick Diagnostic Steps

1. **Open Browser Console (F12)**
2. **Look for these messages after login:**
   ```
   PermissionChecker: Looking for role "Admin" (original: "admin")
   PermissionChecker: Found role "Admin" with ID: X
   PermissionChecker: Loaded X permissions: [...]
   PermissionProvider: Loaded permissions for user admin (role: admin): [...]
   PermissionProvider: Total permissions loaded: X
   ```

3. **What to check:**
   - Does it say `role: admin` or `role: staff`?
   - How many permissions are loaded? (Should be 28+ for admin)
   - Are there any warning messages?

## Expected Console Output for Admin

```
PermissionChecker: Looking for role "Admin" (original: "admin")
PermissionChecker: Found role "Admin" with ID: 1
PermissionChecker: Loaded 28 permissions: [dashboard.view, guests.view, guests.create, guests.edit, guests.delete, rooms.view, rooms.create, rooms.edit, rooms.delete, reservations.view, reservations.create, reservations.edit, reservations.checkin, reservations.checkout, reservations.cancel, billing.view, billing.create, billing.edit, billing.payment, pos.view, pos.sales, pos.products, reports.view, reports.export, messages.view, users.view, users.create, users.edit, users.delete, roles.manage, settings.view, settings.edit]
PermissionProvider: Loaded permissions for user admin (role: admin): [dashboard.view, guests.view, ...]
PermissionProvider: Total permissions loaded: 28
```

## After Fixing

Once fixed, you should:
- ✅ See all 11 menu items in sidebar
- ✅ Be able to access all pages without "Access Denied"
- ✅ See "Admin" in sidebar footer (not "Staff")
- ✅ Console shows 28+ permissions loaded

## Still Not Working?

If you've checked all of the above and it's still not working:

1. **Verify Firestore Data Structure:**
   - `users` collection: role = "admin" (lowercase)
   - `roles` collection: name = "Admin" (capitalized)
   - `role_permissions` collection: has entries for Admin role_id
   - `permissions` collection: permissions have `key` field

2. **Try Hard Refresh:**
   - Press Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   - This clears cache and reloads everything

3. **Check Network Tab:**
   - Open browser DevTools → Network tab
   - Look for Firestore requests
   - Check if they're successful (200 status)

4. **Contact Support:**
   - Share the browser console logs
   - Share what you see in Firestore

