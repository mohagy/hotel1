# Fix Admin User Role - Quick Guide

## Problem Identified
Your user document in Firestore has `role: "staff"` instead of `role: "admin"`.

**Console Evidence:**
```
PermissionChecker: Looking for role "Staff" (original: "staff")
PermissionProvider: Loaded permissions for user admin (role: staff): [messages.view, guests.view, rooms.view, reservations.view, dashboard.view]
```

Only 5 permissions are loaded (Staff role), but Admin should have 28+ permissions.

## Solution: Change User Role in Firestore

### Steps:

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your project

2. **Navigate to Firestore Database**
   - Click on "Firestore Database" in the left menu

3. **Find Your User Document**
   - Click on the `users` collection
   - Find the document for `admin@hotel.com` (or your admin user)
   - You can search/filter by email if needed

4. **Change the Role Field**
   - Click on the user document to open it
   - Find the `role` field
   - Currently it says: `"staff"` (lowercase)
   - Change it to: `"admin"` (lowercase)
   - Click "Update" or save the document

5. **Clear Browser Cache (Optional but Recommended)**
   - Press Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac) to hard refresh
   - Or clear browser cache

6. **Logout and Login Again**
   - Logout from the app
   - Login again as admin
   - The permissions should now load correctly

## Expected Result

After changing the role to "admin", when you login again, the console should show:

```
PermissionChecker: Looking for role "Admin" (original: "admin")
PermissionChecker: Found role "Admin" with ID: X
PermissionChecker: Loaded 28+ permissions: [dashboard.view, guests.view, guests.create, guests.edit, guests.delete, rooms.view, rooms.create, rooms.edit, rooms.delete, reservations.view, reservations.create, reservations.edit, reservations.checkin, reservations.checkout, reservations.cancel, billing.view, billing.create, billing.edit, billing.payment, pos.view, pos.sales, pos.products, reports.view, reports.export, messages.view, users.view, users.create, users.edit, users.delete, roles.manage, settings.view, settings.edit]
PermissionProvider: Loaded permissions for user admin (role: admin): [dashboard.view, guests.view, ...]
```

And you should see ALL menu items in the sidebar:
- ✅ Dashboard
- ✅ Guests
- ✅ Rooms
- ✅ Reservations
- ✅ Billing
- ✅ Reports
- ✅ POS Management
- ✅ Messages
- ✅ Settings
- ✅ Users
- ✅ Roles & Permissions

The sidebar footer should also show "Admin" instead of "Staff".

## Important Notes

- The role field must be exactly `"admin"` (lowercase) in Firestore
- The system will automatically capitalize it to "Admin" when looking up the role
- Make sure you logout and login again after changing the role
- If permissions still don't load after this, check that the Admin role in the `roles` collection has all permissions assigned

