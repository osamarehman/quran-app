# Development Guide

## Prerequisites

- Node.js 18+
- npm
- Expo CLI: `npm install -g expo-cli`
- EAS CLI (for builds): `npm install -g eas-cli`
- Android Studio (for Android local builds) or Xcode (for iOS local builds)

---

## Install Dependencies

```bash
npm install
```

---

## Dev Server

### Start with Expo Go (fastest — no native build required)

```bash
npm start
# or
npx expo start
```

Scan the QR code with the Expo Go app on your device.

> **Note:** This app uses `expo-sqlite` and custom native modules. Some features may not work in Expo Go. Use a dev client build for full functionality.

### Start with a Dev Client build

First install the dev client on your device (see [Build: Development](#development) below), then:

```bash
npx expo start --dev-client
```

### Platform-specific (local device/emulator)

```bash
npm run android   # launches Android emulator or connected device
npm run ios       # launches iOS simulator (Mac only)
npm run web       # starts web version
```

---

## Builds (EAS)

All cloud builds use [EAS Build](https://docs.expo.dev/build/introduction/). Log in first:

```bash
eas login
```

### Development

Installs a dev client on your device. Required for testing native modules (SQLite, fonts, audio) outside Expo Go.

```bash
eas build --profile development --platform android
eas build --profile development --platform ios
```

### Preview (Internal Distribution)

APK/IPA distributed internally. Useful for QA without going through a store.

```bash
eas build --profile preview --platform android
eas build --profile preview --platform ios
```

### Production

Builds the release binary. App version auto-increments on each run.

```bash
eas build --profile production --platform android
eas build --profile production --platform ios
```

Build both platforms at once:

```bash
eas build --profile production --platform all
```

---

## Local Builds (without EAS cloud)

### Android

```bash
npx expo run:android
```

Requires Android Studio and a connected device or running emulator.

### iOS (Mac only)

```bash
npx expo run:ios
```

Requires Xcode and a simulator or provisioned device.

---

## Type Check

```bash
npx tsc --noEmit
```

---

## Project ID

EAS project ID: `92e644ca-75c1-4745-a365-be8e2ed2ad9f`  
Owner: `usamar`  
Android package: `com.usamar.quranmushafapp`
