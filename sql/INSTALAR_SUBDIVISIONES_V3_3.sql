-- FICOESA CREATIVE HUB / CAJA DE HERRAMIENTAS V3.3
-- Ejecutar en SQL Editor de Supabase, en el MISMO proyecto que gestiona marketing_toolbox_items.
-- Crea solo la configuración de subdivisiones; no borra ni altera recursos existentes.
-- Requiere public.ficoesa_my_role() ya configurada y los roles admin/worker/boss existentes.
BEGIN;

CREATE TABLE IF NOT EXISTS public.marketing_toolbox_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL CHECK (category IN (
    'fichas','merchandising','plv','recursos','catalogos','ferias','novedades'
  )),
  name text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 2 AND 80),
  active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS marketing_toolbox_sections_unique_name
ON public.marketing_toolbox_sections (category, lower(btrim(name)));

ALTER TABLE public.marketing_toolbox_items
  ADD COLUMN IF NOT EXISTS section_id uuid NULL;
-- Si la columna ya existiese, esta operación solo crea la FK si falta.
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname='marketing_toolbox_items_section_id_fkey'
      AND conrelid='public.marketing_toolbox_items'::regclass
  ) THEN
    ALTER TABLE public.marketing_toolbox_items
    ADD CONSTRAINT marketing_toolbox_items_section_id_fkey
    FOREIGN KEY (section_id) REFERENCES public.marketing_toolbox_sections(id)
    ON DELETE RESTRICT;
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS marketing_toolbox_items_section_id_idx
ON public.marketing_toolbox_items(section_id);

-- Impide que se asigne a un recurso una subdivisión de otra categoría.
CREATE OR REPLACE FUNCTION public.ficoesa_verify_toolbox_section()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.section_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.marketing_toolbox_sections s
    WHERE s.id = NEW.section_id AND s.category = NEW.category AND s.active = true
  ) THEN
    RAISE EXCEPTION 'La subdivisión no existe, está inactiva o no corresponde a esta categoría';
  END IF;
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS ficoesa_verify_toolbox_section ON public.marketing_toolbox_items;
CREATE TRIGGER ficoesa_verify_toolbox_section BEFORE INSERT OR UPDATE
  OF category, section_id ON public.marketing_toolbox_items
  FOR EACH ROW EXECUTE FUNCTION public.ficoesa_verify_toolbox_section();

ALTER TABLE public.marketing_toolbox_sections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Toolbox sections role read" ON public.marketing_toolbox_sections;
DROP POLICY IF EXISTS "Toolbox sections admin write" ON public.marketing_toolbox_sections;
DROP POLICY IF EXISTS "Toolbox sections admin update" ON public.marketing_toolbox_sections;
DROP POLICY IF EXISTS "Toolbox sections admin delete" ON public.marketing_toolbox_sections;

CREATE POLICY "Toolbox sections role read" ON public.marketing_toolbox_sections
  FOR SELECT TO authenticated
  USING (public.ficoesa_my_role() IN ('admin','worker','boss'));
CREATE POLICY "Toolbox sections admin write" ON public.marketing_toolbox_sections
  FOR INSERT TO authenticated WITH CHECK (public.ficoesa_my_role() = 'admin');
CREATE POLICY "Toolbox sections admin update" ON public.marketing_toolbox_sections
  FOR UPDATE TO authenticated USING (public.ficoesa_my_role() = 'admin')
  WITH CHECK (public.ficoesa_my_role() = 'admin');
CREATE POLICY "Toolbox sections admin delete" ON public.marketing_toolbox_sections
  FOR DELETE TO authenticated USING (public.ficoesa_my_role() = 'admin');

REVOKE ALL ON public.marketing_toolbox_sections FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.marketing_toolbox_sections TO authenticated;
-- La nueva columna de items hereda las políticas RLS existentes de la tabla.
COMMIT;
NOTIFY pgrst, 'reload schema';

-- Verificar:
-- SELECT id, category, name FROM public.marketing_toolbox_sections ORDER BY category, sort_order;
-- SELECT count(*) FROM public.marketing_toolbox_items WHERE section_id IS NULL;
