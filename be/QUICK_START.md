# Music Harmony Demo – Quick Start Guide

## Project overview

This end-to-end demo consists of:
- **Python FastAPI backend** – exposes APIs for MIDI harmony generation and performance evaluation
- **Flutter frontend** – offers the user interface and recording workflow

## Quick start

### Step 1: Launch the backend service

```bash
# 1. Move to the backend directory
cd Harmony10_demo/be

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Start the FastAPI server
python run.py
```

✅ The backend runs at `http://127.0.0.1:8000`
✅ Visit `http://127.0.0.1:8000/docs` for the interactive API documentation

### Step 2: Configure frontend networking

1. **Find your LAN IP**

   **Windows:**
   ```cmd
   ipconfig
   ```
   
   **macOS/Linux:**
   ```bash
   ifconfig
   ```
   
   Note the LAN IP address (for example: 192.168.1.100).

2. **Update the frontend configuration**

   Edit `fe/lib/api_service.dart`:
   ```dart
   // On line 6, replace with your actual IP address
   static const String baseUrl = 'http://192.168.1.100:8000';
   ```

### Step 3: Run the Flutter app

```bash
# 1. Switch to the Flutter directory
cd ../fe

# 2. Install Flutter dependencies
flutter pub get

# 3. Run the app (connect a device or launch an emulator)
flutter run
```

## Usage guide

### UI flow

1. **Choose a mode**: tap the top buttons “Harmonize” or “Evaluate”.
2. **Start recording**: hit the red “Start Recording” button.
3. **Capture notes**: during the 10-second countdown, press the white keys (C, D, E, F, G, A, B).
4. **Review results**: once recording finishes, processing happens automatically and results appear.

### Mode overview

**🎵 Harmonize mode**
- Records your melody.
- Generates a harmonized MIDI file.
- Saves the file to the app’s documents directory.

**📊 Evaluate mode**
- Records your performance.
- Compares the notes against the C-major scale template.
- Presents the score, detailed mistakes, and improvement suggestions.

## Validation

### Backend API checks

**Harmonize example:**
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{"version":"1.0","mode":"harmonize","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","return_mode":"bytes","events":[{"t_sec":0,"note":60},{"t_sec":3,"note":64},{"t_sec":7,"note":67}]}' \
     --output test_harmony.mid
```

**Evaluate example:**
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{"version":"1.0","mode":"evaluate","duration_sec":10,"quantize":"1s","octave_base":"C4","key":"C major","reference_id":"exercise_c_major_01","events":[{"t_sec":0,"note":60},{"t_sec":1,"note":62},{"t_sec":2,"note":64}]}'
```

### Frontend connectivity check

Within the Flutter app:
1. Make sure the backend service is running.
2. Record a short melody.
3. Confirm that the result panel updates successfully.

## Troubleshooting

### Common pitfalls

❌ **“Network error” message**
- Ensure the backend is running.
- Verify that the IP address is set correctly.
- Confirm the mobile device and computer share the same Wi-Fi network.

❌ **“No route to host” message**
- Inspect firewall settings.
- Make sure port 8000 is not blocked.

❌ **Flutter build failure**
- Run `flutter doctor` to diagnose the environment.
- Ensure the Flutter SDK version is ≥ 2.19.0.

### Debugging tips

1. **Inspect backend logs**
   - The backend terminal prints every API request.

2. **View Flutter logs**
   ```bash
   flutter logs
   ```

3. **Test network connectivity**
   - From the phone browser, open `http://<your-ip>:8000`.
   - You should see the API welcome page.

## Project structure

```
Harmony10_demo/
├── 🐍 Python backend
│   ├── main.py              # FastAPI application
│   ├── models.py            # Data models
│   ├── midi_utils.py        # MIDI utilities
│   ├── run.py               # Launch script
│   └── requirements.txt     # Dependency list
│
├── 📱 Flutter frontend
│   ├── lib/
│   │   ├── main.dart          # Main UI
│   │   ├── models.dart        # Data models
│   │   └── api_service.dart   # API client
│   ├── pubspec.yaml           # Dependency configuration
│   └── README.md              # Frontend guide
│
├── README.md                # Project overview
├── TEST_GUIDE.md            # API tests
└── QUICK_START.md           # Quick start guide
```

## Technical parameters

- **Recording length**: fixed 10 seconds
- **Note range**: C4–B4 white keys (60, 62, 64, 65, 67, 69, 71)
- **Quantization**: 1 second
- **Harmony voicing**: Each recorded melody note produces a major triad (root, major third, perfect fifth) that sustains until the next melody event.
- **MIDI format**: Type-1, dual-track

## Signs of success

✅ Backend running – terminal shows “Uvicorn running on…"
✅ Frontend connected – app screen renders correctly
✅ Recording functional – countdown and key presses behave as expected
✅ Results visible – Harmonize reports file generation, Evaluate shows scores

You now have the music harmony demo ready to play! 🎵