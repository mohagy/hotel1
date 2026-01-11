// Firebase Cloud Messaging Service Worker
// This file is required for Firebase Cloud Messaging to work on web

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase with your config
firebase.initializeApp({
  apiKey: "AIzaSyBLV8T9Wwmcgnb8OvoeB8bofqEYe2IZW_M",
  authDomain: "flutter-hotel-8efbf.firebaseapp.com",
  projectId: "flutter-hotel-8efbf",
  storageBucket: "flutter-hotel-8efbf.firebasestorage.app",
  messagingSenderId: "635259139186",
  appId: "1:635259139186:web:886df2615ded00f87e3eeb"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // Customize notification here
  const notificationTitle = payload.notification?.title || 'New Message';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new message',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
