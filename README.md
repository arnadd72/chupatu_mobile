# 👟 Chupatu - Premium Shoe Care & Logistics Ecosystem

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Laravel](https://img.shields.io/badge/laravel-%23FF2D20.svg?style=for-the-badge&logo=laravel&logoColor=white)
![Google Maps](https://img.shields.io/badge/Google%20Maps-%234285F4.svg?style=for-the-badge&logo=googlemaps&logoColor=white)

**Chupatu** adalah ekosistem aplikasi penyedia layanan perawatan dan cuci sepatu premium berbasis *mobile*. Dibangun dengan arsitektur modern, aplikasi ini mengintegrasikan layanan pelanggan, sistem logistik dengan pelacakan GPS *real-time*, integrasi *payment gateway*, dan notifikasi *push* otomatis menggunakan perpaduan teknologi Flutter, Firebase, dan REST API Laravel.

---

## 📸 Tampilan Aplikasi (Screenshots)
*(Tambahkan URL gambar *screenshot* aplikasi Anda di sini)*
---

## ✨ Fitur Utama (Key Features)

### 🧑‍💻 Sisi Pelanggan (Customer App)
* **Interactive Map Picker:** Pemilihan alamat penjemputan/pengantaran secara visual dan presisi menggunakan Google Maps API & Geocoding.
* **Live Order Tracking (Uber/Gojek Style):** Memantau pergerakan kurir secara *real-time* di atas peta, lengkap dengan animasi garis rute (*Polyline*) dinamis dan kustom ikon kurir.
* **My Garage:** Fitur inventaris sepatu digital milik pengguna untuk mempercepat proses pemesanan selanjutnya.
* **Real-time Chat:** Fitur *live chat* dua arah dengan Admin/Kurir untuk koordinasi pesanan (Didukung oleh Firebase Firestore).
* **Secure Payment & Promo:** Terintegrasi dengan simulasi *payment gateway* (Midtrans) & sistem *Cash on Delivery* (COD), lengkap dengan validasi kode promo.
* **Security PIN Authentication:** Autentikasi 6-digit PIN untuk lapisan keamanan tambahan sebelum melakukan validasi *checkout*.
* **Digital Invoice & Barcode:** Ekspor detail pesanan menjadi file PDF (*Invoice*) secara otomatis dan pemindai Barcode/QR Code untuk identifikasi pesanan yang unik.

### 👨‍💼 Sisi Admin / Kurir (Admin App)
* **Comprehensive Order Management:** Sistem pembaruan status pesanan secara terstruktur (Pending -> Confirmed -> Picked Up -> Processing -> Delivery -> Done).
* **Smart GPS Broadcaster:** Memancarkan koordinat GPS admin secara *real-time* ke Firebase Firestore menggunakan *distance filter* (menghemat baterai) ketika status pesanan adalah "Picked Up" atau "Delivery".
* **Automated FCM Push Notifications:** Memicu notifikasi ke perangkat pelanggan setiap kali status berubah via tembakan API ke Backend Laravel.
* **Magic Result (Proof of Work):** Fitur unggah foto hasil akhir cucian sepatu untuk dikirimkan langsung ke pelanggan.
* **Barcode Generator & Share:** Pembuatan barcode otomatis untuk identifikasi fisik sepatu, dilengkapi fitur *Share* gambar beresolusi tinggi.

---

## 🛠️ Tech Stack & Architecture

Aplikasi ini menggunakan pendekatan pemisahan layanan untuk memastikan skalabilitas dan performa yang optimal:

* **Frontend Mobile:** Flutter (Dart)
* **Backend as a Service (BaaS):** * **Firebase Firestore:** Database NoSQL untuk *real-time state* (Chat, Tracking, Status).
  * **Firebase Authentication:** Manajemen sesi pengguna.
  * **Firebase Storage:** Penyimpanan *cloud* untuk media/foto.
* **Backend Services (REST API):** Laravel (PHP)
  * Digunakan sebagai *controller* untuk *Push Notifications* (Firebase Cloud Messaging).
  * Menangani *upload processing* gambar tingkat lanjut.
* **Maps, Geolocation & Routing:** * Google Maps SDK for Flutter.
  * Google Directions API (REST HTTP) untuk pembuatan jalur algoritma secara *native*.
  * Geolocator & Geocoding.
* **State Management & UI:** Shared Preferences, Lottie Animations, Google Fonts.

---

## 🧠 Highlight Engineering & Best Practices

Sebagai aplikasi dengan performa tinggi, beberapa pendekatan teknis tingkat lanjut diterapkan pada proyek ini:

**1. Native API Call for Polyline Routing**
Menghindari penggunaan *package* pihak ketiga yang tidak stabil (`flutter_polyline_points`) dengan melakukan HTTP Call langsung ke *Google Directions API* dan menerjemahkan data mentah menggunakan algoritma *decoder* bitwise milik sendiri. Hal ini memangkas ukuran *build* dan mencegah *dependency conflicts*.

**2. Efficient GPS Broadcasting**
Modul *Live Tracking* kurir menggunakan `Geolocator.getPositionStream` dengan *locationSettings* yang diatur pada akurasi tinggi namun dibatasi oleh `distanceFilter: 10`. Hal ini mencegah aplikasi mengirim *request* berlebihan ke Firestore jika kurir sedang berhenti, sehingga sangat menghemat baterai dan kuota *read/write* *database*.

**3. Asset Optimization**
Penggunaan `ImageConfiguration` dan `getBytesFromAsset` (atau proses *resize* manual) untuk kustomisasi *marker* peta guna meminimalkan lonjakan penggunaan RAM pada perangkat pengguna saat memuat peta.

---

## 🚀 Panduan Instalasi (Getting Started)

Ikuti langkah-langkah di bawah ini untuk mengonfigurasi dan menjalankan *project* secara lokal.

### 1. Persyaratan Sistem (Prerequisites)
* **Flutter SDK** (Versi stabil terbaru, min. 3.10.x)
* **Dart SDK**
* **Laravel Environment** (PHP 8.x, Composer) untuk menjalankan API *backend*.
* Akun **Firebase** (Telah dikonfigurasi).
* Akun **Google Cloud Platform** (Untuk *API Key Maps & Directions*).

### 2. Kloning Repositori
```bash
git clone [https://github.com/USERNAME_ANDA/chupatu_mobile.git](https://github.com/USERNAME_ANDA/chupatu_mobile.git)
cd chupatu_mobile
```

3. Konfigurasi Backend API (Laravel)
Jika Anda menggunakan local environment, jalankan backend Laravel Anda dan expose port tersebut menggunakan ngrok agar dapat diakses oleh aplikasi mobile.

Bash
# Di direktori proyek Laravel Anda
```bash
php artisan serve
ngrok http 8000
```
Salin URL ngrok yang dihasilkan dan masukkan ke dalam ApiConfig pada proyek Flutter Anda.

4. Konfigurasi Google Maps API Key
Anda memerlukan API Key dari Google Cloud Console dengan layanan berikut yang diaktifkan:

Maps SDK for Android / iOS

Directions API

Untuk Android: Buka file **android/app/src/main/AndroidManifest.xml** dan tambahkan:

XML
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="MASUKKAN_API_KEY_ANDA_DI_SINI"/>
```
    
Untuk Kodingan Dart: Tambahkan API Key Anda pada variabel googleApiKey di dalam file konfigurasi terkait (contoh: order_detail_page.dart).

5. Konfigurasi Firebase
Buat proyek baru di Firebase Console.

Tambahkan aplikasi Android dan unduh file **google-services.json**.

Letakkan file **google-services.json** di dalam direktori **android/app/**.

6. Install Dependencies & Run
Unduh semua package Flutter yang dibutuhkan:

```Bash
flutter pub get
flutter clean
```
Jalankan aplikasi pada emulator atau perangkat fisik (sangat disarankan menggunakan perangkat fisik untuk pengujian GPS yang akurat):

```Bash
flutter run
```
