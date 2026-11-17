-- FICOESA CREATIVE HUB | BOSS: acceso de lectura general y correcciones como COMENTER.
-- IMPORTANTE: ejecutar SOLO en el proyecto Supabase del DIRECTORIO/Caja de Herramientas.
-- NO ejecutar en el proyecto independiente de FICOESA CONNECT.
-- No cambia el rol de ninguna persona ni elimina políticas existentes.
-- Idempotente: se pueden volver a ejecutar estas políticas identificadas por su nombre.
-- Requisitos: public.ficoesa_my_role() y las tablas campañas/comentarios existentes.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.campaigns') IS NULL THEN
    RAISE EXCEPTION 'Falta public.campaigns; verifica que estas en el Supabase del Directorio';
  END IF;
  IF to_regclass('public.campaign_comments') IS NULL THEN
    RAISE EXCEPTION 'Falta public.campaign_comments; revisa la instalacion previa de comentarios';
  END IF;
  IF to_regprocedure('public.ficoesa_my_role()') IS NULL THEN
    RAISE EXCEPTION 'Falta public.ficoesa_my_role(); no es seguro instalar el acceso BOSS';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid = 'public.campaigns'::regclass AND relrowsecurity)
     OR NOT EXISTS (SELECT 1 FROM pg_class WHERE oid = 'public.campaign_comments'::regclass AND relrowsecurity) THEN
    RAISE EXCEPTION 'Las tablas campaigns y campaign_comments deben tener RLS activa. No se modifico nada.';
  END IF;
END $$;

-- Se mantienen los GRANT existentes; COMENTER ya dispone de permisos SQL
-- de lectura/escritura sobre campaign_comments y BOSS hereda los mismos GRANT
-- del rol de base de datos 'authenticated'. Solo se amplía el acceso RLS.

-- BOSS puede consultar TODAS las campañas, incluso pendientes y archivadas.
-- No se concede INSERT/UPDATE/DELETE sobre campaigns.
DROP POLICY IF EXISTS "FICOESA BOSS leer todas las campanas" ON public.campaigns;
CREATE POLICY "FICOESA BOSS leer todas las campanas"
ON public.campaigns FOR SELECT TO authenticated
USING (public.ficoesa_my_role() = 'boss');

-- Las correcciones solo se permiten en campañas activas y pendientes,
-- exactamente en el contexto de la interfaz de COMENTER.
DROP POLICY IF EXISTS "FICOESA BOSS leer correcciones" ON public.campaign_comments;
CREATE POLICY "FICOESA BOSS leer correcciones"
ON public.campaign_comments FOR SELECT TO authenticated
USING (
  public.ficoesa_my_role() = 'boss'
  AND EXISTS (
    SELECT 1 FROM public.campaigns c
    WHERE c.id::text = campaign_id::text
      AND c.content->>'status' = 'pendiente'
      AND COALESCE(c.content->>'archived','false') = 'false'
  )
);

DROP POLICY IF EXISTS "FICOESA BOSS crear correcciones" ON public.campaign_comments;
CREATE POLICY "FICOESA BOSS crear correcciones"
ON public.campaign_comments FOR INSERT TO authenticated
WITH CHECK (
  public.ficoesa_my_role() = 'boss'
  AND user_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.campaigns c
    WHERE c.id::text = campaign_id::text
      AND c.content->>'status' = 'pendiente'
      AND COALESCE(c.content->>'archived','false') = 'false'
  )
);

DROP POLICY IF EXISTS "FICOESA BOSS resolver correcciones" ON public.campaign_comments;
CREATE POLICY "FICOESA BOSS resolver correcciones"
ON public.campaign_comments FOR UPDATE TO authenticated
USING (
  public.ficoesa_my_role() = 'boss'
  AND EXISTS (
    SELECT 1 FROM public.campaigns c
    WHERE c.id::text = campaign_id::text
      AND c.content->>'status' = 'pendiente'
      AND COALESCE(c.content->>'archived','false') = 'false'
  )
)
WITH CHECK (
  public.ficoesa_my_role() = 'boss'
  AND EXISTS (
    SELECT 1 FROM public.campaigns c
    WHERE c.id::text = campaign_id::text
      AND c.content->>'status' = 'pendiente'
      AND COALESCE(c.content->>'archived','false') = 'false'
  )
);

