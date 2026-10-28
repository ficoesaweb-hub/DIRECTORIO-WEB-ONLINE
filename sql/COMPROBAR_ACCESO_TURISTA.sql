-- FICOESA V3.1: COMPROBACIÓN DE ACCESO TURISTA. SOLO LECTURA.
-- Ejecuta en el SQL Editor del proyecto Supabase del DIRECTORIO, no en CONNECT.
-- No cambia permisos ni datos.

select
  to_regprocedure('public.ficoesa_tourist_feed()') is not null as rpc_turista_instalada,
  case when to_regprocedure('public.ficoesa_tourist_feed()') is not null
    then has_function_privilege('anon', 'public.ficoesa_tourist_feed()', 'EXECUTE')
    else false end as anon_puede_ejecutar_rpc,
  to_regprocedure('public.ficoesa_tourist_image_is_published(text)') is not null as filtro_imagenes_instalado;

-- Número de registros PUBLICADOS Y NO ARCHIVADOS en el directorio.
select
  count(*) filter (where content->>'status' = 'publicada'
      and coalesce(content->>'archived','false')='false') as publicadas_para_turista,
  count(*) filter (where content->>'status' = 'pendiente') as pendientes_no_publicas,
  count(*) as total_registros
from public.campaigns;

-- Cuando la RPC esté instalada, esta consulta debe devolver todas las
-- publicaciones visibles para Turista (no solo las 3 del carrusel):
-- select count(*) from public.ficoesa_tourist_feed();
-- select id, content->>'title' as titulo, content->>'realDate' as fecha
--   from public.ficoesa_tourist_feed() limit 10;
