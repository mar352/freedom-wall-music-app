# Android Firebase Setup Guide

## Yang Sudah Selesai ✅
- ✅ Google Services plugin ditambahkan ke `android/build.gradle.kts`
- ✅ Google Services plugin dikonfigurasi di `android/app/build.gradle.kts`
- ✅ File `google-services.json` sudah ada (placeholder)
- ✅ Firebase dependencies sudah ditambahkan di `pubspec.yaml`

## Yang Perlu Kamu Lakukan 🔧

### 1. Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Create a project" atau "Add project"
3. Masukkan nama project (contoh: "freedom-app")
4. Aktifkan Google Analytics (opsional)
5. Buat project

### 2. Tambahkan Android App ke Firebase
1. Di Firebase Console, klik "Add app" → Android
2. Masukkan package name: `com.example.freedomapp`
3. Download file `google-services.json`
4. Ganti file placeholder di `android/app/google-services.json` dengan file yang didownload

### 3. Aktifkan Firebase Services
Di Firebase Console, aktifkan layanan ini:

#### Firestore Database
1. Pergi ke "Firestore Database"
2. Klik "Create database"
3. Pilih "Start in test mode" (untuk development)
4. Pilih lokasi terdekat dengan pengguna

#### Authentication (Opsional)
1. Pergi ke "Authentication"
2. Klik "Get started"
3. Pergi ke tab "Sign-in method"
4. Aktifkan "Anonymous" authentication

#### Storage (Opsional)
1. Pergi ke "Storage"
2. Klik "Get started"
3. Pilih "Start in test mode"
4. Pilih lokasi

### 4. Test Setup
Jalankan aplikasi:
```bash
flutter clean
flutter pub get
flutter run
```

## Konfigurasi Package Name
Package name kamu: `com.example.freedomapp`

Pastikan package name ini sama dengan yang ada di:
- `android/app/build.gradle.kts` (line 24: `applicationId = "com.example.freedomapp"`)
- Firebase Console saat menambahkan Android app

## File yang Perlu Diganti

### `android/app/google-services.json`
Ganti file placeholder dengan file asli dari Firebase Console.

File ini berisi konfigurasi Firebase untuk Android app kamu.

## Firestore Security Rules (Development)
Untuk development, gunakan rules ini:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ Peringatan: Rules ini membolehkan siapa saja baca/tulis. Gunakan security rules yang proper untuk production!**

## Troubleshooting

### Masalah Umum:
1. **Build error**: Pastikan file `google-services.json` sudah diganti
2. **Package name tidak cocok**: Pastikan package name sama antara Firebase Console dan app
3. **Network error**: Cek koneksi internet dan status Firebase project
4. **Permission error**: Pastikan Firestore rules mengizinkan read/write

### Command Berguna:
```bash
# Clean dan rebuild
flutter clean
flutter pub get
flutter run

# Cek koneksi Firebase
flutter doctor
```

## Langkah Selanjutnya
Setelah Firebase dikonfigurasi:
1. Test membuat, membaca, update, dan hapus posts
2. Implementasi user authentication jika diperlukan
3. Tambahkan fitur upload gambar menggunakan Firebase Storage
4. Setup security rules yang proper untuk production
5. Pertimbangkan implementasi real-time updates menggunakan Firestore streams

## Support
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
