# 🔥 Arise Music Flutter — Complete Setup Guide

## Prerequisites
| Tool | Install |
|------|---------|
| Flutter SDK 3.16+ | https://flutter.dev/docs/get-started/install |
| Android Studio | https://developer.android.com/studio |
| Java 17 | Bundled with Android Studio |
| Git | https://git-scm.com |

---

## Step 1 — Clone and install dependencies

```bash
git clone https://github.com/skgupta507/arise.git
cd arise_flutter
flutter pub get
```

---

## Step 2 — Download fonts

Download TTF files from Google Fonts and place in `assets/fonts/`:

**Orbitron** → https://fonts.google.com/specimen/Orbitron
- Orbitron-Regular.ttf, Orbitron-Bold.ttf, Orbitron-Black.ttf

**Rajdhani** → https://fonts.google.com/specimen/Rajdhani
- Rajdhani-Regular.ttf, Rajdhani-SemiBold.ttf, Rajdhani-Bold.ttf

---

## Step 3 — Generate signing keystore (one time only)

```bash
keytool -genkeypair \
  -keystore arise-release.jks \
  -alias arise-key \
  -keyalg RSA -keysize 4096 \
  -sigalg SHA256withRSA \
  -validity 10000 \
  -storepass YOUR_STORE_PASS \
  -keypass YOUR_KEY_PASS \
  -dname "CN=Your Name, OU=Dev, O=Arise Music, L=City, ST=State, C=IN"
```

Create `android/keystore.properties`:
```properties
storeFile=../../arise-release.jks
storePassword=YOUR_STORE_PASS
keyAlias=arise-key
keyPassword=YOUR_KEY_PASS
```

---

## Step 4 — Build debug APK (for testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

## Step 5 — Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Step 6 — Set up GitHub Actions (auto-build on tag push)

Add these 4 secrets in your GitHub repo → Settings → Secrets:

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | `base64 -w 0 arise-release.jks` |
| `KEYSTORE_PASS`   | Your store password |
| `KEY_ALIAS`       | arise-key |
| `KEY_PASS`        | Your key password |

Then trigger a release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will build, sign, and publish `arise.apk` to a GitHub Release automatically.

---

## Step 7 — In-app auto-updates

The app checks `https://api.github.com/repos/skgupta507/arise/releases/latest` on launch.
When a new tag is pushed and the APK version is higher, users see an "Update Available" dialog.
They tap **Update Now** → APK downloads in background → tap notification to install.

To change the update repo, edit `lib/api/update_api.dart`:
```dart
static const _owner   = 'skgupta507';
static const _repo    = 'arise';
static const _apkName = 'arise.apk';
```

---

## Project structure

```
arise_flutter/
├── lib/
│   ├── main.dart                    ← App entry, providers, background audio init
│   ├── theme/app_theme.dart         ← Demon dark + Angel light theme
│   ├── api/
│   │   ├── saavn_api.dart           ← JioSaavn API client
│   │   ├── muzo_api.dart            ← YouTube Music / Muzo API client
│   │   └── update_api.dart          ← GitHub Releases update checker + downloader
│   ├── models/
│   │   ├── song_model.dart          ← Unified song model (Saavn + YouTube)
│   │   └── playlist_model.dart      ← Playlist model
│   ├── providers/
│   │   ├── player_provider.dart     ← Audio engine: playback, queue, history
│   │   ├── library_provider.dart    ← Liked songs, playlists, recently played (Hive)
│   │   ├── theme_provider.dart      ← Dark/light theme state
│   │   └── search_provider.dart     ← Search state + debounce
│   ├── router/app_router.dart       ← GoRouter all routes
│   ├── screens/
│   │   ├── home/                    ← Home, Hero, Mood section
│   │   ├── search/                  ← Search + tabs
│   │   ├── albums/                  ← Albums list + detail
│   │   ├── artists/                 ← Artists grid + detail
│   │   ├── playlists/               ← Playlist management
│   │   ├── podcasts/                ← 12-category podcast screen
│   │   ├── trending/                ← Trending India + 5 tabs
│   │   ├── library/                 ← Library hub
│   │   ├── liked/                   ← Liked songs
│   │   ├── recent/                  ← Recently played
│   │   ├── settings/                ← Settings + update checker
│   │   └── about/                   ← About + links
│   └── widgets/
│       ├── player/
│       │   ├── mini_player.dart     ← Mini player: thumb + marquee + prev/play/next/close
│       │   └── full_player.dart     ← Full-screen player + seek + queue tab
│       ├── cards/
│       │   └── song_card.dart       ← SongTile (list) + SongCard (horizontal)
│       └── common/
│           ├── main_shell.dart      ← Bottom nav + mini-player dock
│           └── section_header.dart  ← SectionHeader + HScrollSection + Shimmer
├── android/                         ← Android config, manifest, signing
├── assets/fonts/                    ← Orbitron + Rajdhani TTFs
├── .github/workflows/release.yml   ← Auto-build + sign + release CI
├── scripts/download_fonts.sh        ← Font download helper
└── SETUP.md                         ← This file
```

---

## Troubleshooting

**`Gradle build failed`**
→ Run `flutter doctor -v` and fix any issues.
→ Make sure Java 17 is active: `java -version`

**`Font not found`**
→ Download TTF files from Google Fonts and place in `assets/fonts/`

**`Audio doesn't play in background`**
→ Check that `just_audio_background` is correctly initialised in `main.dart`
→ Ensure `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions are in AndroidManifest.xml

**`No stream URL found` for a song**
→ The Muzo API may be rate-limited. The app falls back to JioSaavn stream URL automatically.

**`Update not detected`**
→ Ensure the GitHub release has an asset named exactly `arise.apk`
→ Ensure `versionName` in the built APK is lower than the release tag version
