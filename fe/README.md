# Flutter Music Harmony Demo

This Flutter application works with the FastAPI backend in the parent directory to generate harmonies for short melodies and evaluate recorded performances.

## Feature highlights

### 🎵 Dual operating modes
- **Harmonize mode**: Record a melody and receive a MIDI file that adds harmony lines. Each note is harmonized with a root-position major triad instead of pulling from a fixed chord list.
- **Evaluate mode**: Record a performance and compare it against the reference exercise to obtain a score.

### 🎹 Interactive interface
- Mode toggle at the top of the screen
- Seven white-key buttons (C–D–E–F–G–A–B)
- Ten-second countdown-based recording window
- Live recording status and timer feedback

### 📊 Result panels
- **Harmonize**: Confirms that the MIDI file was created, shows the saved filename, and reports how many notes were captured.
- **Evaluate**: Displays the overall score, subscores, detected mistakes, and tailored practice advice.

## Project structure

```
fe/
├── lib/
│   ├── main.dart          # UI and application state
│   ├── models.dart        # Data transfer objects
│   └── api_service.dart   # HTTP client wrappers
├── pubspec.yaml           # Flutter dependencies
└── README.md              # This guide
```

## Installation & run

### Prerequisites

1. **Flutter SDK** (>= 2.19.0)
2. **FastAPI backend** running locally or on the same LAN (see `../be`)

### Steps

1. **Point the client to your backend**

   Edit `lib/api_service.dart` and update the `baseUrl` constant so it matches your backend host:

   ```dart
   static const String baseUrl = 'http://192.168.1.100:8000';
   ```

2. **Install dependencies**

   ```powershell
   cd fe
   flutter pub get
   ```

3. **Run the app**

   ```powershell
   flutter run
   ```

## Usage guide

### Typical workflow

1. **Choose a mode**
   - Tap the “Harmonize” or “Evaluate” toggle button.

2. **Start recording**
   - Press the red “Start recording” button.
   - A 10-second countdown window begins.

3. **Play notes**
   - Tap the white-key buttons (C, D, E, F, G, A, B) during the countdown.
   - The recorder captures at most one note per second.
   - If multiple taps occur within the same second, the latest tap wins.

4. **Review the results**
   - Processing starts automatically when the countdown completes.
   - **Harmonize**: Generates a MIDI file inside the app documents directory.
   - **Evaluate**: Shows scoring details and suggestions for improvement.

### Screen layout

#### Top area
- **Mode toggle**: Switch between Harmonize and Evaluate.
- **Recording status**: Shows whether you are waiting, recording, or finished, plus the remaining seconds.

#### Middle area
- **Piano keys**: Seven white keys that correspond to C4–B4.
- **Visual feedback**: Active keys turn blue while pressed.

#### Bottom area
- **Recording controls**: Start/stop buttons.
- **Result panel**: Displays mode-specific output after recording.

### Harmonize mode output
- ✅ Success banner confirming the MIDI file was created.
- 📁 Filename of the saved MIDI.
- 📊 Count of captured notes.
- 🎼 **Harmony generation rule**: Each captured melody note produces a major triad (root, major third, perfect fifth) built on that pitch. The backend selects the proper pitches dynamically rather than reusing a fixed chord progression.

### Evaluate mode output
- 🎯 **Total score** (0–100) with color coding (green ≥ 80, orange ≥ 60, red < 60).
- 📊 **Subscores** for accuracy and timing.
- 💡 **Suggestions** tailored to the detected issues.
- ❌ **Mistake list** highlighting up to the first five wrong, missing, or extra notes plus a count of any remaining issues.

## Technical details

### Note mapping
```
C: 60 (C4)    D: 62 (D4)    E: 64 (E4)    F: 65 (F4)
G: 67 (G4)    A: 69 (A4)    B: 71 (B4)
```

### Recording rules
- **Duration**: Fixed 10-second window.
- **Quantization**: One-second resolution.
- **Conflict handling**: The latest note within a one-second bucket replaces earlier taps.
- **Scale restriction**: Only white keys from C major are available.

### Harmony generation logic
- **Triad model**: Harmonies use dynamically constructed major triads based on each recorded note.
- **Voicing**: The backend emits root-position chords (root, third, fifth) on separate MIDI tracks for melody and harmony.
- **Adaptability**: Because the triads are derived per note, the harmony responds to melodic movement instead of looping through a pre-set chord chart.

### API integration
- **Backend host**: Configurable through `ApiService.baseUrl`.
- **Timeouts**: 30-second request timeout with retry-safe error handling.
- **Error reporting**: User-friendly messages for network and backend failures.
- **Connectivity check**: Automatically verifies backend availability before sending payloads.

## Troubleshooting

### Common issues

1. **Network errors**
   - Confirm the FastAPI server is running (`python run.py`).
   - Verify the IP/port configuration in `api_service.dart`.
   - Ensure the device running Flutter shares the same LAN.

2. **MIDI file not generated**
   - Make sure at least one note was recorded.
   - Check that the app has permission to write to the documents directory.

3. **Evaluation fails**
   - Confirm the backend has the `exercise_c_major_01` template available.
   - Validate that recorded notes stay within the supported white-key range.

### Debugging tips

1. **Inspect network requests**

   ```powershell
   flutter logs
   ```

2. **Probe backend availability**
   - Visit `http://<your-ip>:8000` in a browser.
   - You should see the FastAPI welcome message.

3. **Validate JSON payloads**
   - Compare Flutter requests and backend responses.
   - Ensure they match the shapes defined in `models.dart`.

## Development notes

### Core components
- **MusicHarmonyPage**: Stateful widget that drives the UI and state machine.
- **ApiService**: Encapsulates HTTP calls to the backend.
- **Models**: Data classes describing requests and responses.

### State management
The app uses Flutter’s built-in `StatefulWidget` pattern:
- `currentMode`: Active mode (Harmonize or Evaluate).
- `isRecording`: Whether recording is in progress.
- `recordedEvents`: Collected melody events.
- `evaluationResult`: Scoring feedback returned by the backend.

### File handling
- Uses the `path_provider` package to resolve the app documents directory.
- Automatically names and saves generated MIDI files in that directory.

## Roadmap

- [ ] Add MIDI playback controls in the UI.
- [ ] Support additional keys and octaves.
- [ ] Provide a recording history view.
- [ ] Visualize notes with basic waveforms or piano roll.
- [ ] Enable export and sharing options.