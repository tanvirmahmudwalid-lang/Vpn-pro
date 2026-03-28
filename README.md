# Btaf Meet (Flutter)

This project is a professional social networking and career platform built with Flutter.

## Project Structure

- `lib/main.dart`: The core application logic (Firebase, AdMob, UI).
- `pubspec.yaml`: Project dependencies.
- `android/`: Android-specific configuration (Permissions, AdMob App ID).

## How to Build

### Local Build

1.  Install Flutter SDK: [flutter.dev](https://docs.flutter.dev/get-started/install)
2.  Run `flutter pub get` to install dependencies.
3.  Connect an Android device or emulator.
4.  Run `flutter run`.

### APK Generation

To generate a release APK locally:
1.  Run `flutter build apk --release`.
2.  The APK will be located in `build/app/outputs/flutter-apk/app-release.apk`.

## Important Notes

- **Firebase**: You must add your `google-services.json` to `android/app/` for Firebase to work on Android.
- **Signing**: For the Release AAB to be accepted by the Play Store, you must set up `key.properties` and signing configurations in `android/app/build.gradle`.
