# Verify Admin Permissions in Firestore

## Your User Document is Correct ✅
I can see your user document has:
- `role: "admin"` ✅ (correct)
- `email: "admin@hotel.com"` ✅
- `status: "active"` ✅

## Next Steps to Verify

### Step 1: Check Roles Collection
1. In Firestore, click on the **`roles`** collection
2. Look for a role document with `name: "Admin"` (capitalized "A")
3. Open that document and note the `role_id` value (it's a number like 1, 2, 3, etc.)

**Expected:** You should see a role with:
- `name: "Admin"`
- `role_id: X` (some number)

### Step 2: Check Role Permissions Collection
1. In Firestore, click on the **`role_permissions`** collection
2. Look for documents where `role_id` = (the Admin role_id from Step 1)
3. Count how many documents exist for the Admin role

**Expected:** Admin should have **28+ permission entries**

**If you see 0 entries:** That's the problem! The Admin role has no permissions assigned.

### Step 3: Check Permissions Collection
1. In Firestore, click on the **`permissions`** collection
2. Check if permissions exist
3. Open a few permission documents and verify they have a `key` field
4. Example keys should be: `"dashboard.view"`, `"guests.view"`, `"billing.view"`, etc.

## Common Issues

### Issue 1: Admin Role Doesn't Exist
**Symptom:** No role document with `name: "Admin"` in roles collection
**Fix:** You need to create the Admin role or initialize the permissions system

### Issue 2: Admin Role Has No Permissions
**Symptom:** Admin role exists but `role_permissions` collection has 0 entries for Admin role_id
**Fix:** You need to assign permissions to the Admin role

### Issue 3: Permissions Don't Exist
**Symptom:** `permissions` collection is empty or doesn't exist
**Fix:** You need to initialize/create the permissions

## Quick Fix: Initialize Permissions

If permissions are missing, you have two options:

### Option A: Use the App (If You Can Access Roles Page)
1. Try navigating directly to `/roles` in the browser (even if menu is hidden)
2. Look for an "Initialize Permissions & Roles" button
3. Click it to create all default permissions and role assignments

### Option B: Manual Fix in Firestore (Advanced)
This requires manually creating permissions and role_permissions entries, which is complex.

## What to Report Back

Please check and tell me:
1. Does the `roles` collection have a role with `name: "Admin"`? What is its `role_id`?
2. How many documents in `role_permissions` collection have that `role_id`?
3. How many documents are in the `permissions` collection?

This will help me understand what's missing!

