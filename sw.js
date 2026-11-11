/* CC Motocrafts AI Engine Labs Service — Root-Safe PWA Service Worker v2.0 */
const CACHE_NAME = 'ccm-cyberpunk-pwa-v2';
const CORE_ASSETS = [
  './',
  './index.html',
  './customer.html',
  './partner-terminal.html',
  './garage.html',
  './admin-ops.html',
  './owner.html',
  './admin.html',
  './hts-owner-app.html',
  './diagnosis.html',
  './app.css',
  './app.js',
  './manifest.json',
  './manifest-partner.json',
  './manifest-owner.json',
  './icon-192.png',
  './icon-512.png',
  './icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => Promise.allSettled(CORE_ASSETS.map((url) => cache.add(url))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.pathname.includes('/api/')) return;
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return cached || fetch(event.request).then((response) => {
        if (response && response.status === 200 && url.origin === location.origin) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => caches.match('./index.html'));
    })
  );
});
