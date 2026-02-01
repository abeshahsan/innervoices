<div align="center">

# Inner Voices

**A secure, private, and personal digital journal built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Google Drive](https://img.shields.io/badge/Google_Drive-4285F4?style=for-the-badge&logo=googledrive&logoColor=white)](https://developers.google.com/drive)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

---

## About

Inner Voices is a secure, private, and personal digital journal built with Flutter. It provides a safe space for your thoughts, with robust security features including local app lock and end-to-end encrypted cloud backups.

## Key Features

*   **Secure Journaling**: Keep your notes safe with local PIN and biometric (fingerprint/face) app lock.
*   **Rich Text Editor**: Format your notes with a clean and intuitive rich text editor powered by `flutter_quill`.
*   **Encrypted Cloud Backup**: Backup your journal to your personal Google Drive. All data is encrypted on your device before being uploaded, ensuring only you can access it.
*   **Google Sign-In**: Simple and secure authentication using your Google account.
*   **Offline-First**: Write and access your notes anytime, anywhere. All data is stored locally on your device using Realm DB.
*   **Smart Sync Status**: Easily see if your local journal is in sync with your cloud backup, ahead of it, or if a newer version is available to restore.
*   **Dynamic Theming**: Switch between light, dark, and system default themes for a comfortable writing experience.

## Technology Stack

<div align="center">

| Category | Technologies |
|----------|-------------|
| **Framework** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white) |
| **State Management** | ![BLoC](https://img.shields.io/badge/BLoC-blueviolet?style=flat-square) `flutter_bloc` |
| **Local Database** | ![Realm](https://img.shields.io/badge/Realm-39477F?style=flat-square&logo=realm&logoColor=white) |
| **Authentication** | ![Google](https://img.shields.io/badge/Google_Sign_In-4285F4?style=flat-square&logo=google&logoColor=white) |
| **Cloud Storage** | ![Google Drive](https://img.shields.io/badge/Google_Drive-4285F4?style=flat-square&logo=googledrive&logoColor=white) |
| **Encryption** | AES/GCM (`pointycastle`) |
| **Security** | `flutter_app_lock`, `flutter_screen_lock`, `local_auth` |
| **Text Editor** | `flutter_quill` |

</div>

## Architecture

The application follows a clean architecture pattern, separating concerns into distinct layers for better maintainability and scalability.

*   **`lib/ui` (Presentation Layer)**: Contains all the widgets and screens that make up the user interface. It is responsible for displaying data and capturing user input.
*   **`lib/bloc` (Business Logic Layer)**: Manages the application's state using the BLoC pattern. Each feature (User, Notes, Backup, AppLock) has its own BLoC to handle events and emit states.
*   **`lib/data` (Data Layer)**: Handles all data operations.
    *   **Repositories**: Abstract the data sources.
    *   **Services**: Interact with external APIs (Google Auth, Google Drive) and the local database (Realm).
    *   **Models**: Define the data structures for the application.

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

*   Flutter SDK installed.
*   An editor like VS Code or Android Studio.
*   A configured Firebase project for Google Sign-In (for Android and iOS).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/abeshahsan/innervoices.git
    cd innervoices
    ```

2.  **Set up Google Sign-In:**
    *   Follow the official `google_sign_in` package instructions to configure your Android, iOS, or web app. This includes adding your `google-services.json` for Android and configuring the iOS project.

3.  **Create the environment file:**
    *   In the root of the project, create a file named `.env`.
    *   This file is used to store the encryption key for backups.

4.  **Generate and add the encryption key:**
    *   The backup data is encrypted using an AES key. You need to generate a 32-byte (256-bit) key, encode it in Base64, and add it to your `.env` file.
    *   You can use the following Dart script to generate a secure key:
        ```dart
        import 'dart:convert';
        import 'dart:math';

        void main() {
          final random = Random.secure();
          final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
          final base64Key = base64UrlEncode(keyBytes);
          print('Your Base64 Key: $base64Key');
        }
        ```
    *   Add the generated key to your `.env` file:
        ```
        BACKUP_ENCRYPTION_KEY=YOUR_GENERATED_BASE64_KEY
        ```

5.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

6.  **Run the application:**
    ```sh
    flutter run
    ```

## Project Structure

```
lib/
├── assets/         # Static assets like images and fonts
├── bloc/           # BLoC state management files for each feature
│   ├── applock/
│   ├── backup/
│   ├── note/
│   ├── theme/
│   └── user/
├── data/           # Data layer: models, repositories, and services
│   ├── models/
│   ├── repositories/
│   └── services/
├── models/         # UI-facing data models
├── theme/          # App theme and color definitions
├── ui/             # Presentation layer: screens and widgets
│   ├── screens/
│   └── widgets/
└── main.dart       # Main application entry point
```

---

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please follow these steps:

1. **Fork the Project**
2. **Create your Feature Branch** 
   ```sh
   git checkout -b feature/AmazingFeature
   ```
3. **Commit your Changes** 
   ```sh
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push to the Branch** 
   ```sh
   git push origin feature/AmazingFeature
   ```
5. **Open a Pull Request**

### Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.

---

## Security

Inner Voices takes security seriously:

- **Local Encryption**: All data is encrypted locally before cloud backup
- **No Server**: Your data goes directly from your device to your personal Google Drive
- **Your Keys**: Only you have access to your encryption keys
- **Open Source**: Full transparency - audit the code yourself

> **Note**: Never share your `.env` file or encryption keys with anyone.

---

## License

Distributed under the MIT License.

```
MIT License

Copyright (c) 2026 Inner Voices

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Author

**Abesh Ahsan**

- GitHub: [@abeshahsan](https://github.com/abeshahsan)

---

## Show your support

Give a star if this project helped you!

---

<div align="center">

**Made with Flutter**

</div>