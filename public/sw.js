const CACHE_NAME = 'cashier-management-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/src/main.tsx',
  '/src/index.css',
  '/src/App.tsx',
  '/icons/icon-72x72.png',
  '/icons/icon-96x96.png',
  '/icons/icon-128x128.png',
  '/icons/icon-144x144.png',
  '/icons/icon-152x152.png',
  '/icons/icon-192x192.png',
  '/icons/icon-384x384.png',
  '/icons/icon-512x512.png',
];

const DYNAMIC_CACHE = 'dynamic-v1';
const DYNAMIC_ASSETS = [
  '/api/employees',
  '/api/payroll',
  '/api/attendance',
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== DYNAMIC_CACHE)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache, then network
self.addEventListener('fetch', (event) => {
  // Skip non-GET requests
  if (event.request.method !== 'GET') return;

  // Handle API requests
  if (event.request.url.includes('/api/')) {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // Handle static assets
  event.respondWith(cacheFirst(event.request));
});

// Cache-first strategy for static assets
async function cacheFirst(request) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_NAME);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    return new Response('Network error happened', {
      status: 408,
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

// Network-first strategy for API requests
async function networkFirst(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
      return networkResponse;
    }
  } catch (error) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    return new Response('Network error happened', {
      status: 408,
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

// Background sync for offline actions
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-attendance') {
    event.waitUntil(syncAttendance());
  } else if (event.tag === 'sync-payroll') {
    event.waitUntil(syncPayroll());
  }
});

// Push notification handling
self.addEventListener('push', (event) => {
  const data = event.data.json();
  const options = {
    body: data.body,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    vibrate: [100, 50, 100],
    data: {
      url: data.url,
    },
    actions: [
      {
        action: 'view',
        title: 'عرض',
      },
      {
        action: 'close',
        title: 'إغلاق',
      },
    ],
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Notification click handling
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'view') {
    event.waitUntil(
      clients.openWindow(event.notification.data.url)
    );
  }
});

// Periodic sync for background tasks
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'daily-sync') {
    event.waitUntil(performDailySync());
  }
});

// Helper functions for sync operations
async function syncAttendance() {
  const offlineAttendance = await getOfflineData('attendance');
  try {
    await fetch('/api/attendance/sync', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(offlineAttendance),
    });
    await clearOfflineData('attendance');
  } catch (error) {
    console.error('Failed to sync attendance:', error);
  }
}

async function syncPayroll() {
  const offlinePayroll = await getOfflineData('payroll');
  try {
    await fetch('/api/payroll/sync', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(offlinePayroll),
    });
    await clearOfflineData('payroll');
  } catch (error) {
    console.error('Failed to sync payroll:', error);
  }
}

async function performDailySync() {
  try {
    // Sync attendance records
    await syncAttendance();
    // Sync payroll data
    await syncPayroll();
    // Update cached data
    await updateCachedData();
  } catch (error) {
    console.error('Failed to perform daily sync:', error);
  }
}

// Helper functions for offline data management
async function getOfflineData(type) {
  const db = await openDB();
  return db.getAll(type);
}

async function clearOfflineData(type) {
  const db = await openDB();
  return db.clear(type);
}

async function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open('cashier-offline', 1);
    
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      
      if (!db.objectStoreNames.contains('attendance')) {
        db.createObjectStore('attendance', { keyPath: 'id' });
      }
      
      if (!db.objectStoreNames.contains('payroll')) {
        db.createObjectStore('payroll', { keyPath: 'id' });
      }
    };
  });
}

async function updateCachedData() {
  const cache = await caches.open(DYNAMIC_CACHE);
  
  // Update frequently changing data
  const urls = [
    '/api/employees',
    '/api/attendance/today',
    '/api/payroll/current',
  ];
  
  return Promise.all(
    urls.map(async (url) => {
      try {
        const response = await fetch(url);
        if (response.ok) {
          await cache.put(url, response);
        }
      } catch (error) {
        console.error(`Failed to update cached data for ${url}:`, error);
      }
    })
  );
}
