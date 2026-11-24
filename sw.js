const CACHE = 'ufba-apostila-v7-20261124';
const ASSETS = ['./','./index.html','./questoes.json','./resumos.json','./manifest.webmanifest','./icon.svg','./icon-192.png','./icon-512.png'];
self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    await Promise.allSettled(ASSETS.map(async path => {
      const request = new Request(new URL(path, self.registration.scope), {cache:'reload'});
      const response = await fetch(request);
      if (response.ok) await cache.put(request, response);
    }));
    await self.skipWaiting();
  })());
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('ufba-') && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  const asset = ASSETS.some(path => new URL(path,self.registration.scope).pathname === url.pathname);
  if (!asset && request.mode !== 'navigate') return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    try {
      const response = await fetch(request, {cache:'no-store'});
      if (response.ok) {
        try { await cache.put(request, response.clone()); } catch (_) {}
      }
      return response;
    } catch (_) {
      const cached = await cache.match(request, {ignoreSearch:true});
      if (cached) return cached;
      if (request.mode === 'navigate') {
        const page = await cache.match(new URL('./index.html',self.registration.scope));
        if (page) return page;
      }
      return new Response('Recurso indisponível offline.', {status:503});
    }
  })());
});
