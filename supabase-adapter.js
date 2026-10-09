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
  async function currentRole() {
    var session = assert(await client.auth.getSession());
    if (!session || !session.session) return 'viewer';
    return (assert(await client.rpc('is_ficoesa_admin')) === true) ? 'admin' : 'viewer';
  }
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
    publicImage: function (id) { return bucket.getPublicUrl(id).data.publicUrl; },
    role: currentRole,
    getUser: async function () { return assert(await client.auth.getUser()).user; },
    signIn: async function (email, password) {
      var data = assert(await client.auth.signInWithPassword({ email: email, password: password }));
      return data.user;
    },
    signOut: async function () { assert(await client.auth.signOut()); }
  };
})();
