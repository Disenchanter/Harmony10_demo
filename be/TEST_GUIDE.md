# Music Harmony API Test Guide

This guide explains how to exercise the two primary endpoints exposed by the Music Harmony API and shows the expected responses.

## Start the server

```bash
# Install dependencies
pip install -r requirements.txt

# Start the server
python run.py
```

The server listens on `http://127.0.0.1:8000`.

You can open `http://127.0.0.1:8000/docs` to view the automatically generated API schema.

## Endpoint tests

### 1. Harmonize endpoint

**Purpose**: Generate a harmonized MIDI file based on the submitted melody events.

**cURL command**:

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
       "events":[
         {"t_sec":0,"note":60},
         {"t_sec":3,"note":64},
         {"t_sec":7,"note":67}
       ]
     }' \
     --output harmony.mid
```

**Expected result**: A file named `harmony.mid` is created containing:
- Track 1: Melody (Piano, Channel 1)
- Track 2: Harmony (String Ensemble, Channel 2)
- Harmony voicing: each melody event generates a root-position major triad (root, +4, +7 semitones) that lasts until the next event.

### 2. Evaluate endpoint

**Purpose**: Compare a user performance to a reference template and produce a score report.

**cURL command**:

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"evaluate",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "reference_id":"exercise_c_major_01",
       "events":[
         {"t_sec":0,"note":60},
         {"t_sec":1,"note":62},
         {"t_sec":2,"note":64}
       ]
     }'
```

**Expected result**: The API returns a JSON report containing:
```json
{
  "score": 30.0,
  "subscores": {
    "accuracy": 30.0,
    "timing": 30.0
  },
  "mistakes": [
    {
      "time_sec": 3,
      "expected_note": 65,
      "played_note": null,
      "error_type": "missing_note"
    },
    ...
  ],
  "advice": "Don't miss notes - you missed 7 notes. Focus on learning the basic melody pattern first."
}
```

## Error scenarios

### 1. Unsupported version

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/harmonize" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"2.0",
       "mode":"harmonize",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "return_mode":"bytes",
       "events":[{"t_sec":0,"note":60}]
     }'
```

**Expected error**: `unsupported_version`

### 2. Invalid note

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
       "events":[{"t_sec":0,"note":61}]
     }'
```

**Expected error**: `invalid_note`

### 3. Duplicate timeslot

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
       "events":[
         {"t_sec":0,"note":60},
         {"t_sec":0,"note":64}
       ]
     }'
```

**Expected error**: `duplicate_timeslot`

### 4. Missing reference template

```bash
curl -X POST "http://127.0.0.1:8000/api/v1/evaluate" \
     -H "Content-Type: application/json" \
     -d '{
       "version":"1.0",
       "mode":"evaluate",
       "duration_sec":10,
       "quantize":"1s",
       "octave_base":"C4",
       "key":"C major",
       "reference_id":"nonexistent_template",
       "events":[{"t_sec":0,"note":60}]
     }'
```

**Expected error**: `reference_not_found`

## Reference templates

### exercise_c_major_01

Built-in C-major exercise template:

```
Time (seconds) → Target note
0 -> 60 (C)
1 -> 62 (D)  
2 -> 64 (E)
3 -> 65 (F)
4 -> 67 (G)
5 -> 69 (A)
6 -> 71 (B)
7 -> 60 (C)
8 -> 62 (D)
9 -> 64 (E)
```

## Technical specification

- **Quantization**: Fixed to 1 second (t_sec ∈ [0..9])
- **Key**: Fixed to C major
- **White-key set**: {60, 62, 64, 65, 67, 69, 71}
- **Per-second rule**: Keep only the last click within the same second
- **Default velocity**: vel = 96
- **MIDI format**: Type-1 
  - Track 1: Channel 1, Program 0 (Piano)
  - Track 2: Channel 2, Program 48 (String Ensemble)

## Harmony generation rule

- For every recorded melody event at `t_sec`, the backend creates a major triad `[note, note+4, note+7]`.
- The harmony notes sustain until the next melody event starts (or the clip ends).
- The response metadata includes chord descriptors (for example, “C Major”, “D Major”).

## Troubleshooting

If something goes wrong:

1. Confirm the server is running (`http://127.0.0.1:8000`).
2. Check that the request JSON is well-formed.
3. Verify all required fields are supplied.
4. Ensure the note values belong to the white-key set.
5. Review the server logs for detailed error information.