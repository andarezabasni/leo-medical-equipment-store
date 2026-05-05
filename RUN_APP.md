Most Important
Tips: Sebelum copy, hapus folder build/ dan .dart_tool/ di leo_app
agar ukuran lebih kecil — nanti tinggal flutter pub get di laptop baru

# 1. Install Flutter + Git (sama seperti laptop lama)
# 2. Copy folder dari flashdisk ke laptop baru
# 3. Buka terminal di folder leo_app
flutter pub get

# 4. Jalankan backend
cd leo-backend
json-server --host 0.0.0.0 db.json

# 5. Jalankan flutter
cd leo_app
flutter run -d windows


## ▶️ Menjalankan Aplikasi sama saja

**Terminal 1 — Backend:**

```powershell
cd leo-backend
json-server --host 0.0.0.0 db.json
```

**Terminal 2 — Flutter:**

```powershell
cd leo_app
flutter run -d windows
```

> **Hot restart** = tekan `R` (kapital) di terminal Flutter.

## 🌐 Ganti IP Server (jika jaringan berbeda)

1. Cek IP laptop server: buka `CMD` → ketik `ipconfig` → lihat **IPv4 Address**
2. Buka aplikasi → halaman Login → klik **Pengaturan**
3. Masukkan `http://[IP_ANDA]:3000` → **Simpan** → **Test Koneksi**

## 🔧 Build Aplikasi

**Windows EXE:**

```powershell
cd leo_app
flutter build windows --release
```

Hasil: `leo_app\build\windows\x64\runner\Release\`

**Android APK:**

```powershell
cd leo_app
flutter build apk --release
```

Hasil: `leo_app\build\app\outputs\flutter-apk\app-release.apk`

> **Catatan:** Di device/client setelah install, buka **Pengaturan** → ganti IP server sesuai IP laptop yang menjalankan `json-server`.

## 🔑 Akun Login

| Role  | Email          | Password |
| ----- | -------------- | -------- |
| Admin | admin@leo.com  | admin123 |
| User  | budi@email.com | user123  |