DROP POLICY IF EXISTS "FICOESA BOSS borrar correcciones resueltas" ON public.campaign_comments;
CREATE POLICY "FICOESA BOSS borrar correcciones resueltas"
ON public.campaign_comments FOR DELETE TO authenticated
USING (
  public.ficoesa_my_role() = 'boss'
  AND resolved = true
  AND parent_id IS NULL
  AND EXISTS (
    SELECT 1 FROM public.campaigns c
    WHERE c.id::text = campaign_id::text
      AND c.content->>'status' = 'pendiente'
      AND COALESCE(c.content->>'archived','false') = 'false'
  )
);

-- Caja de Herramientas: todos los recursos y sus enlaces, adjuntos, secciones
-- y ajustes pueden ser leídos por BOSS sin poder modificarlos.
-- La migración es tolerante a tablas adicionales ausentes en versiones previas.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'marketing_toolbox_items', 'marketing_toolbox_links',
    'marketing_toolbox_files', 'marketing_toolbox_sections',
    'marketing_toolbox_settings'
  ] LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      IF EXISTS (
        SELECT 1 FROM pg_class WHERE oid = to_regclass('public.' || t) AND relrowsecurity
      ) THEN
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', 'FICOESA BOSS lectura', t);
        EXECUTE format(
          'CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (public.ficoesa_my_role() = ''boss'')',
          'FICOESA BOSS lectura', t
        );
      ELSE
        RAISE NOTICE 'La tabla % no tiene RLS; se dejan intactos sus permisos existentes', t;
      END IF;
    END IF;
  END LOOP;
END $$;

-- Tablón informativo: BOSS ve también los avisos todavía en borrador,
-- sin poder crearlos, publicarlos, modificarlos o borrarlos.
DO $$
BEGIN
  IF to_regclass('public.ficoesa_hub_notes') IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM pg_class WHERE oid = 'public.ficoesa_hub_notes'::regclass AND relrowsecurity) THEN
      DROP POLICY IF EXISTS "FICOESA BOSS leer todos los avisos" ON public.ficoesa_hub_notes;
      CREATE POLICY "FICOESA BOSS leer todos los avisos"
      ON public.ficoesa_hub_notes FOR SELECT TO authenticated
      USING (public.ficoesa_my_role() = 'boss');
    ELSE
      RAISE NOTICE 'El tablon no tiene RLS activa; se mantienen sus permisos actuales';
    END IF;
  END IF;
END $$;

-- Los buckets siguen PRIVADOS. Se habilita exclusivamente la lectura
-- a una cuenta autenticada cuyo rol del Directorio sea BOSS.
DROP POLICY IF EXISTS "FICOESA BOSS leer fotos del Directorio" ON storage.objects;
CREATE POLICY "FICOESA BOSS leer fotos del Directorio"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'campaign-images' AND public.ficoesa_my_role() = 'boss');

DROP POLICY IF EXISTS "FICOESA BOSS leer recursos de Caja" ON storage.objects;
CREATE POLICY "FICOESA BOSS leer recursos de Caja"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'marketing-toolbox' AND public.ficoesa_my_role() = 'boss');

COMMIT;
NOTIFY pgrst, 'reload schema';

-- IMPORTANTE: SQL no cambia la whitelist existente. El usuario BOSS debe
-- estar dado de alta en Authentication y en ficoesa_allowed_users con role='boss'.
-- No se modifican usuarios ni permisos de la instancia independiente CONNECT.
-- Prueba con una cuenta BOSS: visualizar pendientes, publicadas, archivadas,
-- revisar Caja, publicar/reabrir/resolver una corrección. Confirmar que no
-- puede crear/editar/eliminar campañas ni alterar usuarios o recursos.
