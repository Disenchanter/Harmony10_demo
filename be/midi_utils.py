import mido
from io import BytesIO
from typing import List, Dict
from models import MusicEvent


class MidiGenerator:
    """MIDI file generator"""
    
    def __init__(self):
        self.ticks_per_beat = 480  # MIDI time resolution
        self.tempo = 500000  # 120 BPM (microseconds per beat)
        # Mapping from MIDI note numbers to note names (with simplified accidentals)
        self.note_names = {
            60: 'C', 61: 'C#', 62: 'D', 63: 'D#', 64: 'E', 65: 'F', 
            66: 'F#', 67: 'G', 68: 'G#', 69: 'A', 70: 'A#', 71: 'B', 
            72: 'C', 73: 'C#', 74: 'D', 75: 'D#', 76: 'E', 77: 'F',
            78: 'F#', 79: 'G', 80: 'G#', 81: 'A', 82: 'A#', 83: 'B'
        }
    
    def create_harmonized_midi(self, events: List[MusicEvent], duration_sec: int) -> tuple:
        """
        Create a harmonized MIDI file
        - Track 1: Melody (Channel 1, Program 0 - Piano)
        - Track 2: Harmony (Channel 2, Program 48 - String Ensemble)
        - Harmony pattern: Generate triads based on melody notes

        Returns:
            tuple: (midi_bytes, chord_names_info)
        """
        # Create a MIDI file (Type 1)
        mid = mido.MidiFile(type=1)
        
        # Create the melody track
        melody_track = mido.MidiTrack()
        mid.tracks.append(melody_track)
        
        # Set tempo
        melody_track.append(mido.MetaMessage('set_tempo', tempo=self.tempo))
        melody_track.append(mido.Message('program_change', channel=0, program=0))
        
        # Create the harmony track
        harmony_track = mido.MidiTrack()
        mid.tracks.append(harmony_track)
        harmony_track.append(mido.Message('program_change', channel=1, program=48))
        
        # Process melody events
        self._add_melody_events(melody_track, events, duration_sec)
        
        # Add harmony (triads based on melody notes) and collect chord names
        chord_names_info = self._add_harmony_events(harmony_track, events, duration_sec)
        
        # Save the MIDI file locally
        midi_bytes = self._midi_to_bytes(mid)
        self._save_midi_file(mid, "harmony_output.mid")
        
        return midi_bytes, chord_names_info
    
    def _add_melody_events(self, track: mido.MidiTrack, events: List[MusicEvent], duration_sec: int):
        """Add melody events to the track"""
        # Sort events by time
        sorted_events = sorted(events, key=lambda x: x.t_sec)
        
        current_time = 0
        current_note = None
        
        for event in sorted_events:
            # Calculate the time delta (in ticks) to reach this event
            event_time_ticks = event.t_sec * self.ticks_per_beat
            delta_time = event_time_ticks - current_time
            
            # Stop the currently playing note if needed
            if current_note is not None:
                track.append(mido.Message('note_off', 
                                        channel=0, 
                                        note=current_note, 
                                        velocity=0, 
                                        time=delta_time))
                current_time = event_time_ticks
                delta_time = 0
            
            # Start a new note
            track.append(mido.Message('note_on', 
                                    channel=0, 
                                    note=event.note, 
                                    velocity=event.vel, 
                                    time=delta_time))
            current_note = event.note
            current_time = event_time_ticks
        
        # Ensure the last note stops at the end
        if current_note is not None:
            end_time_ticks = duration_sec * self.ticks_per_beat
            delta_time = end_time_ticks - current_time
            track.append(mido.Message('note_off', 
                                    channel=0, 
                                    note=current_note, 
                                    velocity=0, 
                                    time=delta_time))
    
    def _add_harmony_events(self, track: mido.MidiTrack, events: List[MusicEvent], duration_sec: int) -> List[Dict]:
        """
        Add harmony events
        Generate triads using each melody note as the root

        Returns:
            List[Dict]: List of chord information including time, root name, etc.
        """
        # Sort events by time
        sorted_events = sorted(events, key=lambda x: x.t_sec)
        
        # Generate a triad for each melody note
        current_chord = None
        current_time = 0
        chord_names_info = []
        
        for i, event in enumerate(sorted_events):
            # Calculate the duration of the current chord
            if i < len(sorted_events) - 1:
                chord_end_time = sorted_events[i + 1].t_sec
            else:
                chord_end_time = duration_sec
            
            # End the current chord
            if current_chord is not None:
                event_time_ticks = event.t_sec * self.ticks_per_beat
                delta_time = event_time_ticks - current_time
                
                for j, note in enumerate(current_chord):
                    note_off_time = delta_time if j == 0 else 0
                    track.append(mido.Message('note_off', 
                                            channel=1, 
                                            note=note, 
                                            velocity=0, 
                                            time=note_off_time))
                current_time = event_time_ticks
            
            # Generate a new triad (root + third + fifth)
            root_note = event.note
            third = root_note + 4  # Major third
            fifth = root_note + 7  # Perfect fifth
            current_chord = [root_note, third, fifth]
            
            # Record chord details
            root_name = self.note_names.get(root_note, f'Unknown({root_note})')
            chord_names_info.append({
                'time_sec': event.t_sec,
                'duration_sec': chord_end_time - event.t_sec,
                'root_note': root_note,
                'chord_name': f'{root_name} Major',
                'notes': current_chord,
                'note_names': [self.note_names.get(note, f'Unknown({note})') for note in current_chord]
            })
            
            # Start the new chord
            start_time_ticks = event.t_sec * self.ticks_per_beat
            delta_time = start_time_ticks - current_time if current_time > 0 else start_time_ticks
            
            for j, note in enumerate(current_chord):
                note_on_time = delta_time if j == 0 else 0
                track.append(mido.Message('note_on', 
                                        channel=1, 
                                        note=note, 
                                        velocity=60,  # Lower velocity keeps harmony balanced
                                        time=note_on_time))
            
            current_time = start_time_ticks
        
        # End the final chord
        if current_chord is not None:
            end_time_ticks = duration_sec * self.ticks_per_beat
            delta_time = end_time_ticks - current_time
            
            for j, note in enumerate(current_chord):
                note_off_time = delta_time if j == 0 else 0
                track.append(mido.Message('note_off', 
                                        channel=1, 
                                        note=note, 
                                        velocity=0, 
                                        time=note_off_time))
        
        return chord_names_info
    
    def _midi_to_bytes(self, mid: mido.MidiFile) -> bytes:
        """Convert a MIDI object to bytes"""
        bytes_io = BytesIO()
        mid.save(file=bytes_io)
        return bytes_io.getvalue()
    
    def _save_midi_file(self, mid: mido.MidiFile, filename: str) -> str:
        """
        Save the MIDI file locally

        Args:
            mid: MIDI file object
            filename: Output filename

        Returns:
            str: Path of the saved file
        """
        import os
        # Ensure the output directory exists
        output_dir = "midi_output"
        os.makedirs(output_dir, exist_ok=True)
        
        # Generate a timestamped filename
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        final_filename = f"{timestamp}_{filename}"
        filepath = os.path.join(output_dir, final_filename)
        
        # Save the file
        mid.save(filepath)
        print(f"MIDI file saved to: {filepath}")
        return filepath


