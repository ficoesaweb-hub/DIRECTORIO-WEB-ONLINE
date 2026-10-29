/* FICOESA Creative Hub - solo cache de iconos e interfaz de desconexión.
   Los HTML autenticados y todas las solicitudes de Supabase van SIEMPRE a red. */
const STATIC_CACHE='ficoesa-creativehub-static-v3-3';
const STATIC_ASSETS=['./offline.html','./favicon.png','./icons/icon-192.png','./icons/icon-512.png','./manifest.webmanifest'];
self.addEventListener('install',event=>{event.waitUntil(caches.open(STATIC_CACHE).then(cache=>cache.addAll(STATIC_ASSETS)));self.skipWaiting();});
self.addEventListener('activate',event=>{event.waitUntil((async()=>{let keys=await caches.keys();await Promise.all(keys.filter(k=>k.startsWith('ficoesa-creativehub-static-')&&k!==STATIC_CACHE).map(k=>caches.delete(k)));await self.clients.claim()})());});
self.addEventListener('fetch',event=>{
  const req=event.request;
  if(req.method!=='GET'||new URL(req.url).origin!==self.location.origin)return;
  if(req.mode==='navigate'){
    event.respondWith(fetch(req).catch(()=>caches.match('./offline.html')));
    return;
  }
  const path=new URL(req.url).pathname;
  if(/\/(?:favicon\.png|manifest\.webmanifest|offline\.html)$/.test(path)||/\/icons\/icon-(?:192|512)\.png$/.test(path)){
    event.respondWith(caches.match(req).then(cached=>cached||fetch(req)));
  }
});
