# User Flow & Wireframe (Low-Fidelity) — Ngadu

| Informasi Dokumen | Detail |
| :--- | :--- |
| **Nama Produk** | Ngadu (Aplikasi Aduan Fasilitas Kampus) |
| **Versi Dokumen** | v1.0 (MVP) |
| **Referensi Utama** | `PRD_Ngadu_v1.md` |
| **Tujuan Dokumen** | Pemetaan inventaris layar, alur navigasi pengguna, tata letak komponen (*wireframe*), dan kondisi batas (*edge cases*) sebelum tahap desain database & coding. |

---

## 1. Inventaris Layar (*Screen Inventory*)

Berdasarkan ruang lingkup fitur *Must-Have* pada PRD v1.0, aplikasi **Ngadu** terdiri dari **7 layar utama** dengan pola navigasi *Bottom Navigation Bar*:

1. **Layar Autentikasi:**
   * **S-01 `Splash Screen`:** Pengecekan sesi login pengguna secara otomatis.
   * **S-02 `Auth Screen (Login & Register)`:** Halaman masuk dan pendaftaran akun baru menggunakan email & kata sandi.
2. **Navigasi Utama (*Bottom Navigation Bar*):**
   * **S-03 `Beranda (Feed Aduan)`:** Daftar seluruh laporan kerusakan fasilitas kampus dilengkapi pencarian dan filter.
   * **S-04 `Form Buat Aduan`:** Layar pengisian laporan baru (diakses melalui tombol aksi utama di tengah *bottom bar*).
   * **S-05 `Aduan Saya & Profil`:** Daftar riwayat aduan yang dibuat oleh pengguna yang sedang login beserta info profil/peran akun.
3. **Layar Detail & Aksi Lanjutan:**
   * **S-06 `Detail Aduan`:** Rincian lengkap aduan, foto awal, mini-map GPS, linimasa status, foto bukti perbaikan, serta panel aksi kondisional sesuai *role*.
   * **S-07 `Modal Update Status (Khusus Admin)`:** *Bottom sheet* / modal bagi Admin untuk memperbarui status aduan, menambah catatan, dan mengunggah foto bukti selesai.

---

## 2. Alur Pengguna (*User Flow*)

Konvensi simbol diagram:
* `[ Persegi ]` : Layar / Halaman UI (*Screen*)
* `( Kapsul )` : Aksi Pengguna atau Proses Sistem
* `{ Belah Ketupat }` : Percabangan Logika / Validasi

### 2.1 Alur A: Autentikasi Pengguna
```text
[S-01: Splash Screen]
         │
         ▼
 {Sesi Login Aktif?} ──── Ya ────► [S-03: Beranda]
         │
       Tidak
         ▼
[S-02: Auth Screen]
  ├── Tab Masuk: (Input Email & Password) ──► {Valid?} ── Ya ──► [S-03: Beranda]
  └── Tab Daftar: (Input Nama, Email, Password) ──► (Set Role = "pelapor") ──► [S-03: Beranda]
```

### 2.2 Alur B: Pelapor Membuat Aduan Baru (Alur Inti)
```text
[S-03: Beranda]
       │
       ▼ (Tap tombol "+ Buat Aduan")
{Izin Kamera & GPS Aktif?} ── Tidak ──► [Dialog Permintaan Izin Perangkat]
       │
       Ya
       ▼
[Kamera Perangkat Terbuka]
       │
       ▼ (Ambil Foto Bukti Kerusakan) ──► (Sistem Kunci Koordinat GPS Otomatis)
       ▼
[S-04: Form Buat Aduan]
  ├── Tampilkan preview foto & mini-map titik GPS
  ├── (Pilih Kategori: Listrik/AC, Bangunan, Jalan/Taman, Kebersihan, Lainnya)
  ├── (Pilih Gedung/Zona Kampus & Isi Lantai/Ruangan)
  └── (Isi Judul & Deskripsi Singkat)
       │
       ▼ (Tap "Kirim Aduan")
{Semua Field Wajib Terisi?} ── Tidak ──► (Tampilkan Pesan Validasi pada Kolom Kosong)
       │
       Ya
       ▼
(Upload Foto ke Storage & Simpan Data dengan Status = "Menunggu Verifikasi")
       │
       ▼
[S-06: Detail Aduan] (Menampilkan laporan yang baru saja terkirim)
```

