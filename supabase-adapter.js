/* FICOESA Creative Hub - adaptador Supabase JS v2 */
(function () {
  'use strict';
  var cfg = window.SUPABASE_CONFIG || window.supabaseConfig || window.FICOESA_SUPABASE || {};
  var url = cfg.url || cfg.supabaseUrl || cfg.SUPABASE_URL || window.SUPABASE_URL;
  var key = cfg.anonKey || cfg.publishableKey || cfg.supabaseAnonKey || cfg.key || cfg.SUPABASE_ANON_KEY || window.SUPABASE_ANON_KEY;
  var sdk = window.supabase;
  var configured = !!(url && key && sdk && typeof sdk.createClient === 'function' && !/TU_|YOUR_|AQUI|REEMPLAZAR/i.test(key));
  if (!configured) {
    console.error('FICOESA: falta URL/clave publica en supabase-config.js o no carga la libreria Supabase JS v2.');
    window.FICOESA_BACKEND = { configured: false };
    return;
  }
  var client = sdk.createClient(url, key);
  var bucket = client.storage.from('campaign-images');
  function assert(result) {
    if (result && result.error) throw result.error;
    return result ? result.data : null;
  }
  async function requireAdmin() {
    var data = assert(await client.rpc('is_ficoesa_admin'));
    if (data !== true) throw new Error('La cuenta no tiene permisos de administrador en Supabase.');
  }
  var validRoles = ['admin','visitante','viewer','comenter','worker','boss'];
  async function currentRole() {
    var res = await client.auth.getUser();
    if (res.error || !res.data || !res.data.user) return 'guest';
    var roleResult = await client.rpc('ficoesa_my_role');
    if (roleResult.error) throw roleResult.error;
    var role = roleResult.data;
    return validRoles.indexOf(role) !== -1 ? role : 'denied';
  }
  async function requireAllowed() {
    var role = await currentRole();
    if (validRoles.indexOf(role) === -1) throw new Error('Tu cuenta no está autorizada en FICOESA Creative Hub.');
  }
  // Firma por lotes: evita abrir decenas de peticiones a Storage en paralelo.
  var privateUrls = Object.create(null);
  var signingInProgress = null;
  var lastSignatureRefresh = 0;
  var signedUrlMaxEntries = 2200;
  async function refreshImageUrls(ids) {
    // Mantener los enlaces validos dentro de la sesion.
    var unique = Array.from(new Set((ids || []).filter(Boolean))).filter(function (id) {
      return !privateUrls[id] || privateUrls[id].expires <= Date.now();
    });
    if (!unique.length) return;
    // Serializar tambien llamadas solapadas de sincronizacion.
    if (signingInProgress) {
      await signingInProgress;
      unique = unique.filter(function (id) { return !privateUrls[id] || privateUrls[id].expires <= Date.now(); });
      if (!unique.length) return;
    }
    signingInProgress = (async function () {
      await requireAllowed();
      // La portada de cada campana viaja primero en la lista recibida.
      for (var offset = 0; offset < unique.length; offset += 20) {
        var batch = unique.slice(offset, offset + 20);
        // Una solicitud de Storage por cada 20 imagenes, en vez de una por imagen.
        var response = await bucket.createSignedUrls(batch, 3600);
        // Un 429 temporal no debe dejar sin miniaturas todas las campanas.
        if (response.error && (response.error.status === 429 || /rate limit|too many/i.test(response.error.message || ''))) {
          await new Promise(function (resolve) { setTimeout(resolve, 1100); });
          response = await bucket.createSignedUrls(batch, 3600);
        }
        if (response.error) throw response.error;
        (response.data || []).forEach(function (entry) {
          if (entry && entry.signedUrl && entry.path) {
            privateUrls[entry.path] = { url: entry.signedUrl, expires: Date.now() + 3500 * 1000 };
          }
        });
        // Ceder el control del navegador entre lotes de Storage.
        if (offset + 20 < unique.length) await new Promise(function (resolve) { setTimeout(resolve, 45); });
      }
      lastSignatureRefresh = Date.now();
      var keys = Object.keys(privateUrls);
      if (keys.length > signedUrlMaxEntries) {
        keys.forEach(function (key) { if (privateUrls[key].expires <= Date.now()) delete privateUrls[key]; });
      }
    })();
    try { await signingInProgress; }
    finally { signingInProgress = null; }
  }
  function privateImage(id) {
    var item = privateUrls[id];
    return item && item.expires > Date.now() ? item.url : '';
  }
  var allowedUsers = {
    list: async function () {
      await requireAdmin();
      return assert(await client.from('ficoesa_allowed_users').select('email,role,created_at').order('email')) || [];
    },
    add: async function (email) {
      await requireAdmin();
      email = String(email || '').trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error('Correo electrónico incorrecto.');
      assert(await client.from('ficoesa_allowed_users').insert({email:email,role:'viewer'}));
    },
    remove: async function (email) {
      await requireAdmin();
      if (email === 'ficoesaweb@gmail.com') throw new Error('No se puede eliminar la cuenta administradora principal.');
      assert(await client.from('ficoesa_allowed_users').delete().eq('email',email).eq('role','viewer'));
    }
  };
  function readDoc(data) {
    return { id: data.id, data: function () { return Object.assign({}, data.content || {}); } };
  }
  var channel = null;
  var db = {
    collection: function (name) {
      if (name !== 'campaigns') throw new Error('Coleccion desconocida: ' + name);
      return {
        onSnapshot: function (success, failure) {
          var closed = false;
          async function refresh() {
            try {
              await requireAllowed();
              var rows = assert(await client.from('campaigns').select('id,content').order('created_at', { ascending: false }));
              if (!closed) success({ docs: (rows || []).map(readDoc) });
            } catch (e) { if (!closed && failure) failure(e); }
          }
          refresh();
          channel = client.channel('ficoesa-campaigns-' + Math.random().toString(36).slice(2))
            .on('postgres_changes', { event: '*', schema: 'public', table: 'campaigns' }, refresh)
            .subscribe();
          return function () { closed = true; if (channel) client.removeChannel(channel); };
        }
      };
    },
    doc: function (path) {
      var match = /^campaigns\/(.+)$/.exec(path);
      if (!match) throw new Error('Ruta de documento desconocida.');
      var id = match[1];
      return {
        set: async function (content) {
          await requireAdmin();
          assert(await client.from('campaigns').upsert({ id: id, content: content, updated_at: new Date().toISOString() }, { onConflict: 'id' }));
        },
        update: async function (patch) {
          await requireAdmin();
          var rows = assert(await client.from('campaigns').select('content').eq('id', id).single());
          if (!rows) throw new Error('No existe la campana.');
          var merged = Object.assign({}, rows.content || {}, patch);
          assert(await client.from('campaigns').update({ content: merged, updated_at: new Date().toISOString() }).eq('id', id));
        },
        delete: async function () {
          await requireAdmin();
          assert(await client.from('campaigns').delete().eq('id', id));
        }
      };
    }
  };
  var assets = {
    upload: async function (file, options) {
      await requireAdmin();
      if (!file || !/^image\/jpeg$/i.test(file.type || (options && options.type) || '')) throw new Error('Solo se permiten imagenes JPG.');
      if (file.size > 20 * 1024 * 1024) throw new Error('El JPG supera 20 MB.');
      var id = (crypto.randomUUID ? crypto.randomUUID() : Date.now() + '-' + Math.random().toString(36).slice(2)) + '.jpg';
      assert(await bucket.upload(id, file, { contentType: 'image/jpeg', upsert: false }));
      return { id: id };
    },
    delete: async function (id) {
      await requireAdmin();
      assert(await bucket.remove([id]));
    },
    list: async function () {
      await requireAdmin();
      var rows = assert(await bucket.list('', { limit: 1000 }));
      var files = (rows || []).filter(function (x) { return !!x.name && x.name !== '.emptyFolderPlaceholder'; });
      var bytes = files.reduce(function (sum, file) { return sum + Number((file.metadata && file.metadata.size) || 0); }, 0);
      return { usage: { files: files.length, bytes: bytes, maxBytes: 20 * 1024 * 1024 } };
    }
  };
  window.FICOESA_BACKEND = {
    configured: true,
    client: client,
    db: db,
    assets: assets,
    publicImage: privateImage,
    refreshImageUrls: refreshImageUrls,
    allowedUsers: allowedUsers,
    role: currentRole,
    getUser: async function () { return assert(await client.auth.getUser()).user; },
    signIn: async function (email, password) {
      var data = assert(await client.auth.signInWithPassword({ email: email, password: password }));
      return data.user;
    },
    signOut: async function () { assert(await client.auth.signOut()); }
  };
})();
