-- ============================================================
-- Skema Database Ngadu (Aplikasi Aduan Fasilitas Kampus) v1.0
-- Platform: Supabase (PostgreSQL + RLS + Storage)
-- ============================================================

-- Ekstensi UUID
create extension if not exists "uuid-ossp";

-- ------------------------------------------------------------
-- 1. Tabel Profil Pengguna (Sinkron dengan auth.users)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  name text not null,
  role text not null check (role in ('pelapor', 'admin')) default 'pelapor',
  created_at timestamp with time zone default now()
);

-- RLS Profil
alter table public.profiles enable row level security;

create policy "Profil dapat dibaca oleh pengguna terautentikasi"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Pengguna dapat mengubah profil sendiri"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id);

create policy "Pengguna dapat memasukkan baris profil sendiri"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- Trigger otomatis saat user register via Supabase Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    'pelapor'
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- 2. Tabel Aduan Kerusakan (Complaints)
-- ------------------------------------------------------------
create table if not exists public.complaints (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid references public.profiles(id) on delete set null,
  reporter_name text not null,
  title text not null,
  description text not null,
  category text not null check (
    category in (
      'Listrik & AC',
      'Bangunan & Furnitur',
      'Jalan & Area Luar',
      'Kebersihan',
      'Lainnya'
    )
  ),
  building text not null,
  floor_room text not null,
  latitude double precision not null,
  longitude double precision not null,
  photo_url text not null,
  status text not null check (
    status in (
      'Menunggu Verifikasi',
      'Sedang Diproses',
      'Selesai',
      'Ditolak'
    )
  ) default 'Menunggu Verifikasi',
  admin_note text,
  proof_photo_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indeks query
create index if not exists idx_complaints_created_at on public.complaints (created_at desc);
create index if not exists idx_complaints_reporter on public.complaints (reporter_id);
create index if not exists idx_complaints_status on public.complaints (status);

-- RLS Aduan
alter table public.complaints enable row level security;

-- Siapa pun yang login boleh melihat feed aduan
create policy "Aduan dapat dibaca pengguna terautentikasi"
  on public.complaints for select
  to authenticated
  using (true);

-- Pelapor boleh membuat aduan baru
create policy "Pelapor boleh membuat aduan"
  on public.complaints for insert
  to authenticated
  with check (auth.uid() = reporter_id);

-- Aturan bisnis: Pelapor hanya boleh menghapus jika milik sendiri & status Menunggu
create policy "Pelapor hanya boleh hapus aduan status Menunggu"
  on public.complaints for delete
  to authenticated
  using (
    auth.uid() = reporter_id
    and status = 'Menunggu Verifikasi'
  );

-- Admin boleh mengubah status dan catatan apa pun
create policy "Admin boleh memperbarui status aduan"
  on public.complaints for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- ------------------------------------------------------------
-- 3. Storage Bucket: complaint_photos
-- ------------------------------------------------------------
-- Jalankan di Dashboard Supabase > Storage:
-- 1. Buat bucket bernama: complaint_photos (Public: true)
-- 2. Tambahkan policy:
--    - SELECT: authenticated (atau public)
--    - INSERT: authenticated
