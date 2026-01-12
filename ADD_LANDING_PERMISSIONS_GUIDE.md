# Add Landing Page Permissions to Firestore

## Problem
The landing page permissions (`landing.view` and `landing.manage`) are not showing in the permission matrix because they haven't been added to Firestore yet.

## Solution: Run the Script

### Option 1: Using Node.js Script (Recommended)

1. **Navigate to the Flutter project directory:**
   ```powershell
   cd c:\xampp2\htdocs\hotel\Flutter_hotel
   ```

2. **Run the script:**
   ```powershell
   node add_landing_permissions.js
   ```

3. **What the script does:**
   - Creates the `landing.view` and `landing.manage` permissions in Firestore
   - Adds them to Owner, Admin, and Manager roles
   - Skips roles that already have the permissions

4. **After running:**
   - Refresh the Roles & Permissions page in the app
   - The "LANDING" category should now appear in the permission matrix
   - You can assign these permissions to any role

### Option 2: Using the UI (If permissions don't exist)

If the permissions don't exist at all:

1. Go to **Roles & Permissions** in the app
2. Click **"Initialize Permissions"** button (if shown)
3. This will create all default permissions including landing page permissions
4. Refresh the page

### Option 3: Manual Firestore Update

If you prefer to add them manually in Firebase Console:

1. Go to Firebase Console → Firestore Database
2. Navigate to `permissions` collection
3. Add two new documents:

**Document 1:**
- Document ID: Next available number (e.g., "29")
- Fields:
  - `name`: "View Landing Page"
  - `key`: "landing.view"
  - `category`: "landing"
  - `description`: "View the public landing page"
  - `permission_id`: 29 (or next available)
  - `created_at`: [timestamp]
  - `updated_at`: [timestamp]

**Document 2:**
- Document ID: Next available number (e.g., "30")
- Fields:
  - `name`: "Manage Landing Page"
  - `key`: "landing.manage"
  - `category`: "landing"
  - `description`: "Manage landing page content, media, and settings"
  - `permission_id`: 30 (or next available)
  - `created_at`: [timestamp]
  - `updated_at`: [timestamp]

4. Then update the roles to include these permissions in their `permissions` array.

## Verify It Worked

1. Go to **Roles & Permissions** in the app
2. Click the security icon (🔒) next to any role
3. You should see a **"LANDING"** category with:
   - ☐ View Landing Page
   - ☐ Manage Landing Page

## Troubleshooting

### Still not showing?
- Make sure you've run the script or added permissions to Firestore
- Refresh the Roles & Permissions page
- Check browser console for errors
- Verify permissions exist in Firestore by checking the `permissions` collection

### Permissions exist but not assigned to roles?
- Run the `add_landing_permissions.js` script
- Or manually edit roles in Firestore to add `landing.view` and `landing.manage` to their permissions array

