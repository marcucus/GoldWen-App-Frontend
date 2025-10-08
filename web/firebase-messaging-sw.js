// Firebase Cloud Messaging Service Worker for Web Push Notifications
// This file handles background notifications when the web app is not in focus

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
// Note: These values should match your Firebase project configuration
firebase.initializeApp({
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID",
  measurementId: "YOUR_MEASUREMENT_ID"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'GoldWen';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'default',
    data: payload.data,
    requireInteraction: payload.data?.type === 'new_match' || payload.data?.type === 'chat_expiring',
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.', event);
  
  event.notification.close();
  
  // Get the notification data
  const data = event.notification.data || {};
  const type = data.type;
  
  // Determine the URL to open based on notification type
  let urlToOpen = '/';
  
  switch (type) {
    case 'daily_selection':
      urlToOpen = '/discover';
      break;
    case 'new_match':
      urlToOpen = '/matches';
      break;
    case 'new_message':
      if (data.conversationId) {
        urlToOpen = `/chat/${data.conversationId}`;
      } else {
        urlToOpen = '/matches';
      }
      break;
    case 'chat_expiring':
      if (data.conversationId) {
        urlToOpen = `/chat/${data.conversationId}`;
      } else {
        urlToOpen = '/matches';
      }
      break;
    default:
      urlToOpen = '/notifications';
  }
  
  // Open or focus the appropriate window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if there's already a window open
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            return client.focus().then(() => client.navigate(urlToOpen));
          }
        }
        // If no window is open, open a new one
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});
