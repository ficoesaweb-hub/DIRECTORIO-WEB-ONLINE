/* FICOESA Connect: avisos de mensajes no leidos para Creative Hub y Caja de Herramientas.
   Cliente separado de Supabase; no comparte permisos ni credenciales entre proyectos.
   Utiliza la misma marca de lectura local que Connect (sin SQL adicional). */
(function () {
  'use strict';
  var client = null, timer = null, started = false, checking = false, emailProvider = null;
  var key = null, latestCount = 0, pendingPoll = null, lastPoll = 0;
  function dot() {
    document.querySelectorAll('[data-connect-notification]').forEach(function (el) {
      el.hidden = latestCount < 1;
      el.title = latestCount ? 'Hay mensajes nuevos en FICOESA Connect' : '';
    });
  }
  function update(n) { latestCount = n; dot(); }
  async function poll() {
    if (checking || document.hidden || !client || Date.now() - lastPoll < 12000) return;
    checking = true; lastPoll = Date.now();
    try {
      var identity = emailProvider ? await emailProvider() : null;
      if (!identity) { update(0); return; }
      var result = await client.auth.getUser();
      var person = result.data && result.data.user;
      if (result.error || !person || !person.email || person.email.toLowerCase() !== String(identity).toLowerCase()) {
        key = null; update(0); return;
      }
      key = 'ficoesa-connect-seen-' + person.id;
      var seen = {};
      try { seen = JSON.parse(localStorage.getItem(key) || '{}') || {}; } catch (_) {}
      var res = await client.from('connect_rooms').select('id');
      if (res.error) throw res.error;
      var list = res.data || [];
      if (!list.length) { update(0); return; }
      var now = new Date().toISOString();
      // Solo el ultimo mensaje DE OTRA PERSONA en cada sala autorizada.
      var flags = await Promise.all(list.map(async function (room) {
        var q = await client.from('connect_messages')
          .select('created_at').eq('room_id', room.id).neq('user_id', person.id)
          .gt('expires_at', now).order('created_at', { ascending: false }).limit(1);
        if (q.error) throw q.error;
        var last = q.data && q.data[0] && q.data[0].created_at;
        return last && (!seen[room.id] || new Date(last) > new Date(seen[room.id])) ? 1 : 0;
      }));
      update(flags.reduce(function (a, b) { return a + b; }, 0));
    } catch (err) {
      // Sin sesion iniciada en Connect o error de red: nunca inventar avisos.
      update(0);
      console.warn('FICOESA Connect - notificaciones:', err.message || err);
    } finally { checking = false; }
  }
  function start(getEmail) {
    emailProvider = getEmail;
    if (started) { dot(); return; }
    var cfg = window.FICOESA_CONNECT_CONFIG;
    if (!window.supabase || !cfg || !cfg.url || !cfg.publishableKey) return;
    client = window.supabase.createClient(cfg.url, cfg.publishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false }
    });
    started = true;
    // No competir con el acceso ni con la carga inicial del directorio.
    pendingPoll = setTimeout(function () { pendingPoll = null; poll(); }, 2500);
    timer = setInterval(poll, 60000);
    document.addEventListener('visibilitychange', function () { if (!document.hidden) poll(); });
    window.addEventListener('focus', poll);
    window.addEventListener('storage', function (e) { if (e.key && e.key === key) poll(); });
  }
  window.FICOESA_CONNECT_NOTIFICATIONS = { start: start, refresh: poll, decorate: dot };
})();
