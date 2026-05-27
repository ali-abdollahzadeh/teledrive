# TeleDrive

TeleDrive is a modern, high-performance Flutter application that transforms your Telegram account into a personal cloud storage drive. It leverages the official Telegram API (via native TDLib) to offer seamless file management using your "Saved Messages" and private channels as storage folders.

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android-blue)]()


[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="80">](https://play.google.com/store/apps/details?id=dev.aliabdollahzadeh.teledrive)
</div>
<div align="center">

![Cover Screen](docs/assets/cover.png/)
</div>


> [!CAUTION]
> TeleDrive uses your own Telegram account as the storage layer.
> Very heavy, automated, or abnormal upload activity may trigger Telegram limits or account restrictions.
> Use the app responsibly, respect Telegram’s Terms of Service, and do not upload illegal, copyrighted, harmful, or abusive content.


## ✨ Features

- **Native TDLib Integration**: Uses a native Kotlin implementation of TDLib (`tdlibx`) connected to Flutter via MethodChannels and EventChannels. This ensures blazing-fast, reliable, and background-capable Telegram interactions.
- **Secure Authentication**: Supports full Telegram authentication flows including Phone Number, Verification Code, and 2FA (Two-Factor Authentication) passwords. Session keys are safely stored using secure device storage.
- **Persistent Sessions**: Once logged in, your session is securely persisted. You don't have to log in every time you open the app.
- **Folder Management**: 
  - Uses your **Saved Messages** as the default storage location.
  - Automatically discovers **Channels and Supergroups** where you have Administrator upload rights, treating them as separate "Folders".
  - **Create Folders**: Creating a new folder seamlessly creates a private Telegram channel behind the scenes, dedicated solely to storing your files.
- **File Operations**:
  - **Upload Files**: Easily upload documents and media to specific folders.
  - **Download Files**: Download files back to your device with real-time progress tracking.
  - **Categorization**: Automatically categorizes files into Documents, Images, Videos, Audio, PDFs, and Archives.
- **Modern UI**: Built with a sleek, responsive Flutter UI utilizing Riverpod for robust state management and GoRouter for deep-linkable navigation.

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: GoRouter
- **Local Storage**: Flutter Secure Storage
- **Native Backend (Android)**: Kotlin, TDLib (via `tdlibx`)
- **Platform Bridging**: Flutter MethodChannel (for commands) & EventChannel (for reactive data streams like download progress and auth state)

## 🏗️ Architecture Architecture

The application is structured using a clean architecture approach, separated into distinct features (`auth`, `drive`, `preview`, `search`, `settings`).

The most critical architectural component is the **TDLib Bridge**:
1. **Dart Layer (`NativeTelegramChannel`)**: Exposes future-based methods (`uploadFile`, `downloadFile`, `getMyChats`) and streams (`authStateStream`, `fileUpdateStream`) to the Flutter app.
2. **Method/Event Channels**: Transmits data securely across the platform boundary.
3. **Kotlin Plugin (`TelegramPlugin`)**: Receives Flutter requests and routes them.
4. **Kotlin Manager (`TelegramManager`)**: A Singleton manager that initializes TDLib, manages the active client, handles file locking to prevent crashes, executes API calls, and processes real-time events from Telegram servers.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Android SDK (The current native TDLib implementation is Android-specific)
- A Telegram API ID and API Hash (Obtain these from [my.telegram.org](https://my.telegram.org/))

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ali-abdollahzadeh/telegram-drive.git
   cd telegram-drive
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   Ensure you have an Android emulator running or an Android device connected.
   ```bash
   flutter run
   ```

### Usage

1. Upon first launch, enter your **Telegram API ID**, **API Hash**, and **Phone Number**.
2. Enter the verification code sent to your Telegram app.
3. If you have 2FA enabled, enter your password.
4. Welcome to your Drive! You can now browse your Saved Messages, view your admin channels (folders), create new folders (private channels), and upload/download files.

## ⚠️ Current Limitations

- **Platform Support**: Currently, the native TDLib integration is implemented exclusively for Android using Kotlin. iOS support would require a Swift/Objective-C equivalent implementation of the `TelegramManager`.
- **Background Sync**: File uploads and downloads currently rely on the app being in the foreground, though TDLib itself is capable of background execution with proper OS service configurations.

## 📄 License

This project is licensed under the MIT License.
