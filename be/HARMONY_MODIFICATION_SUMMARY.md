# Harmony Generation Logic — Update Summary

## 🎯 Goals
Revise the harmony generation logic so that every melody note becomes the root of a triad, save the resulting MIDI file locally, and expose the chord names in the response.

## 📝 Key Changes

### 1. Harmony workflow updates in `midi_utils.py`

#### Improvements to the `MidiGenerator` class
- **Note name mapping**: Added a complete MIDI-note-to-name mapping that covers all semitone steps.
- **Triad creation**: Updated `_add_harmony_events` to generate triads dynamically from the melody notes.
- **File persistence**: Introduced `_save_midi_file`, which automatically stores the generated MIDI file on disk.
- **Chord metadata**: `_add_harmony_events` now returns detailed chord descriptors.

#### Implementation snippet
```python
# Old approach: fixed C-F-G progression
# New approach: triads generated from the current melody note
root_note = event.note
third = root_note + 4  # Major third
fifth = root_note + 7  # Perfect fifth
current_chord = [root_note, third, fifth]
```

### 2. API response enhancements in `main.py`

#### Response format improvements
- **URL mode**: Returns JSON including chord names and detailed chord metadata.
- **Bytes mode**: Sends chord information via response headers.
- **Logging**: Records the generated chord names for easier diagnostics.

### 3. Additional capabilities

#### 🎵 Harmony generation rules
- **Dynamic triads**: Every melody note produces a major triad.
- **Duration handling**: Each triad lasts until the next melody note begins.
- **Volume control**: Harmony velocity is fixed at 60 to avoid overpowering the melody.

#### 💾 File output features
- **Automatic directory creation**: Generates the `midi_output/` folder if needed.
- **Timestamped filenames**: Uses the pattern `YYYYMMDD_HHMMSS_harmony_output.mid`.
- **Console feedback**: Prints the save location for quick inspection.

#### 📊 Chord information payload
```json
{
  "time_sec": 0,
  "duration_sec": 1,
  "root_note": 60,
  "chord_name": "C Major",
  "notes": [60, 64, 67],
  "note_names": ["C", "E", "G"]
}
```

## 🧪 Test Results

### Test Case 1: C-major scale
**Input**: C-D-E-F-G-A-B-C  
**Output**: C Major → D Major → E Major → F Major → G Major → A Major → B Major → C Major

### Test Case 2: Simple progression
**Input**: C-F-G  
**Output**: C Major → F Major → G Major

### API validation
✅ All scenarios pass:
- Triads are generated correctly.
- MIDI files are saved successfully.
- Chord names appear in the response.
- API payloads follow the expected schema.

## 📁 Generated Artifacts

1. **MIDI files**: Stored in the `midi_output/` directory.
2. **Test scripts**:
   - `test_harmony.py` — core functionality tests
   - `test_direct.py` — direct API function tests
   - `test_api.py` — end-to-end API tests

## 🎼 Technical Notes

### Triad structure
- **Root**: Current melody note
- **Third**: Root + 4 semitones (major third)
- **Fifth**: Root + 7 semitones (perfect fifth)

### MIDI configuration
- **Track 1**: Melody (Piano, Channel 0)
- **Track 2**: Harmony (String Ensemble, Channel 1)
- **Resolution**: 480 ticks per beat
- **Tempo**: 120 BPM

## ✅ Completion Checklist

All planned tasks are finished:
- ✅ Generate triads from melody notes
- ✅ Save MIDI files locally
- ✅ Surface chord name information
- ✅ Integrate and test API responses

## 🚀 How to Use

1. **Unit tests**: `python test_harmony.py`
2. **API helper tests**: `python test_direct.py`
3. **Start the service**: `python main.py`
4. **Inspect output**: Review the generated MIDI files inside `midi_output/`