-- Run in Supabase > SQL Editor, in the FICOESA Creative Hub project.
-- Step 1: create tables/functions/policies; Step 2: register user in Authentication;
-- Step 3: run the final INSERT at the bottom to grant admin to ficoesaweb@gmail.com.
CREATE TABLE IF NOT EXISTS public.campaigns (
  id text PRIMARY KEY,
  content jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.ficoesa_admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ficoesa_admins ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_ficoesa_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$ SELECT EXISTS (SELECT 1 FROM public.ficoesa_admins WHERE user_id = (select auth.uid())); $$;
REVOKE ALL ON FUNCTION public.is_ficoesa_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_ficoesa_admin() TO anon, authenticated;

DROP POLICY IF EXISTS "Everyone reads campaign library" ON public.campaigns;
CREATE POLICY "Everyone reads campaign library" ON public.campaigns
FOR SELECT TO anon, authenticated USING (true);
-- This includes pending campaigns. If drafts must be private, replace with a
-- selective policy and adapt the admin/editor query accordingly.
DROP POLICY IF EXISTS "Only admins insert campaigns" ON public.campaigns;
CREATE POLICY "Only admins insert campaigns" ON public.campaigns
FOR INSERT TO authenticated WITH CHECK ((select public.is_ficoesa_admin()));
DROP POLICY IF EXISTS "Only admins update campaigns" ON public.campaigns;
CREATE POLICY "Only admins update campaigns" ON public.campaigns
FOR UPDATE TO authenticated USING ((select public.is_ficoesa_admin()))
WITH CHECK ((select public.is_ficoesa_admin()));
DROP POLICY IF EXISTS "Only admins delete campaigns" ON public.campaigns;
CREATE POLICY "Only admins delete campaigns" ON public.campaigns
FOR DELETE TO authenticated USING ((select public.is_ficoesa_admin()));
DROP POLICY IF EXISTS "Admins see their own admin membership" ON public.ficoesa_admins;
CREATE POLICY "Admins see their own admin membership" ON public.ficoesa_admins
FOR SELECT TO authenticated USING (user_id = (select auth.uid()));

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('campaign-images','campaign-images',true, 20971520, ARRAY['image/jpeg'])
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 20971520, allowed_mime_types = ARRAY['image/jpeg'];
DROP POLICY IF EXISTS "Admin uploads campaign images" ON storage.objects;
CREATE POLICY "Admin uploads campaign images" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'campaign-images' AND (select public.is_ficoesa_admin()));
DROP POLICY IF EXISTS "Admin deletes campaign images" ON storage.objects;
CREATE POLICY "Admin deletes campaign images" ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'campaign-images' AND (select public.is_ficoesa_admin()));
DROP POLICY IF EXISTS "Admin lists campaign images" ON storage.objects;
CREATE POLICY "Admin lists campaign images" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'campaign-images' AND (select public.is_ficoesa_admin()));

-- Enable realtime for cross-browser automatic refresh (safe to run once).
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.campaigns;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- STEP 3: Execute this statement AFTER the user exists in Authentication > Users.
-- If zero rows are inserted, confirm the exact email and account existence.
INSERT INTO public.ficoesa_admins (user_id)
SELECT id FROM auth.users WHERE lower(email) = 'ficoesaweb@gmail.com'
ON CONFLICT (user_id) DO NOTHING;
