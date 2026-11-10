# 🎵 Music Player for iOS

A feature-rich, Spotify-style dark theme iOS music player app built natively with **SwiftUI** and **MVVM architecture**. Supports multiple streaming services (Deezer, Jamendo, Last.fm, YouTube, SoundCloud), local file playback, background audio & lock screen controls, song lyrics, 10-band equalizer, playlist management, and an offline download manager.

---

## ✨ Features

- **Spotify-Style Vibrant Dark Theme**: Beautiful neon accents, glassmorphic cards, gradient art backgrounds, and smooth interactive animations.
- **Multiple Music Sources**:
  - **Deezer**: Charts, top artists, track search, and 30-second previews *(Works out-of-the-box, no key required)*.
  - **Jamendo**: Full-length Creative Commons music, trending tracks, featured albums *(Pre-configured with default client ID)*.
  - **Last.fm**: Search, global charts, top artists, and album artwork integration.
  - **YouTube / YouTube Music**: Search query catalog, video metadata, trending tracks.
  - **SoundCloud**: Search catalog and stream endpoint integration.
  - **Local Files**: Apple Music device library (`MediaPlayer`) and imported audio files via iOS Files / iTunes (`Documents/ImportedMusic`).
- **Interactive Player Experience**:
  - **Persistent Mini Player**: Sits neatly above the tab bar with real-time progress bar, responsive play/pause, and quick track skip.
  - **Full Screen Player**: Drag-down to dismiss gesture, pulsing artwork animation, interactive scrubbing slider, volume control, repeat modes (off/all/one), and shuffle.
  - **Native AirPlay Integration**: Native `AVRoutePickerView` to stream audio to AirPods, HomePods, Apple TV, or Bluetooth speakers.
  - **Now Playing & Background Audio**: Full lock screen and Control Center media controls (`MPNowPlayingInfoCenter` & `MPRemoteCommandCenter`) with background audio playback capability (`UIBackgroundModes: audio`).
- **10-Band Graphic Equalizer**:
  - 10 adjustable frequency bands (32Hz, 64Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz) from -12 dB to +12 dB.
  - 10 presets: *Flat, Bass Boost, Treble Boost, Vocal, Rock, Pop, Jazz, Electronic, Classical, Hip Hop*, plus dynamic custom preset saving.
- **Synced Lyrics Display**:
  - In-player expandable lyrics viewer powered by `lyrics.ovh` with automated cleanup fallbacks.
- **Offline Download Manager**:
  - Download streamed audio directly to the app container.
  - Tracks download progress in real-time.
  - Automatically indexes downloads in Core Data for offline playback without network connectivity.
- **Playlist & Library Management**:
  - Core Data persistent storage with programmatically constructed managed object model.
  - "Liked Songs" / Favorites default playlist with instant heart toggle.
  - Custom user playlists (create, rename, delete, add/remove songs).
  - Recently played history tracking (up to 50 tracks).
- **Universal Multi-Source Search**:
  - Real-time search with 500ms Combine debounce.
  - Filter chips to toggle individual music sources on or off.
  - Recent search query history with tap-to-replay and clear options.
- **Customizable In-App Settings**:
  - In-app API Key configuration (Jamendo, Last.fm, YouTube, SoundCloud) persisted securely to `UserDefaults`.
  - Cache size inspection and one-tap cache cleanup.
  - Audio quality preference, Wi-Fi only download toggles, crossfade preferences.

---

## 🏗️ Architecture & Tech Stack

```
MusicPlayer/
├── App/
│   ├── MusicPlayerApp.swift       # Application entry point (@main, dependency injection)
│   ├── AppTheme.swift             # Design system (colors, gradients, view modifiers, hex color parser)
│   └── ContentView.swift          # Root TabView container with mini-player overlay
├── Models/
│   ├── Models.swift               # Song, Playlist, Album, Artist, EqualizerPreset data models
│   └── PersistenceController.swift # Core Data programmatic stack & managed object subclasses
├── Services/
│   ├── AudioPlayerService.swift   # AVPlayer engine, audio session, time observers, lock screen info
│   ├── NetworkService.swift       # Async/await URLSession HTTP client & file downloader
│   ├── DownloadManager.swift      # Offline file persistence & download progress tracking
│   ├── DeezerService.swift        # Deezer REST API client (Charts, Search, Artists)
│   ├── JamendoService.swift       # Jamendo v3.0 REST API client (Search, Trending, Albums)
│   ├── LastFMService.swift        # Last.fm Audioscrobbler 2.0 API client
│   ├── YouTubeService.swift       # YouTube Data v3 API client
│   ├── SoundCloudService.swift    # SoundCloud API client
│   ├── LocalMusicService.swift    # MPMediaQuery device library & Documents audio loader
│   └── LyricsService.swift        # Lyrics fetching API with title cleanup fallback
├── ViewModels/
│   ├── HomeViewModel.swift        # Home feed state (Trending, Charts, Artists, Albums)
│   ├── PlayerViewModel.swift      # Audio playback state, queue, lyrics, equalizer, remote controls
│   ├── LibraryViewModel.swift     # Playlists, downloads, favorites, local tracks
│   ├── SearchViewModel.swift      # Debounced multi-source search state
│   └── SettingsViewModel.swift    # User preferences, API key storage, storage cache
├── Views/
│   ├── HomeView.swift             # Home feed view with quick play & horizontal scroll carousels
│   ├── SearchView.swift           # Search input, filter chips, category cards, result rows
│   ├── LibraryView.swift          # Segmented library (Playlists, Downloads, Local, Favorites)
│   ├── SettingsView.swift         # Audio quality, API key inputs, cache cleaner
│   ├── MiniPlayerView.swift       # Bottom mini-player strip
│   ├── FullPlayerView.swift       # Full modal player with lyrics & AirPlay
│   ├── PlaylistDetailView.swift   # Dynamic playlist detail, shuffle, rename, song management
│   ├── EqualizerView.swift        # Interactive 10-band slider equalizer & preset chips
│   └── QueueView.swift            # Play queue list with drag-to-reorder (.onMove) & swipe-delete
├── Assets.xcassets/               # App icons & AccentColor asset catalogs
└── Info.plist                     # Permissions & background modes configuration
```

