# Firebase Login Setup Guide

## Current Situation
Your Flutter app uses **Firebase Authentication** (not the PHP backend authentication). This means:
- ❌ No hardcoded credentials
- ✅ Users must be created in Firebase Console first
- 🔐 Login uses Firebase Auth: `flutter-hotel-8efbf` project

## Quick Setup - Create Test User

### Step 1: Access Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select project: **flutter-hotel-8efbf**
3. Navigate to: **Authentication** → **Users**

### Step 2: Add a Test User
1. Click **"Add user"** button
2. Enter:
   - **Email:** `admin@hotel.com` (or any email)
   - **Password:** `admin123` (or your preferred password)
3. Click **"Add user"**

### Step 3: Login to Flutter App
1. Open: `http://localhost:56245/#/login`
2. Enter the email and password you just created
3. Click **Login**

---

## Alternative: Add Signup Screen (Recommended)

If you prefer to create users directly from the app, I can add a signup screen for you.

### Demo Credentials (after creating user)
```
Email: admin@hotel.com
Password: admin123
```

Or any email/password you create in Firebase Console.

---

## Firebase Project Details
- **Project ID:** flutter-hotel-8efbf
- **Auth Domain:** flutter-hotel-8efbf.firebaseapp.com
- **Firebase Console:** https://console.firebase.google.com/project/flutter-hotel-8efbf

