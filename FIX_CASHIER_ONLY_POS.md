# Fix Cashier Role - Only POS Permissions

## Issue
Cashier user is seeing Guests, Reservations, and Billing menu items, but you only want POS Management.

## Solution Applied
I've updated the Cashier role to only have:
- `dashboard.view` (Dashboard)
- `pos.view`, `pos.sales` (POS Management)
- `messages.view` (Messages)

## Current Status
✅ Script executed successfully - Cashier role now has only 4 permissions instead of 8.

## Next Steps

1. **Logout and Login Again**
   - Logout from the Cashier account
   - Login again as cashier@gmail.com
   - The permissions cache will be cleared and new permissions loaded

2. **Expected Result**
   After login, Cashier should only see:
   - ✅ Dashboard
   - ✅ POS Management
   - ✅ Messages
   - ❌ Guests (removed)
   - ❌ Reservations (removed)
   - ❌ Billing (removed)

## If You Want ONLY POS (No Dashboard, No Messages)

If you want Cashier to have ONLY POS Management (no Dashboard, no Messages), you can:

1. **Option A: Use the App UI**
   - Login as Admin
   - Go to Roles & Permissions page
   - Click on "Cashier" role
   - Click "Manage Permissions"
   - Uncheck "View Dashboard" and "View Messages"
   - Only check "View POS" and "POS Sales"
   - Save

2. **Option B: Run Custom Script**
   I can create a script that sets Cashier to ONLY have POS permissions (no dashboard, no messages). Let me know if you want this.

## Verify It Worked

Check the browser console (F12) after login. You should see:
```
PermissionChecker: Loaded 4 permissions: [dashboard.view, pos.view, pos.sales, messages.view]
PermissionProvider: Loaded permissions for user cashier (role: cashier): [dashboard.view, pos.view, pos.sales, messages.view]
```

## Files Created

- `fix_cashier_permissions.js` - Script to fix Cashier permissions
- Updated `init_permissions.js` - Updated default Cashier permissions