---

## 🚀 How to Open and Run the Project

### Requirements
- **macOS Sonoma** or newer (required to run Xcode).
- **Xcode 14.0+** (Xcode 15 or 16 recommended).
- **iOS 16.0+** deployment target.
- Target devices: iPhone and iPad (universal).

### Steps to Run
1. Transfer or clone this repository to your macOS development environment:
   ```bash
   git clone <repo-url>
   cd "app ios"
   ```
2. Open the project in Xcode:
   ```bash
   open MusicPlayer.xcodeproj
   ```
3. In Xcode, select an iOS Simulator from the device selector bar (e.g., **iPhone 15 Pro** or **iPhone 16**).
4. Build and run the project:
   - Press **`Cmd + R`** or click the **Play ▶** button in Xcode's toolbar.
5. The app will launch in the simulator, load the Home tab with trending songs from Deezer and Jamendo, and start playing on tap!

---

## 🔑 API Keys Configuration

The app works **immediately out-of-the-box**:
- **Deezer**: Requires **no API key**. Search, Charts, and 30-second previews work out-of-the-box.
- **Jamendo**: Pre-configured with a public developer client ID (`b6747d04`). Search and full track streaming work immediately.

### Custom API Keys (Optional)
To enable Last.fm, YouTube, and SoundCloud, or to use your own personal developer quota, you can configure keys directly inside the app:

1. Launch the app and go to the **Settings** tab (gear icon).
2. Scroll to the **API Configuration** section.
3. Enter your keys:
   - **Jamendo Client ID**: Register at [devportal.jamendo.com](https://devportal.jamendo.com/).
   - **Last.fm API Key**: Create an account at [last.fm/api/account/create](https://www.last.fm/api/account/create).
   - **YouTube API Key**: Create a project in [Google Cloud Console](https://console.cloud.google.com/) and enable the **YouTube Data API v3**.
   - **SoundCloud Client ID**: Register at [developers.soundcloud.com](https://developers.soundcloud.com/).
4. Keys are stored locally in `UserDefaults` and will be dynamically used across all API requests without requiring app recompilation.

---

## 📁 Importing Local Music Files

You can play your own local music files inside the app in two ways:

### 1. From Device Apple Music Library
- Ensure the app is granted permission when prompted (configured via `NSAppleMusicUsageDescription` in `Info.plist`).
- Any synced music from iTunes / Apple Music on the physical iOS device appears under **Library -> Local**.

### 2. File Sharing via iOS Files App or Finder / iTunes
The app is configured with `UIFileSharingEnabled = true` and `LSSupportsOpeningDocumentsInPlace = true`:
1. Connect your iPhone to your Mac or PC.
2. In Finder (macOS) or iTunes (Windows), go to the **Files** section of your device.
3. Locate **Music Player** and drag your audio files (`.mp3`, `.m4a`, `.wav`, `.aac`, `.flac`) into the **ImportedMusic** directory.
4. Alternatively, on an iPhone, open the native **Files** app, go to **On My iPhone -> Music Player -> ImportedMusic**, and copy your songs there.
5. In the app, switch to **Library -> Local** to see and play your imported tracks.

---

## 🧪 Running the Verification & Test Suite

To verify lexical balance, Info.plist configurations, project.pbxproj file mappings, cross-file ViewModel symbol resolution, and regression checks across all 29 Swift source files:
```bash
python3 test_suite.py
```

---

## ⚙️ Regenerating the Xcode Project (Optional)

If you ever modify files or need to recreate the `MusicPlayer.xcodeproj` project file:
```bash
python3 generate_xcodeproj.py
```
This script dynamically parses the directory structure, creates deterministic PBX object IDs, generates `MusicPlayer.xcodeproj/project.pbxproj`, and configures the default shared schemes and workspace settings.

---

## 📄 License
This project is open-source and intended for educational and personal entertainment purposes. Music streams and previews are served directly by their respective providers (Deezer, Jamendo, Last.fm, SoundCloud, YouTube).