class ReferenceTemplates:
    """Reference template manager"""
    
    @staticmethod
    def get_reference_template(reference_id: str) -> Dict[int, int]:
        """
        Retrieve the reference template (seconds -> target note mapping)
        """
        templates = {
            "exercise_c_major_01": {
                0: 60,  # C
                1: 62,  # D
                2: 64,  # E
                3: 65,  # F
                4: 67,  # G
                5: 69,  # A
                6: 71,  # B
                7: 60,  # C (octave)
                8: 62,  # D
                9: 64   # E
            }
        }
        
        if reference_id not in templates:
            raise ValueError("Reference not found")
        
        return templates[reference_id]


class MusicEvaluator:
    """Music evaluator"""
    
    def __init__(self):
        self.reference_templates = ReferenceTemplates()
    
    def evaluate_performance(self, events: List[MusicEvent], reference_id: str, duration_sec: int) -> Dict:
        """
        Evaluate performance - supports any number of notes
        """
        try:
            reference = self.reference_templates.get_reference_template(reference_id)
        except ValueError:
            raise ValueError("Reference not found")
        
        # Convert events to a time -> note map
        played_notes = {}
        for event in events:
            if event.t_sec < duration_sec:
                played_notes[event.t_sec] = event.note
        
        # Calculate the score - only check times present in the reference template
        total_points = 0
        correct_notes = 0
        mistakes = []
        
        # Get the valid time range in the reference template
        reference_times = [t for t in reference.keys() if t < duration_sec]
        
        # Check each time point in the reference template
        for sec in reference_times:
            expected_note = reference[sec]
            total_points += 1
            
            if sec in played_notes:
                played_note = played_notes[sec]
                if played_note == expected_note:
                    correct_notes += 1
                else:
                    mistakes.append({
                        "time_sec": sec,
                        "expected_note": expected_note,
                        "played_note": played_note,
                        "error_type": "wrong_note"
                    })
            else:
                mistakes.append({
                    "time_sec": sec,
                    "expected_note": expected_note,
                    "played_note": None,
                    "error_type": "missing_note"
                })
        
        # Check for extra notes - only consider notes not in the reference template
        for sec, note in played_notes.items():
            if sec not in reference or reference[sec] != note:
                # Avoid duplicating errors already recorded
                if not any(m.get("time_sec") == sec for m in mistakes):
                    mistakes.append({
                        "time_sec": sec,
                        "expected_note": reference.get(sec),
                        "played_note": note,
                        "error_type": "extra_note"
                    })
        
        # Calculate the score - handle the case when the reference is empty
        if total_points > 0:
            accuracy_score = (correct_notes / total_points) * 100
        else:
            # If there are no reference points but notes were played, grant a baseline score
            accuracy_score = 50.0 if played_notes else 100.0
        
        # Timing accuracy score
        timing_penalty = len([m for m in mistakes if m["error_type"] in ["missing_note", "extra_note"]]) * 10
        timing_score = max(0, 100 - timing_penalty)
        
        # Overall score
        overall_score = (accuracy_score * 0.7 + timing_score * 0.3)
        
        # Generate advice
        advice = self._generate_advice(mistakes, correct_notes, total_points)
        
        return {
            "score": round(overall_score, 1),
            "subscores": {
                "accuracy": round(accuracy_score, 1),
                "timing": round(timing_score, 1)
            },
            "mistakes": mistakes,
            "advice": advice
        }
    
    def _generate_advice(self, mistakes: List[Dict], correct_notes: int, total_points: int) -> str:
        """Generate improvement advice - handles multiple situations"""
        if not mistakes:
            return "Perfect performance! Keep up the excellent work!"
        
        advice_parts = []
        
        wrong_notes = [m for m in mistakes if m["error_type"] == "wrong_note"]
        missing_notes = [m for m in mistakes if m["error_type"] == "missing_note"]
        extra_notes = [m for m in mistakes if m["error_type"] == "extra_note"]
        
        if wrong_notes:
            advice_parts.append(f"Focus on accuracy - you played {len(wrong_notes)} wrong notes.")
        
        if missing_notes:
            advice_parts.append(f"Don't miss notes - you missed {len(missing_notes)} notes.")
        
        if extra_notes:
            advice_parts.append(f"Avoid extra notes - you played {len(extra_notes)} additional notes.")
        
        # Handle the case with zero reference points
        if total_points == 0:
            advice_parts.append("No reference template available for this duration.")
        elif correct_notes / total_points >= 0.8:
            advice_parts.append("You're doing well overall, just need minor adjustments.")
        elif correct_notes / total_points >= 0.6:
            advice_parts.append("Good progress, but practice more to improve accuracy.")
        else:
            advice_parts.append("Focus on learning the basic melody pattern first.")
        
        return " ".join(advice_parts) if advice_parts else "Keep practicing!"