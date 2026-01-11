# Hotel Management System - Flutter Web App

A comprehensive hotel management system built with Flutter for web, featuring real-time chat, reservation management, POS system, and more.

## Features

- 🏨 **Room Management** - Manage hotel rooms with real-time updates
- 👥 **Guest Management** - Track guest information and preferences
- 📅 **Reservations** - Handle bookings, check-ins, and check-outs
- 💬 **Real-time Chat** - Group and private messaging for staff communication
- 💰 **POS System** - Point of sale for retail, restaurant, and reservations
- 👤 **User Management** - Role-based access control with permissions
- 🔐 **Authentication** - Secure login with Firebase Authentication
- ☁️ **Firestore Integration** - Real-time database synchronization

## Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Firestore, Authentication)
- **State Management**: Provider
- **Routing**: GoRouter
- **Offline Support**: Hive

## Deployment

This app is deployed to GitHub Pages using GitHub Actions.

### Local Development

1. Install Flutter SDK (3.x or higher)
2. Clone the repository:
   ```bash
   git clone https://github.com/mohagy/hotel1.git
   cd hotel1
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run -d chrome
   ```

### Building for Production

To build the web app:

```bash
flutter build web --base-href /hotel1/
```

The built files will be in the `build/web` directory.

## Firebase Configuration

This app requires Firebase configuration. Make sure to:

1. Set up a Firebase project
2. Configure `lib/firebase_options.dart` with your Firebase credentials
3. Set up Firestore security rules
4. Enable Firebase Authentication (Email/Password)

## License

[Add your license here]

## Contact

Email: nathonheart@gmail.com
