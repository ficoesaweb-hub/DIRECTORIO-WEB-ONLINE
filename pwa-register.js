/* PWA progresiva: no guarda campañas privadas en caché. */
(function(){'use strict';
  if(!('serviceWorker' in navigator))return;
  if(location.protocol!=='https:' && location.hostname!=='localhost' && location.hostname!=='127.0.0.1')return;
  var script=document.currentScript;
  var serviceUrl=new URL('service-worker.js',script && script.src ? script.src : location.href).href;
  window.addEventListener('load',function(){ navigator.serviceWorker.register(serviceUrl).catch(function(e){console.warn('Creative Hub: PWA no disponible',e);}); });
})();
