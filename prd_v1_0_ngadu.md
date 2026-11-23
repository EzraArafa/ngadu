# Product Requirements Document (PRD) — Ngadu

| Informasi Dokumen | Detail | 
| ----- | ----- | 
| **Nama Produk** | Ngadu (Aplikasi Aduan Fasilitas Kampus) | 
| **Versi Dokumen** | v1.0 (MVP) | 
| **Status** | Final - Siap Masuk Tahap Desain & Teknis | 
| **Platform Target** | Mobile (Android / iOS) | 

## 1. Ringkasan Produk & Masalah Utama

### 1.1 Latar Belakang Masalah

Mahasiswa, dosen, dan staf kampus sering menemukan kerusakan fasilitas di lingkungan kampus (seperti AC ruang kelas mati, proyektor rusak, toilet bermasalah, atau jalan area kampus berlubang). Namun, pelaporan sering terhambat karena:

* Jalur pelaporan yang tidak terpusat dan membingungkan.

* Sulitnya mendeskripsikan titik lokasi kerusakan secara akurat kepada petugas.

* Tidak adanya transparansi mengenai apakah laporan sudah diterima, sedang dikerjakan, atau telah selesai diperbaiki.

### 1.2 Solusi Utama

**Ngadu** adalah aplikasi mobile terpusat untuk melaporkan kerusakan fasilitas di lingkungan kampus secara cepat dan transparan. Aplikasi ini mengandalkan mekanisme **Lokasi Hibrida** (kombinasi koordinat GPS otomatis dan detail gedung/ruangan) serta pembaruan status penanganan berbasis bukti visual.

### 1.3 Proposisi Nilai (*Value Proposition*)

> *"Aplikasi **Ngadu** membantu **civitas akademika kampus** untuk **melaporkan dan memantau perbaikan fasilitas rusak** dengan cara **pengaduan visual berbasis lokasi hibrida yang terhubung langsung dengan pengelola sarana dan prasarana**."*

## 2. Target Pengguna & Hak Akses (*User Roles*)

Untuk menjaga efisiensi pengembangan pada versi pertama (MVP), sistem menggunakan pendekatan **Single App with Role-Based UI** (satu aplikasi mobile untuk semua pengguna dengan tampilan menu yang menyesuaikan peran akun):

1. **Pelapor (Mahasiswa / Dosen / Staf Kampus):**

   * Membuat laporan aduan kerusakan baru.

   * Melihat daftar seluruh aduan fasilitas di lingkungan kampus.

   * Memantau riwayat dan progres status aduan yang dibuat sendiri.

   * Menghapus aduan pribadi selama statusnya masih *Menunggu Verifikasi*.

2. **Admin (Pengelola Sarana & Prasarana Kampus):**

   * Melihat seluruh aduan masuk dari seluruh area kampus.

   * Memverifikasi laporan dan memperbarui status penanganan (*Menunggu Verifikasi* → *Sedang Diproses* → *Selesai* atau *Ditolak*).

   * Mengunggah foto bukti perbaikan saat mengubah status menjadi *Selesai*.

## 3. Ruang Lingkup Fitur MVP (Metode MoSCoW)

### 3.1 Must-Have (Wajib Ada di Rilis v1.0)

* **Autentikasi Pengguna:** Registrasi akun baru dan Login menggunakan email serta kata sandi.

* **Form Buat Aduan (Lokasi Hibrida):**

  * Pengambilan foto bukti langsung menggunakan kamera dalam aplikasi.

  * Penangkapan titik koordinat GPS (`latitude` & `longitude`) secara otomatis.

  * Pemilihan **Kategori Kerusakan** (Listrik & AC, Bangunan & Furnitur, Jalan & Area Luar, Kebersihan, Lainnya).

  * Pemilihan **Gedung / Zona Kampus** (*Dropdown*) serta isian teks **Lantai & Ruangan / Patokan**.

  * Kolom **Judul & Deskripsi Singkat** kerusakan.

* **Beranda / Feed Aduan Kampus:** Daftar seluruh aduan yang masuk dilengkapi fitur pencarian dan filter berdasarkan **Status** serta **Kategori**.

* **Halaman Aduan Saya:** Daftar khusus riwayat aduan yang dikirimkan oleh pengguna yang sedang login.

* **Halaman Detail Aduan:** Menampilkan foto kerusakan awal, peta titik koordinat, detail gedung/ruangan, informasi pelapor, linimasa status, serta foto bukti perbaikan (jika sudah selesai).

