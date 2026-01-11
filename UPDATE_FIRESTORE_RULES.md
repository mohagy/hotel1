# Update Firestore Rules - URGENT

## ⚠️ Permission Denied Error

Your app is getting `[cloud_firestore/permission-denied] Missing or insufficient permissions` because the Firestore security rules are missing read permissions for reservations.

## 🔧 Quick Fix

You need to update your Firestore rules in the Firebase Console:

### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/project/flutter-hotel-8efbf/firestore/rules
2. Or go to: Firebase Console → Your Project → Firestore Database → Rules tab

### Step 2: Update the Reservations Rule

Find this section:
```
match /reservations/{reservationId} {
  allow update, delete: if hasRole('admin') || hasRole('manager');
}
```

**Change it to:**
```
match /reservations/{reservationId} {
  allow read, create: if isAuthenticated();
  allow update, delete: if hasRole('admin') || hasRole('manager');
}
```

### Step 3: Update the hasRole Function (Optional but Recommended)

Find this function:
```
function hasRole(role) {
  return isAuthenticated() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
}
```

**Change it to:**
```
function hasRole(role) {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
}
```

### Step 4: Publish
1. Click **"Publish"** button
2. Wait for deployment (usually takes a few seconds)

### Step 5: Test
1. Refresh your app (Ctrl+F5 or hard refresh)
2. The permission errors should be gone
3. Reservations should now load correctly

## 📋 Complete Rules File

If you want to copy the entire updated rules file, see `firestore.rules` in the project root.

## ✅ After Updating

Once you publish the rules:
- ✅ Reservations will load from Firestore
- ✅ Products will load from Firestore  
- ✅ Categories will load from Firestore
- ✅ No more permission denied errors

