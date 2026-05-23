// Venndle service worker — satisfies PWA installability requirements.
// Passthrough fetch handler: all requests go to the network as normal.
self.addEventListener('fetch', function(event) {
  event.respondWith(fetch(event.request));
});
