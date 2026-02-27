# 💰 Catatan Keuangan (Pribadi)

Aplikasi pencatatan keuangan pribadi premium yang dibangun menggunakan Flutter. Aplikasi ini membantu Anda mengelola, mencatat, dan menganalisis arus kas keuangan harian Anda dengan antarmuka pengguna yang modern, bersih, dan mudah digunakan.

## ✨ Fitur Utama

- **📝 Catat Pemasukan & Pengeluaran:** Tambahkan transaksi harian dengan mudah lewat form yang intuitif.
- **📊 Dashboard Dinamis:** Pantau total saldo saat ini, indikator kesehatan keuangan, dan grafik tren pengeluaran 7 hari terakhir.
- **🏷️ Kategori Terstruktur:** Pilih dari 15+ kategori bawaan yang sudah dilengkapi ikon dan warna estetik (Makanan, Transportasi, Gaji, dll.).
- **💾 Database Lokal Aman:** Data disimpan secara permanen, aman, dan tanpa perlu internet menggunakan SQLite (`sqflite`).
- **🔍 Pencarian & Filter:** Cari transaksi berdasarkan kategori atau deskripsi spesifik di Riwayat Transaksi.
- **📈 Laporan Komprehensif:** Bandingkan persentase pendapatan vs pengeluaran via Pie Chart dan amati breakdown alokasi dana secara mendetail.
- **🎨 Tema Terang Modern:** Dibangun dengan perpaduan warna Putih dan Biru yang bersih, shadow yang lembut, dan tipografi Poppins.

---

## 🚀 Instalasi & Menjalankan Proyek Secara Lokal

Pastikan Anda sudah menginstal **Flutter SDK** versi terbaru di perangkat Anda.

1. **Clone Repository ini:**
   ```bash
   git clone https://github.com/Dhani2612/catatan-keuangan.git
   ```

2. **Masuk ke direktori proyek:**
   ```bash
   cd catatan-keuangan
   ```

3. **Unduh seluruh package kelengkapan / dependencies:**
   ```bash
   flutter pub get
   ```

4. **Jalankan Aplikasi** (Bisa melalui Emulator Android/iOS, atau perangkat Web/Desktop):
   ```bash
   flutter run
   ```

---

## 🛠️ Teknologi yang Digunakan

Aplikasi ini menggunakan perpaduan framework dan package pub.dev berikut:

- **[Flutter](https://flutter.dev/):** UI Toolkit lintas platform.
- **[sqflite](https://pub.dev/packages/sqflite):** Package untuk integrasi SQLite Database di Flutter.
- **[path](https://pub.dev/packages/path):** Fungsi untuk memanipulasi path direktori database lokal.
- **[google_fonts](https://pub.dev/packages/google_fonts):** Package tipografi dinamis untuk mengunduh jenis huruf "Poppins".
- **[intl](https://pub.dev/packages/intl):** Untuk format _currency_ Rupiah (`Rp`) dan tanggal lokal.
- **[fl_chart](https://pub.dev/packages/fl_chart):** Library luar biasa untuk Pie Chart dan Bar Chart.

---

## 📁 Struktur Folder Utama

```text
lib/
├── models/
│   └── transaction.dart        # Model data transaksi & mapping SQLite
├── pages/
│   ├── home_page.dart          # Halaman depan (Dashboard + Navigasi)
│   ├── history_page.dart       # Daftar riwayat transaksi (Search, Edit, Delete)
│   ├── transaction_page.dart   # Form input (Add & Edit)
│   └── report_page.dart        # Laporan analisis Pie Chart & Kategori
├── services/
│   └── database_helper.dart    # Konfigurasi SQLite (Singleton CRUD)
├── utils/
│   ├── app_theme.dart          # Konfigurasi Tema (Warna, Font, Widget Style)
│   └── constants.dart          # Data statis (Daftar Kategori Pemasukan/Pengeluaran)
└── main.dart                   # Entry point aplikasi
```

---

## 🤝 Kontribusi

Aplikasi ini bersifat *Open Source* untuk tujuan portofolio dan pembelajaran. Silakan melakukan *fork* repositori ini, modifikasi kodenya, dan lakukan *Pull Request* jika Anda merasa ada fitur yang ingin ditambahkan!

## 📜 Lisensi

Aplikasi *Catatan Keuangan* ini dilisensikan di bawah [MIT License](LICENSE). Anda bebas untuk menggunakan, menyalin, memodifikasi, dan mendistribusikannya kembali.