### 2.3 Alur C: Detail Aduan & Pembedaan Hak Akses (Pelapor vs. Admin)
```text
[S-03: Beranda / S-05: Aduan Saya]
               │
               ▼ (Tap salah satu kartu aduan)
       [S-06: Detail Aduan]
               │
       ┌───────┴───────────────────────────────────────┐
       ▼                                               ▼
{Role == Pelapor}                               {Role == Admin}
       │                                               │
{Milik Sendiri & Status == "Menunggu"?}        (Tap "Tindak Lanjuti Aduan")
  ├── Ya  ──► Tampil tombol [Hapus Aduan]              │
  │             └── (Konfirmasi Hapus) ──► [S-03]      ▼
  └── Tidak ──► Tombol hapus disembunyikan     [S-07: Modal Update Status]
                                                 ├── Pilih Status: Diproses / Selesai / Ditolak
                                                 ├── Upload Foto Bukti (Wajib jika "Selesai")
                                                 └── Isi Catatan Petugas ──► (Simpan) ──► [S-06]
```

---

## 3. Wireframe Kasar (*Low-Fidelity*)

### 3.1 Layar Autentikasi (`S-02: Auth Screen`)
```text
+-----------------------------------+
|                                   |
|          [ LOGO NGADU ]           |
|     Aduan Fasilitas Kampus        |
|                                   |
|  +-------------+---------------+  |
|  |   Masuk     |    Daftar     |  |
|  +-------------+---------------+  |
|                                   |
|  Email Kampus / Pribadi           |
|  [ nama@kampus.ac.id           ]  |
|                                   |
|  Kata Sandi                       |
|  [ ••••••••••••           (o)  ]  |
|                                   |
|  [            MASUK            ]  |
|                                   |
+-----------------------------------+
```

### 3.2 Beranda (`S-03`) & Form Buat Aduan (`S-04`)
```text
+-----------------------------------+      +-----------------------------------+
|  NGADU             [Ikon Filter]  |      |  <-  Buat Aduan Baru              |
|  [ Semua ] [ Menunggu ] [ Proses ]|      |-----------------------------------|
|-----------------------------------|      |  +-----------------------------+  |
|  +-----------------------------+  |      |  |    [ Preview Foto Kamera ]  |  |
|  | [Foto]  AC Bocor Ruang 302  |  |      |  |         [ Foto Ulang ]      |  |
|  |         Gedung Teknik       |  |      |  +-----------------------------+  |
|  |         [Status: Menunggu]  |  |      |  [ Mini-Map GPS: -7.765, 110.37 ] |
|  +-----------------------------+  |      |                                   |
|  +-----------------------------+  |      |  Kategori *                       |
|  | [Foto]  Jalan Parkir Berlubang |      |  [ Pilih Kategori           v ]   |
|  |         Area Parkir Utara   |  |      |  Gedung / Zona *                  |
|  |         [Status: Selesai]   |  |      |  [ Pilih Gedung             v ]   |
|  +-----------------------------+  |      |  Lantai & Ruangan / Patokan *     |
|                                   |      |  [ Contoh: Lt. 3, Ruang 302   ]   |
|         ( + Buat Aduan )          |      |  Deskripsi Kerusakan *            |
|-----------------------------------|      |  [ Jelaskan kondisi singkat.. ]   |
|  [ Beranda ]         [ Aduan Saya ]      |  [        KIRIM ADUAN          ]  |
+-----------------------------------+      +-----------------------------------+
```

