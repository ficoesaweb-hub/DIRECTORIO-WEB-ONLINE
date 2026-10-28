-- FICOESA CREATIVE HUB V3.0 - Rol TURISTA sin login + Tablon informativo.
-- EJECUTAR UNICAMENTE EN EL PROYECTO SUPABASE DEL DIRECTORIO (no en FICOESA CONNECT).
-- Revisar primero las politicas y objetos existentes; ejecutar como propietario de las tablas.
-- No modifica las politicas de lectura de cuentas autenticadas ni los datos existentes.

begin;

-- Publicaciones del turista: la RPC expone exclusivamente la informacion editorial
-- de campañas publicadas y no archivadas. NO concede SELECT sobre la tabla campaigns a anon.
create or replace function public.ficoesa_tourist_feed()
returns table (id text, content jsonb)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id::text,
         jsonb_build_object(
           'title', coalesce(c.content->>'title', ''),
           'ref', coalesce(c.content->>'ref', ''),
           'cat', coalesce(c.content->>'cat', 'otros'),
           'group', coalesce(c.content->>'group', ''),
           'description', coalesce(c.content->>'description', ''),
           'status', 'publicada',
           'archived', false,
           'plannedDate', coalesce(c.content->>'plannedDate', ''),
           'realDate', coalesce(c.content->>'realDate', ''),
           'createdAt', coalesce(c.content->>'createdAt', ''),
           'coverId', coalesce(c.content->>'coverId', ''),
           'images', coalesce(
             (select jsonb_agg(jsonb_build_object(
                 'id', img->>'id',
                 'name', coalesce(img->>'name', ''),
                 'w', coalesce(img->'w', '0'::jsonb),
                 'h', coalesce(img->'h', '0'::jsonb)
               ))
              from jsonb_array_elements(case when jsonb_typeof(c.content->'images')='array'
                  then c.content->'images' else '[]'::jsonb end) img
              where img ? 'id' and length(img->>'id') > 0),
             '[]'::jsonb
           ),
           'posts', coalesce(
             (select jsonb_agg(jsonb_build_object(
                'net', coalesce(post->>'net','otras'),
                'planned',coalesce(post->>'planned',''),
                'real',coalesce(post->>'real',''),
                'status','publicada',
                'url',coalesce(post->>'url','')
              ))
              from jsonb_array_elements(case when jsonb_typeof(c.content->'posts')='array'
                 then c.content->'posts' else '[]'::jsonb end) post
              where post->>'status' = 'publicada'),
             '[]'::jsonb)
         ) as content
    from public.campaigns c
   where c.content->>'status' = 'publicada'
     and coalesce((c.content->>'archived')::boolean,false) = false
   order by coalesce(c.content->>'realDate', c.content->>'plannedDate', c.created_at::text) desc;
$$;

revoke all on function public.ficoesa_tourist_feed() from public;
grant execute on function public.ficoesa_tourist_feed() to anon, authenticated;

-- Un turista solo puede solicitar enlaces firmados de archivos utilizados por
-- campañas publicadas. Los demás objetos del bucket siguen privados.
create or replace function public.ficoesa_tourist_image_is_published(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.campaigns c
    where c.content->>'status' = 'publicada'
      and coalesce((c.content->>'archived')::boolean,false) = false
      and exists (
        select 1
        from jsonb_array_elements(case when jsonb_typeof(c.content->'images')='array'
          then c.content->'images' else '[]'::jsonb end) img
        where img->>'id' = p_path
      )
  );
$$;
revoke all on function public.ficoesa_tourist_image_is_published(text) from public;
grant execute on function public.ficoesa_tourist_image_is_published(text) to anon, authenticated;

-- Supabase Storage utiliza SELECT para la creacion de URLs firmadas.
-- Las imagenes privadas NO SE CONVIERTEN en un bucket publico.
drop policy if exists "FICOESA turista imagenes publicadas" on storage.objects;
create policy "FICOESA turista imagenes publicadas" on storage.objects
for select to anon
using (bucket_id = 'campaign-images' and public.ficoesa_tourist_image_is_published(name));

-- Tablon pequeno de novedades. Solo los admins publican, editan o borran.
create table if not exists public.ficoesa_hub_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 100),
  body text not null check (char_length(trim(body)) between 1 and 1200),
  pinned boolean not null default false,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.ficoesa_hub_notes enable row level security;

-- RLS no admite CREATE POLICY IF NOT EXISTS; drop solo de las que gestiona esta migracion.
drop policy if exists "FICOESA tablón lectura pública" on public.ficoesa_hub_notes;
drop policy if exists "FICOESA tablón lectura admin" on public.ficoesa_hub_notes;
drop policy if exists "FICOESA tablón insertar admin" on public.ficoesa_hub_notes;
drop policy if exists "FICOESA tablón actualizar admin" on public.ficoesa_hub_notes;
drop policy if exists "FICOESA tablón eliminar admin" on public.ficoesa_hub_notes;
create policy "FICOESA tablón lectura pública" on public.ficoesa_hub_notes
for select to anon, authenticated using (published = true);
create policy "FICOESA tablón lectura admin" on public.ficoesa_hub_notes
for select to authenticated using (public.is_ficoesa_admin());
create policy "FICOESA tablón insertar admin" on public.ficoesa_hub_notes
for insert to authenticated with check (public.is_ficoesa_admin());
create policy "FICOESA tablón actualizar admin" on public.ficoesa_hub_notes
for update to authenticated using (public.is_ficoesa_admin()) with check (public.is_ficoesa_admin());
create policy "FICOESA tablón eliminar admin" on public.ficoesa_hub_notes
for delete to authenticated using (public.is_ficoesa_admin());

revoke all on public.ficoesa_hub_notes from anon, authenticated;
grant select on public.ficoesa_hub_notes to anon;
grant select, insert, update, delete on public.ficoesa_hub_notes to authenticated;
commit;

-- PRUEBAS OBLIGATORIAS DESPUES:
-- 1) Ventana incognito, sin login: "Estoy de visita" muestra solo publicadas.
-- 2) Incognito: /herramientas/ y /connect/ exigen autenticacion; URL directa no abre datos.
-- 3) Admin publica y despublica un aviso; desaparece/ aparece desde incógnito.
-- 4) Imagenes de campañas pendientes y archivadas NO crean URL firmada como anon.
-- 5) Comprobar que no existen otras politicas permisivas para el rol anon en
--    public.campaigns, storage.objects, toolbox o connect.
