-- CONSULTA DE SOLO LECTURA: ver si public.marketing_toolbox_items
-- permite insertar category = 'ferias' en la instalación actual.
-- Ejecutar en el Supabase de FICOESA Creative Hub (Caja de Herramientas).
SELECT
    c.column_name,
    c.data_type,
    c.udt_schema,
    c.udt_name,
    c.is_nullable
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'marketing_toolbox_items'
  AND c.column_name IN ('category','brand','subcategory');

SELECT
    con.conname AS restriccion,
    pg_get_constraintdef(con.oid) AS definicion
FROM pg_constraint con
WHERE con.conrelid = 'public.marketing_toolbox_items'::regclass
  AND con.contype = 'c'
ORDER BY con.conname;

-- Si category es ENUM, consulta sus valores actuales:
SELECT
    t.typname AS tipo,
    e.enumlabel AS valor
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE t.oid = (
    SELECT a.atttypid
    FROM pg_attribute a
    WHERE a.attrelid = 'public.marketing_toolbox_items'::regclass
      AND a.attname = 'category'
      AND a.attnum > 0
      AND NOT a.attisdropped
)
ORDER BY e.enumsortorder;
