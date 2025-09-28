# Harmony10 Demo

A full-stack music harmony playground that pairs a **Python FastAPI** backend with a **Flutter** client. Record short white-key melodies, auto-generate harmonized MIDI files built from dynamic major triads, or evaluate your performance against a reference template.

## Highlights

- **Two recording modes** – Harmonize (melody ➜ triad-based harmony) and Evaluate (performance ➜ scoring report).
- **Per-note triads** – Harmony voices are generated on the fly: each melody event spawns a root-position major triad that sustains until the next note.
- **Cross-platform UI** – Flutter app runs on desktop, mobile, or emulator with real-time countdown feedback.
- **MIDI-first workflow** – Backend ships Type-1 MIDI output and detailed evaluation JSON, front end saves harmony files locally.

## Architecture at a glance

```
Harmony10_demo/
├── be/               # FastAPI backend (Python)
│   ├── main.py       # API entry point
│   ├── midi_utils.py # MIDI generation & evaluation logic
│   └── ...
├── fe/               # Flutter frontend (Dart)
│   ├── lib/
│   │   ├── main.dart        # UI & state machine
│   │   ├── api_service.dart # HTTP client
│   │   └── models.dart      # Data contracts
└── midi_output/      # Sample/exported MIDI files kept for reference
```

## Prerequisites

| Component | Requirements |
|-----------|--------------|
| Backend   | Python 3.8+, `pip`, optional virtual environment (e.g., Conda or venv) |
| Frontend  | Flutter SDK ≥ 2.19.0, connected device or desktop target |
| Both      | Same LAN if the device and backend run on different machines |

👉 Need setup help? See the detailed guides in [`be/QUICK_START.md`](be/QUICK_START.md) and [`fe/README.md`](fe/README.md).

## Getting started

### 1. Start the FastAPI backend

```powershell
cd .\be
pip install -r requirements.txt
python .\run.py
```

- Default host: `http://127.0.0.1:8000`
- Interactive docs: `http://127.0.0.1:8000/docs`
- Backend saves generated MIDI files to `be/midi_output` (configurable inside `midi_utils.py`).

### 2. Point the Flutter app at your backend

Edit `fe/lib/api_service.dart` and change the base URL:

```dart
static const String baseUrl = 'http://<your-lan-ip>:8000';
```

Find the LAN IP on Windows with `ipconfig`, or use `ifconfig` / `ip addr` on macOS & Linux.

### 3. Run the Flutter client

```powershell
cd ..\fe
flutter pub get
flutter run
```

- Desktop (Windows/macOS/Linux), Android, and iOS are all supported by Flutter—pick your target during `flutter run`.
- In harmonize mode, the app stores MIDI files in a `midi` folder next to the Flutter executable (see runtime console logs for the exact path).

### 4. Smoke-test the API (optional)

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"harmonize",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "return_mode":"bytes",
       "events":[{"t_sec":0,"note":60},{"t_sec":3,"note":64},{"t_sec":7,"note":67}]
     }' \
     --output harmony.mid
```

### Usage in a nutshell

1. Pick **Harmonize** or **Evaluate** on the Flutter home screen.
2. Hit **Start recording**; the 10-second countdown begins on the first key press.
3. Tap the on-screen white keys (C–B). Only the latest tap within a second counts.
4. Let processing finish automatically:
   - **Harmonize** ➜ saved MIDI file + note count.
   - **Evaluate** ➜ score, subscores, mistakes, and tailored advice.

## API cheat sheet

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| POST | `/api/v1/harmonize` | Accepts melody events, returns harmonized MIDI bytes. | Binary MIDI file + metadata |
| POST | `/api/v1/evaluate` | Compares events with reference template `exercise_c_major_01`. | JSON `{score, subscores, mistakes, advice}` |

Both endpoints validate note range (C4–B4), quantization (1s), and reject duplicate timestamps.

## Where files land

- `be/midi_output/` – backend-generated harmonies and evaluation intermediates.
- `<flutter_executable_dir>/midi/` – Flutter desktop build saves harmonize outputs here (path logged at runtime).
- `midi_output/` (repo root) – archived demo outputs for documentation or QA.

## Documentation map

- Backend overview: [`be/README.md`](be/README.md)
- Backend quick start: [`be/QUICK_START.md`](be/QUICK_START.md)
- API test recipes: [`be/TEST_GUIDE.md`](be/TEST_GUIDE.md)
- Harmony design notes: [`be/HARMONY_MODIFICATION_SUMMARY.md`](be/HARMONY_MODIFICATION_SUMMARY.md)
- Frontend usage guide: [`fe/README.md`](fe/README.md)

## Troubleshooting tips

| Symptom | Fix |
|---------|-----|
| Flutter app shows “Network error” | Ensure the backend is running, confirm IP/port, and verify devices share the same network. |
| No MIDI file after harmonizing | Record at least one note; check filesystem permissions; inspect Flutter logs (`flutter logs`). |
| Evaluate mode returns `reference_not_found` | Confirm the request uses `exercise_c_major_01` and the backend has loaded reference templates. |
| Backend crashes on start | Reinstall dependencies, ensure Python ≥ 3.8, and verify `mido`/`uvicorn` installed. |

For deeper diagnostics, consult the detailed troubleshooting sections inside the backend and frontend READMEs linked above.

## Roadmap ideas

- Support additional scales and octave ranges.
- Add playback controls within the Flutter UI.
- Surface a recording history and sharing options.
- Extend evaluation to multiple reference exercises.

Contributions, ideas, and bug reports are welcome—feel free to open an issue or submit a pull request!