* **Panel Kontrol Admin (Dalam Halaman Detail):** Tombol khusus untuk akun `admin` guna mengubah status aduan, menambahkan catatan petugas, dan mengunggah foto bukti penyelesaian.

### 3.2 Should-Have (Penting, Rencana Pengembangan Tahap 2)

* **Konfirmasi / Upvote Aduan (*"Ikut Melaporkan"*):** Fitur bagi pengguna lain untuk mendukung aduan yang sudah ada agar tidak terjadi duplikasi laporan pada kerusakan yang sama.

* **Push Notification:** Notifikasi otomatis ke perangkat pelapor saat status aduan diperbarui oleh Admin.

### 3.3 Won't-Have (Ditunda / Di luar Cakupan v1.0)

* Fitur *live chat* atau komentar terbuka antar pengguna di halaman aduan.

* Integrasi Single Sign-On (SSO) sistem akademik kampus.

* *Dashboard* analitik statistik kerusakan bulanan dalam bentuk grafik kompleks.

## 4. *User Stories* & Kriteria Keberhasilan (*Acceptance Criteria*)

### US-01: Membuat Laporan Kerusakan

> *"Sebagai **Pelapor**, saya ingin **mengambil foto kerusakan secara langsung dan melengkapinya dengan titik GPS serta detail gedung/ruangan**, sehingga **petugas kampus dapat menemukan lokasi kerusakan secara akurat tanpa perlu bertanya ulang**."*

* **Acceptance Criteria:**

  * Kamera langsung terbuka saat pengguna menekan tombol buat aduan.

  * Titik GPS terisi otomatis dan tampil dalam pratinjau peta kecil.

  * Tombol **Kirim Aduan** hanya aktif apabila foto, kategori, gedung, detail ruangan, dan deskripsi telah diisi.

### US-02: Melihat Aduan Sekitar untuk Mencegah Laporan Ganda

> *"Sebagai **Pelapor**, saya ingin **melihat daftar aduan fasilitas yang sudah masuk di beranda**, sehingga **saya tahu apakah kerusakan yang saya temukan sudah pernah dilaporkan oleh orang lain**."*

* **Acceptance Criteria:**

  * Beranda menampilkan daftar aduan terbaru secara urut waktu.

  * Pengguna dapat menyaring aduan berdasarkan kategori atau status.

### US-03: Memantau Progres Penanganan

> *"Sebagai **Pelapor**, saya ingin **melihat status terbaru dari aduan yang saya kirim**, sehingga **saya mendapat kepastian bahwa laporan tersebut benar-benar ditindaklanjuti**."*

* **Acceptance Criteria:**

  * Halaman *Aduan Saya* menampilkan lencana (*badge*) status terkini pada setiap kartu aduan.

  * Halaman detail menampilkan catatan dari Admin serta foto bukti apabila status sudah *Selesai*.

### US-04: Menindaklanjuti dan Menyelesaikan Aduan

> *"Sebagai **Admin**, saya ingin **mengubah status aduan dan mengunggah foto bukti perbaikan**, sehingga **pelapor dapat melihat bukti fisik bahwa fasilitas telah kembali layak pakai**."*

* **Acceptance Criteria:**

  * Panel ubah status hanya muncul jika akun yang login memiliki peran `admin`.

  * Saat Admin memilih status `Selesai`, sistem mewajibkan pengunggahan minimal satu foto bukti perbaikan.

## 5. Aturan Bisnis (*Business Rules*)

1. **Integritas Foto Awal:** Foto bukti kerusakan awal **wajib diambil langsung dari kamera** melalui aplikasi (opsi memilih dari galeri dinonaktifkan) untuk mencegah manipulasi foto lama atau laporan palsu. Foto bukti penyelesaian oleh Admin diperbolehkan dari kamera maupun galeri.

2. **Penguncian Data Aduan:** Pelapor hanya dapat menghapus aduan miliknya selama status aduan masih `Menunggu Verifikasi`. Apabila Admin telah memproses aduan (`Sedang Diproses` atau `Selesai`), aduan tidak dapat dihapus oleh pelapor demi menjaga rekam jejak kerja petugas.

3. **Penetapan Hak Akses:** Seluruh pendaftaran akun baru melalui aplikasi otomatis diberikan peran `pelapor`. Perubahan peran menjadi `admin` hanya dilakukan secara manual melalui pengelolaan database oleh pengembang/administrator utama.

4. **Alur Status Baku:** Setiap aduan baru otomatis memiliki status awal `Menunggu Verifikasi`, dengan urutan transisi status: `Menunggu Verifikasi` → `Sedang Diproses` → `Selesai` (atau `Ditolak` dengan alasan wajib dari Admin).