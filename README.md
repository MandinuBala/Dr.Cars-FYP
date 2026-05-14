# 🚗 DR.Cars — Vehicle Management Mobile App

<p align="center">
  <img src="assets/images/logo.png" alt="DR.Cars Logo" width="120"/>
</p>

<p align="center">
  A Flutter-based mobile application for vehicle owners, service centers, and administrators — featuring OBD2 diagnostics, 3D vehicle model viewing, Google Maps integration, and multi-language support.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-^3.7.2-blue?logo=dart" />
  <img src="https://img.shields.io/badge/MongoDB-Backend-green?logo=mongodb" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?logo=android" />
  <img src="https://img.shields.io/badge/Version-1.0.0-orange" />
</p>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Backend Setup](#backend-setup)
- [GLB 3D Model Files — Setup Guide](#glb-3d-model-files--setup-guide)
- [OBD2 Bluetooth Setup](#obd2-bluetooth-setup)
- [Environment Configuration](#environment-configuration)
- [Running the App](#running-the-app)
- [User Roles](#user-roles)
- [Supported Vehicle Models](#supported-vehicle-models)
- [Screenshots](#screenshots)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## 📖 Overview

**DR.Cars** is a mobile-first vehicle management platform that addresses the common problem of fragmented service records and inaccessible vehicle diagnostics. The app supports three user roles — **Vehicle Owner**, **Service Center**, and **App Admin** — each with a dedicated dashboard tailored to their needs.

---

## ✨ Features

### 🔑 Core Features
| Feature | Description |
|---|---|
| 🧊 **3D Vehicle Model Viewer** | Interactive WebGL-powered 3D car viewer with color customization, studio lighting, and support for 8 brands |
| 🔌 **OBD2 Bluetooth Diagnostics** | Real-time RPM, speed, coolant temperature, and fuel consumption via Bluetooth |
| 🗺️ **Google Maps Integration** | Nearby service center discovery with routing and reviews |
| 📅 **Appointments & Notifications** | Book and manage service appointments with push notifications |
| 📜 **Service History & Receipts** | Full digital service records for every vehicle |
| 🌐 **Multi-Language Support** | English, Sinhala (SI), and Tamil (TA) |
| 🌙 **Dark / Light Mode** | Full theme support across all screens |
| 🔐 **Google & Facebook Auth** | Social authentication for easy onboarding |
| 🔔 **OneSignal Push Notifications** | Real-time alerts for bookings and updates |

### 👑 Admin Features
- Approve / reject service center registrations
- Vehicle dashboard overview with warning system (28 indicators across 8 brands)
- Ratings management

### 🔧 Service Center Features
- Manage service menu and pricing
- Handle bookings and generate confirmation receipts
- Access owner and vehicle information

### 🚘 Vehicle Owner Features
- Full OBD2 diagnostics dashboard
- 3D vehicle viewer with paint color picker
- Nearby service center map
- Appointment booking
- Service history

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter / Dart (SDK ^3.7.2) |
| **Backend** | Node.js + Express |
| **Database** | MongoDB |
| **3D Rendering** | Three.js via WebView (WebGL), MeshoptDecoder CDN, `.glb` format |
| **Maps** | Google Maps Flutter, Geolocator |
| **OBD2** | Bluetooth Serial (flutter_bluetooth_serial) |
| **Auth** | Google Sign-In, Facebook Auth |
| **Notifications** | OneSignal |
| **State / Theme** | ValueNotifier, SharedPreferences |

---

## 📁 Project Structure

```
dr_cars_fyp/
├── android/                    # Android native files
├── ios/                        # iOS native files
├── assets/
│   ├── html/
│   │   └── car_viewer.html     # Three.js WebGL 3D viewer page
│   └── images/                 # App logos and images
├── backend/
│   ├── public/
│   │   └── models/             # ⚠️ GLB 3D model files go HERE
│   │       ├── BMW/
│   │       ├── Toyota/
│   │       ├── Nissan/
│   │       ├── Honda/
│   │       ├── Suzuki/
│   │       ├── Mazda/
│   │       ├── Kia/
│   │       └── Hyundai/
│   └── server.js               # Node.js backend entry point
├── lib/
│   ├── admin/                  # Admin role screens
│   ├── service_center/         # Service center role screens
│   ├── vehicle_owner/          # Vehicle owner role screens
│   ├── l10n/
│   │   └── app_strings.dart    # EN / SI / TA translations
│   ├── providers/
│   │   └── locale_provider.dart
│   └── theme/
│       └── app_theme.dart      # Centralized theme configuration
├── pubspec.yaml
└── README.md
```

---

## ✅ Prerequisites

Make sure the following are installed before you begin:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Dart SDK](https://dart.dev/get-dart) (^3.7.2)
- [Node.js](https://nodejs.org/) (v18 or later) — for the backend
- [MongoDB](https://www.mongodb.com/try/download/community) — local or Atlas
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) (for iOS)
- A physical Android or iOS device (recommended for OBD2 Bluetooth and Maps features)

---

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/MandinuBala/DR.Cars_fyp.git
cd DR.Cars_fyp
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Setup

```bash
flutter doctor
```

Resolve any issues flagged before proceeding.

---

## 🖥️ Backend Setup

The Node.js backend serves the MongoDB API and, critically, **hosts the 3D GLB model files**.

### 1. Navigate to the backend folder

```bash
cd backend
```

### 2. Install Node.js dependencies

```bash
npm install
```

### 3. Configure MongoDB Connection

Open `backend/server.js` (or your `.env` file) and set your MongoDB connection string:

```env
MONGO_URI=mongodb://localhost:27017/drcars
PORT=5000
```

### 4. Start the Backend Server

```bash
node server.js
```

The server will start at:

```
http://localhost:5000
```

> ⚠️ **Important:** The Flutter app is configured to connect to the backend at `http://192.168.1.21:5000`. If your machine has a different local IP address, update this in the app's API configuration files before running.

To find your local IP:
- **Windows:** `ipconfig`
- **macOS/Linux:** `ifconfig` or `ip addr`

---

## 🧊 GLB 3D Model Files — Setup Guide

> This is the most critical setup step. The 3D Vehicle Model Viewer **will not work** without the `.glb` files placed in the correct directory.

### What are GLB files?

`.glb` files are binary 3D model files (GL Transmission Format). DR.Cars uses them to render interactive 3D car models in the app via a Three.js WebGL viewer embedded in a WebView.

---

### 📂 Where to Place GLB Files

All `.glb` model files must be placed inside:

```
backend/public/models/{Brand}/{Model}.glb
```

The folder structure **must exactly match** the following:

```
backend/
└── public/
    └── models/
        ├── BMW/
        │   └── Z4.glb
        ├── Toyota/
        │   ├── Camry.glb
        │   ├── Crown.glb
        │   └── Fortuner.glb
        ├── Nissan/
        │   ├── X-Trail.glb
        │   ├── GT-R.glb
        │   └── 370Z.glb
        ├── Honda/
        │   └── Vezel.glb
        ├── Suzuki/
        │   └── Vitara.glb
        ├── Mazda/
        │   └── CX-5.glb
        ├── Kia/
        │   └── Picanto.glb
        └── Hyundai/
            └── Santa Fe.glb
```

> ⚠️ **Folder and file names are case-sensitive.** `BMW/Z4.glb` ≠ `bmw/z4.glb`. Match the names exactly as shown above.

---

### 🔗 How the App Fetches GLB Files

The Flutter app constructs the URL dynamically based on the vehicle's brand and model:

```
http://192.168.1.21:5000/models/{Brand}/{Model}.glb
```

**Example URLs:**

| Vehicle | URL |
|---|---|
| BMW Z4 | `http://192.168.1.21:5000/models/BMW/Z4.glb` |
| Toyota Camry | `http://192.168.1.21:5000/models/Toyota/Camry.glb` |
| Nissan GT-R | `http://192.168.1.21:5000/models/Nissan/GT-R.glb` |
| Honda Vezel | `http://192.168.1.21:5000/models/Honda/Vezel.glb` |

The 3D viewer HTML (`assets/html/car_viewer.html`) loads these URLs via Three.js `GLTFLoader`.

---

### 🌐 Accessing GLB Files from a Physical Device

Since the backend runs on your **local machine**, your phone and computer must be on the **same Wi-Fi network**.

1. Find your computer's local IP address (e.g., `192.168.1.21`)
2. Update the base URL in the app's config to match your IP
3. Ensure the backend server is running (`node server.js`)
4. Confirm the GLB file is accessible by visiting the URL in your phone's browser:
   ```
   http://YOUR_IP:5000/models/BMW/Z4.glb
   ```
   Your browser should begin downloading the file — this confirms the server is serving it correctly.

---

### ⚙️ How the 3D Viewer Works

The viewer (`assets/html/car_viewer.html`) uses:

- **Three.js** for WebGL 3D rendering
- **GLTFLoader** to load `.glb` models from the backend
- **MeshoptDecoder** (loaded via CDN) for compressed mesh support
- **Smart color filtering** — paint changes skip glass, tires, and chrome automatically
- **3-point studio lighting** for a professional look
- **OrbitControls** for touch-based rotate, zoom, and pan

---

### 🛠️ Getting GLB Models

You can source `.glb` car models from:

- [Sketchfab](https://sketchfab.com/) — large library, many free models
- [TurboSquid](https://www.turbosquid.com/)
- [CGTrader](https://www.cgtrader.com/)
- [Free3D](https://free3d.com/)

After downloading, convert any `.gltf` or other formats to `.glb` using:

```bash
# Using gltf-pipeline (Node.js)
npm install -g gltf-pipeline
gltf-pipeline -i model.gltf -o Model.glb
```

Or use the free online tool: [https://sbtron.github.io/makeglb/](https://sbtron.github.io/makeglb/)

---

## 🔌 OBD2 Bluetooth Setup

1. Plug an **ELM327 Bluetooth OBD2 adapter** into your vehicle's OBD2 port (usually under the dashboard)
2. Pair the adapter with your Android/iOS device via Bluetooth settings
3. Open the app → Vehicle Owner Dashboard → OBD2 Diagnostics
4. Select the paired OBD2 device from the list
5. The app will begin reading: **RPM**, **Speed**, **Coolant Temperature**, and **Fuel Consumption**

> 📱 OBD2 Bluetooth is best tested on a **physical device**. It will not work on an emulator.

---

## ⚙️ Environment Configuration

### Google Maps API Key

1. Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**

**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS** — `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

### Google Sign-In

Place your `google-services.json` (Android) in:
```
android/app/google-services.json
```

Place your `GoogleService-Info.plist` (iOS) in:
```
ios/Runner/GoogleService-Info.plist
```

### Facebook Authentication

Update `android/app/src/main/AndroidManifest.xml` with your Facebook App ID and Client Token.

---

## ▶️ Running the App

### Ensure the backend is running first:

```bash
cd backend
node server.js
```

### Then run the Flutter app:

```bash
# Debug mode
flutter run

# Specific device
flutter run -d <device_id>

# List available devices
flutter devices

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

---

## 👥 User Roles

| Role | Description |
|---|---|
| 🚘 **Vehicle Owner** | Register vehicle, view 3D model, run OBD2 scan, book service, view history |
| 🔧 **Service Center** | Manage services, handle appointments, generate receipts |
| 👑 **App Admin** | Approve registrations, manage platform, view warnings dashboard |

---

## 🚗 Supported Vehicle Models

| Brand | Models |
|---|---|
| BMW | Z4 |
| Toyota | Camry, Crown, Fortuner |
| Nissan | X-Trail, GT-R, 370Z |
| Honda | Vezel |
| Suzuki | Vitara |
| Mazda | CX-5 |
| Kia | Picanto |
| Hyundai | Santa Fe |

---

## 🖼️ Screenshots

> *(Add screenshots of your app here)*

---

## 🐛 Troubleshooting

### 3D Model Not Loading
- ✅ Is the backend server running? (`node server.js`)
- ✅ Is your phone on the **same Wi-Fi** as your computer?
- ✅ Does the IP in the app match your machine's local IP?
- ✅ Is the `.glb` file in the correct folder with the correct name (case-sensitive)?
- ✅ Test the URL directly in your phone's browser: `http://YOUR_IP:5000/models/Brand/Model.glb`

### OBD2 Not Connecting
- ✅ Is Bluetooth enabled on your device?
- ✅ Is the OBD2 adapter paired in Bluetooth settings before opening the app?
- ✅ Is the adapter plugged into the vehicle's OBD2 port?
- ✅ Are you testing on a physical device (not an emulator)?

### Google Maps Not Showing
- ✅ Is the Maps API key correctly set in `AndroidManifest.xml` / `AppDelegate.swift`?
- ✅ Is location permission granted on the device?

### Language Not Switching
- ✅ Restart the app after changing language in Settings for the first time.

### MongoDB Connection Error
- ✅ Is MongoDB running locally? (`mongod`)
- ✅ Does the `MONGO_URI` in the backend match your MongoDB instance?

---

## 📄 License

This project is developed as a Final Year Project (FYP) for academic purposes.

---

<p align="center">Made with ❤️ using Flutter | DR.Cars FYP</p>
