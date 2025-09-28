# Music Harmony Demo – Full Project Overview

A complete **Flutter + Python FastAPI** music demo that generates harmonized melodies and evaluates performances.

## Project structure

```
Harmony10_demo/
├── be/                     # Python FastAPI backend
│   ├── main.py              # FastAPI application
│   ├── models.py            # Pydantic data schemas
│   ├── midi_utils.py        # MIDI generation and evaluation logic
│   ├── run.py               # Service launcher
│   ├── requirements.txt     # Python dependencies
│   └── TEST_GUIDE.md        # API test guide
│
└── fe/                     # Flutter frontend
   ├── lib/
   │   ├── main.dart        # Flutter app entry point
   │   ├── models.dart      # Data models
   │   └── api_service.dart # HTTP client
   ├── pubspec.yaml         # Flutter dependencies
   └── README.md            # Frontend usage notes
```

## Feature highlights

### 🎵 Dual modes
- **Harmonize mode**: record a melody → generate a harmonized MIDI file.
- **Evaluate mode**: record a performance → compare against a reference template and score it.

### 🎹 User interface
- Mode toggle across the top (Harmonize/Evaluate).
- Seven white-key buttons (C–D–E–F–G–A–B, default range C4–B4).
- 10-second recording countdown with one event per second.
- Within the same second, the last tap wins.

### 🔄 Backend behavior
- **Harmonize**: POST `/api/v1/harmonize` → returns the MIDI file (bytes).
- **Evaluate**: POST `/api/v1/evaluate` → returns `{score, subscores, mistakes, advice}`.

### 🌐 LAN deployment
- FastAPI backend: `http://<LAN-IP>:8000`.
- Flutter frontend: mobile device or desktop build.

## Quick start

### 1. Run the backend service

```bash
# Move into the backend directory
cd Harmony10_demo/be

# Install Python dependencies
pip install -r requirements.txt

# Start the FastAPI server
python run.py
```

The service listens at `http://127.0.0.1:8000`.

### 2. Configure and run the frontend

```bash
# Enter the Flutter project
cd ../fe

# Install Flutter dependencies
flutter pub get

# Update the IP address in `lib/api_service.dart`
# ApiService.baseUrl = 'http://<your-lan-ip>:8000';

# Launch the Flutter app
flutter run
```

## Technical specification

### Musical parameters
- **Quantization**: fixed at 1 s (t_sec ∈ [0..9]).
- **Key**: fixed to C major.
- **White-key set**: {60, 62, 64, 65, 67, 69, 71} (C, D, E, F, G, A, B).
- **Conflict handling**: keep only the last tap within the same second.
- **Default velocity**: vel = 96.

### MIDI output
- **Format**: Type-1 MIDI file.
- **Track 1**: Melody (Channel 1, Program 0 – Piano).
- **Track 2**: Harmony (Channel 2, Program 48 – String Ensemble).
- **Harmony voicing**: Each recorded melody note produces a root-position major triad (root, major third, perfect fifth) that plays until the next melody event.

### API error codes
- `unsupported_version` – unsupported version string.
- `invalid_mode` – invalid mode value.
- `invalid_duration` – duration outside the allowed range.
- `invalid_quantize` – unsupported quantization value.
- `empty_sequence` – events array is empty.
- `duplicate_timeslot` – duplicate timestamp detected.
- `invalid_note` – note outside the allowed set.
- `reference_not_found` – reference template missing.

## Usage flow

### Harmonize mode
1. Switch to **Harmonize**.
2. Tap “Start Recording”; a 10-second countdown begins.
3. During the countdown, tap the white keys to record the melody.
4. After recording, the backend generates a MIDI file automatically.
5. The UI confirms the file was saved.

### Evaluate mode
1. Switch to **Evaluate**.
2. Tap “Start Recording” to start the countdown.
3. Perform according to the reference template (`exercise_c_major_01`).
4. The backend evaluates the performance automatically.
5. The UI displays scores and suggestions.

## Built-in reference template

### exercise_c_major_01 (C-major practice)
```
0s -> C(60)    1s -> D(62)    2s -> E(64)    3s -> F(65)    4s -> G(67)
5s -> A(69)    6s -> B(71)    7s -> C(60)    8s -> D(62)    9s -> E(64)
```

## Sample tests

### Harmonize endpoint
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0","mode":"harmonize","duration_sec":10,"quantize":"1s",
       "octave_base":"C4","key":"C major","return_mode":"bytes",
       "events":[{"t_sec":0,"note":60},{"t_sec":3,"note":64},{"t_sec":7,"note":67}]
     }' \
     --output harmony.mid
```

### Evaluate endpoint
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0","mode":"evaluate","duration_sec":10,"quantize":"1s",
       "octave_base":"C4","key":"C major","reference_id":"exercise_c_major_01",
       "events":[{"t_sec":0,"note":60},{"t_sec":1,"note":62},{"t_sec":2,"note":64}]
     }'
```

   ## Deployment notes

   ### Deploying on a local network

   1. **Backend**
      - Run `python run.py` on the host machine or server.
      - Open port 8000 in the firewall.
      - Record the host’s LAN IP address.

   2. **Frontend**
      - Update `flutter_app/lib/api_service.dart` with the backend IP.
      - Ensure the Flutter device and backend host share the same LAN.

   ### Production recommendations

   - **HTTPS**: provision SSL certificates.
   - **Reverse proxy**: place Nginx or Apache in front.
   - **Domain name**: configure DNS records.
   - **Monitoring**: enable logging and error tracking.

   ## Troubleshooting

   ### Common issues

   1. **Network connection failure**
      - Confirm the backend is running.
      - Double-check the configured IP address.
      - Validate firewall rules.

   2. **MIDI file not generated**
      - Ensure valid notes were recorded.
      - Check file-system permissions.

   3. **Evaluation anomalies**
      - Make sure the reference template exists.
      - Verify notes are inside the allowed range.

   ### Diagnostic tools

   - **Backend logs**: console output from `python run.py`.
   - **API explorer**: `http://<IP>:8000/docs`.
   - **Flutter logs**: `flutter logs`.
   - **Network test**: open the backend health endpoint in a browser.

   ## Technology stack

   ### Backend
   - **FastAPI** – modern Python web framework.
   - **Pydantic** – validation and serialization.
   - **Mido** – MIDI file handling.
   - **Uvicorn** – ASGI server.

   ### Frontend
   - **Flutter** – cross-platform UI toolkit.
   - **Dart** – programming language.
   - **http** – networking package.
   - **path_provider** – file path management.

   ## Contributing

   Contributions, feature requests, and bug reports are welcome.

   ### Development environment
   - Python 3.8+
   - Flutter 3.0+
   - VS Code or Android Studio recommended

   ### Submission guidelines
   - Follow the project’s style conventions.
   - Add relevant tests where applicable.
   - Update supporting documentation.

   ## License

   MIT License – see the `LICENSE` file for details.