### 3.3 Aduan Saya (`S-05`) & Detail Aduan (`S-06`)
```text
+-----------------------------------+      +-----------------------------------+
|  Aduan Saya              [Logout] |      |  <-  Detail Aduan       [Hapus*]  |
|  Halo, Andi (Role: Pelapor)       |      |-----------------------------------|
|-----------------------------------|      |  +-----------------------------+  |
|  Total: 3 | Proses: 1 | Selesai: 2|      |  |    [ Foto Bukti Laporan ]   |  |
|-----------------------------------|      |  +-----------------------------+  |
|  +-----------------------------+  |      |  [Kategori: Listrik/AC] [Selesai] |
|  | [Foto]  AC Bocor Ruang 302  |  |      |  Gedung Teknik - Lt. 3, Ruang 302 |
|  |         12 Nov • [Proses]   |  |      |  "Air menetes deras dari unit AC" |
|  +-----------------------------+  |      |  Dilaporkan oleh: Andi • 2 jam lalu
|  +-----------------------------+  |      |-----------------------------------|
|  | [Foto]  Kursi Kuliah Patah  |  |      |  Lokasi Peta:                     |
|  |         05 Nov • [Selesai]  |  |      |  [ Mini-Map Pin Koordinat GPS ]   |
|  +-----------------------------+  |      |-----------------------------------|
|                                   |      |  Linimasa & Bukti Penanganan:     |
|                                   |      |  (v) Menunggu Verifikasi          |
|                                   |      |  (v) Sedang Diproses              |
|                                   |      |  (v) Selesai                      |
|                                   |      |  Catatan Admin: "Freon & saluran  |
|                                   |      |  pembuangan sudah diperbaiki."    |
|                                   |      |  +-----------------------------+  |
|                                   |      |  |  [ Foto Bukti Perbaikan ]   |  |
|                                   |      |  +-----------------------------+  |
|-----------------------------------|      |-----------------------------------|
|  [ Beranda ]         [ Aduan Saya ]      |  [    UPDATE STATUS (ADMIN)    ]  |
+-----------------------------------+      +-----------------------------------+
```
*(Catatan Wireframe `S-06`: Tombol `[Hapus*]` di pojok kanan atas hanya muncul untuk pemilik aduan saat status masih `Menunggu Verifikasi`. Tombol `[UPDATE STATUS (ADMIN)]` di bagian bawah hanya dirender apabila akun yang login memiliki peran `admin`.)*

### 3.4 Modal Update Status Admin (`S-07`)
```text
+-----------------------------------+
|  (Layar Detail Aduan Redup/Dim)   |
|                                   |
|===================================|
|  Tindak Lanjuti Aduan         [X] |
|-----------------------------------|
|  Ubah Status Penanganan *         |
|  ( ) Sedang Diproses              |
|  (•) Selesai                      |
|  ( ) Ditolak                      |
|                                   |
|  Foto Bukti Perbaikan *           |
|  (Wajib jika status = Selesai)    |
|  +-----------------------------+  |
|  |   [ + Ambil / Pilih Foto ]  |  |
|  +-----------------------------+  |
|                                   |
|  Catatan Petugas / Keterangan     |
|  [ Tulis catatan tindakan...   ]  |
|                                   |
|  [       SIMPAN PERUBAHAN      ]  |
+-----------------------------------+
```

---

## 4. Kondisi Batas (*Edge Cases & UI States*)

Setiap layar utama wajib menangani empat kondisi berikut agar pengalaman pengguna tetap informatif:

1. **Empty State (Data Kosong):**
   * Jika daftar aduan di `Beranda` atau `Aduan Saya` belum memiliki data (atau hasil filter tidak ditemukan), tampilkan ikon ilustrasi sederhana beserta teks *"Belum ada laporan kerusakan pada kategori ini"* dan tombol pintasan ke `Buat Aduan`.
2. **Loading State (Proses Muat / Unggah):**
   * Gunakan *skeleton loader* saat memuat daftar kartu aduan di beranda.
   * Nonaktifkan tombol `Kirim Aduan` dan tampilkan indikator *loading* saat proses kompresi dan pengunggahan foto berlangsung untuk mencegah pengiriman ganda (*double submit*).
3. **Permission Denied State (Izin Kamera / GPS Ditolak):**
   * Jika pengguna menolak izin kamera atau lokasi saat menekan `+ Buat Aduan`, tampilkan dialog penjelasan beserta tombol pintasan untuk membuka pengaturan aplikasi perangkat.
4. **Error / Offline State (Koneksi Terputus):**
   * Jika gagal mengirim data atau memuat daftar aduan akibat gangguan jaringan, tampilkan notifikasi *snackbar* beserta tombol `Coba Lagi` tanpa menghapus isian teks yang sudah diketik pengguna di form.