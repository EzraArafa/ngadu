-- Jalankan skema ini di Supabase SQL Editor SETELAH supabase_schema.sql.
-- Memberikan hak akses tabel ke role 'authenticated' agar kebijakan RLS
-- dapat dievaluasi (RLS hanya memfilter baris, bukan menggantikan GRANT).

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.complaints TO authenticated;

-- Pastikan urutan sequence dapat dipakai
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Verifikasi tabel
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'complaints');
