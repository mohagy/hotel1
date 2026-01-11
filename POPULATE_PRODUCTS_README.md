# How to Populate Products and Categories in Firestore

This guide explains how to add hotel retail products and categories to Firebase Firestore.

## Prerequisites

1. Make sure you're logged into Firebase CLI:
   ```powershell
   firebase login
   ```

2. Make sure your Flutter app is configured with the correct Firebase project (`flutter-hotel-8efbf`)

## Steps to Populate Data

### Option 1: Using Dart Script (Recommended)

1. Open PowerShell and navigate to the Flutter project directory:
   ```powershell
   cd C:\xampp2\htdocs\hotel\Flutter_hotel
   ```

2. Run the populate script:
   ```powershell
   dart run lib/scripts/populate_products.dart
   ```

   This will:
   - Create 7 categories (Snacks & Beverages, Toiletries & Personal Care, etc.)
   - Create 58 hotel retail products
   - Store everything in Firestore

### Option 2: Using Flutter App (Alternative)

If the Dart script doesn't work, you can create a temporary screen in your Flutter app to run the population logic.

## What Gets Created

### Categories (7 total):
- Snacks & Beverages
- Toiletries & Personal Care
- Souvenirs & Gifts
- Food & Meals
- Drinks & Alcohol
- Room Service Items
- Electronics & Accessories

### Products (58 total):
- 13 Snacks & Beverages products
- 11 Toiletries & Personal Care products
- 8 Souvenirs & Gifts products
- 8 Food & Meals products
- 7 Drinks & Alcohol products
- 5 Room Service Items products
- 6 Electronics & Accessories products

## Verification

After running the script, you can verify the data in:
1. Firebase Console: https://console.firebase.google.com/project/flutter-hotel-8efbf/firestore
2. Your Flutter POS terminal: `http://localhost:XXXX/#/pos/terminal?mode=retail`

## Troubleshooting

If you get authentication errors:
- Make sure you're logged into Firebase: `firebase login`
- Make sure the Firebase project is correct in `firebase_options.dart`

If products don't show up:
- Check browser console (F12) for errors
- Verify Firestore rules are deployed: `firebase deploy --only firestore:rules`
- Make sure you're logged into the Flutter app

