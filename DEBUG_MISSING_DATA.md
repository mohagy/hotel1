# Debug: Missing Guest/Reservation Data

## Quick Questions:
1. **What account are you logged in as?** (email and role)
2. **What do you see when you try to access Guests/Reservations?**
   - "Access Denied" screen?
   - Empty list?
   - Error message?
3. **Can you see the "Guests" and "Reservations" menu items in the sidebar?**
   - If NO: You don't have permission (this is correct if you're logged in as Cashier)
   - If YES: But no data loads, there's a data loading issue

## Expected Behavior by Role:

### Cashier Role:
- ❌ Should NOT see Guests menu item
- ❌ Should NOT see Reservations menu item  
- ✅ Should only see POS Management
- ✅ Should get "Access Denied" if trying to access /guests or /reservations directly

### Admin/Staff/Manager/Receptionist:
- ✅ Should see Guests menu item
- ✅ Should see Reservations menu item
- ✅ Should see data when clicking on them

## If You're Logged In as Admin/Staff and Still Not Seeing Data:

1. **Check Browser Console (F12):**
   - Look for error messages
   - Look for "PermissionProvider: Loaded permissions..." message
   - Check what permissions are loaded

2. **Check if Routes Are Blocked:**
   - Try navigating directly to /guests or /reservations
   - If you see "Access Denied", you don't have the required permissions

3. **Verify Your Role in Firestore:**
   - Run: `node check_user_role.js`
   - Make sure your role is correct

4. **Check Permissions:**
   - Run: `node verify_cashier_permissions.js` (for cashier)
   - Or check your role's permissions in Firestore

## Common Issues:

### Issue 1: Wrong Role Assigned
- **Symptom:** Cashier seeing all menu items
- **Solution:** Run `node fix_cashier_user_role.js`

### Issue 2: Missing Permissions
- **Symptom:** Admin/Staff not seeing data, getting "Access Denied"
- **Solution:** Check role_permissions in Firestore, run `init_permissions.js`

### Issue 3: Cache Issue
- **Symptom:** Changed permissions but still seeing old behavior
- **Solution:** Logout and login again

