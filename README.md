# Ngadu: Aplikasi Aduan Fasilitas Kampus

Ngadu adalah aplikasi mobile (Android & iOS) terpusat untuk melaporkan
kerusakan fasilitas di lingkungan kampus secara cepat dan transparan.
Aplikasi ini mengandalkan mekanisme **Lokasi Hibrida** (kombinasi
koordinat GPS otomatis dan detail gedung/ruangan) serta pembaruan
status penanganan berbasis bukti visual.

## Dokumen Referensi
- **PRD**: `prd_v1_0_ngadu.md`
- **Wireframe**: `user_flow_wireframe_v1_0_ngadu.md`
- **Skema DB**: `supabase_schema.sql`

## Teknologi
- **Frontend**: Flutter 3.13+, Dart 3.0
- **State Management**: `provider`
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Peta**: `flutter_map` (OpenStreetMap)
- **Kamera**: `image_picker` (hanya dari kamera untuk foto awal)
- **Lokasi**: `geolocator`

## Struktur Proyek
```
lib/
├─ main.dart                # Entry point, router, theme
├─ models/                  # Complaint, ComplaintCategory, ComplaintStatus, NgaduUser
├─ services/                # SupabaseService, LocationService
├─ providers/               # AuthController, ComplaintProvider, UiStateProvider
├─ screens/                 # 7 layar utama (Splash, Auth, Home, Form, My, Detail, AdminModal)
└─ widgets/                 # ComplaintCard, EmptyState, LoadingState, ErrorState
```

## Konfigurasi Supabase
1. Buat proyek Supabase, salin URL & anon key.
2. Jalankan `supabase_schema.sql` di Supabase SQL editor.
3. Buat Storage bucket `complaint_photos` (public).
4. Jalankan Flutter dengan flag:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=<url> \
     --dart-define=SUPABASE_ANON_KEY=<anon-key>
   ```

## Izin Aplikasi
- Android: `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
  `INTERNET` (lihat `android/app/src/main/AndroidManifest.xml`).
- iOS: `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`,
  `NSPhotoLibraryUsageDescription` (lihat `ios/Runner/Info.plist`).

## Aturan Bisnis (PRD)
1. Foto awal wajib diambil langsung dari kamera.
2. Pelapor hanya boleh meng deletes aduan miliknya bila status
   `Menunggu Verifikasi`.
3. Role `admin` ditetapkan secara manual di database.
4. Alur status: `Menunggu Verifikasi` → `Sedang Diproses` → `Selesai`
   (atau `Ditolak`).

## Pengujian
```bash
flutter test
```