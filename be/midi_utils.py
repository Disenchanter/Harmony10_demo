import mido
from io import BytesIO
from typing import List, Dict
from models import MusicEvent


class MidiGenerator:
    """MIDI文件生成器"""
    
    def __init__(self):
        self.ticks_per_beat = 480  # MIDI 时间分辨率
        self.tempo = 500000  # 120 BPM (microseconds per beat)
        # MIDI音符号到音符名称的映射（包含升降号简化处理）
        self.note_names = {
            60: 'C', 61: 'C#', 62: 'D', 63: 'D#', 64: 'E', 65: 'F', 
            66: 'F#', 67: 'G', 68: 'G#', 69: 'A', 70: 'A#', 71: 'B', 
            72: 'C', 73: 'C#', 74: 'D', 75: 'D#', 76: 'E', 77: 'F',
            78: 'F#', 79: 'G', 80: 'G#', 81: 'A', 82: 'A#', 83: 'B'
        }
    
    def create_harmonized_midi(self, events: List[MusicEvent], duration_sec: int) -> tuple:
        """
        创建带和声的 MIDI 文件
        - 轨道1: 旋律 (Channel 1, Program 0 - Piano)  
        - 轨道2: 和声 (Channel 2, Program 48 - String Ensemble)
        - 和声规律: 根据旋律音符生成对应的三和弦
        
        Returns:
            tuple: (midi_bytes, chord_names_info)
        """
        # 创建 MIDI 文件 (Type 1)
        mid = mido.MidiFile(type=1)
        
        # 创建旋律轨道
        melody_track = mido.MidiTrack()
        mid.tracks.append(melody_track)
        
        # 设置 tempo
        melody_track.append(mido.MetaMessage('set_tempo', tempo=self.tempo))
        melody_track.append(mido.Message('program_change', channel=0, program=0))
        
        # 创建和声轨道
        harmony_track = mido.MidiTrack()
        mid.tracks.append(harmony_track)
        harmony_track.append(mido.Message('program_change', channel=1, program=48))
        
        # 处理旋律事件
        self._add_melody_events(melody_track, events, duration_sec)
        
        # 添加和声（基于旋律音符生成三和弦）并获取和弦名称
        chord_names_info = self._add_harmony_events(harmony_track, events, duration_sec)
        
        # 保存MIDI文件到本地
        midi_bytes = self._midi_to_bytes(mid)
        self._save_midi_file(mid, "harmony_output.mid")
        
        return midi_bytes, chord_names_info
    
    def _add_melody_events(self, track: mido.MidiTrack, events: List[MusicEvent], duration_sec: int):
        """添加旋律事件到轨道"""
        # 按时间排序事件
        sorted_events = sorted(events, key=lambda x: x.t_sec)
        
        current_time = 0
        current_note = None
        
        for event in sorted_events:
            # 计算到达该事件的时间差 (以 ticks 为单位)
            event_time_ticks = event.t_sec * self.ticks_per_beat
            delta_time = event_time_ticks - current_time
            
            # 如果有正在播放的音符，先停止它
            if current_note is not None:
                track.append(mido.Message('note_off', 
                                        channel=0, 
                                        note=current_note, 
                                        velocity=0, 
                                        time=delta_time))
                current_time = event_time_ticks
                delta_time = 0
            
            # 开始新音符
            track.append(mido.Message('note_on', 
                                    channel=0, 
                                    note=event.note, 
                                    velocity=event.vel, 
                                    time=delta_time))
            current_note = event.note
            current_time = event_time_ticks
        
        # 在最后停止任何正在播放的音符
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
        添加和声事件
        根据旋律中每个音符作为根音生成三和弦
        
        Returns:
            List[Dict]: 和弦信息列表，包含时间、根音名称等
        """
        # 按时间排序事件
        sorted_events = sorted(events, key=lambda x: x.t_sec)
        
        # 为每个旋律音符生成三和弦
        current_chord = None
        current_time = 0
        chord_names_info = []
        
        for i, event in enumerate(sorted_events):
            # 计算当前和弦的持续时间
            if i < len(sorted_events) - 1:
                chord_end_time = sorted_events[i + 1].t_sec
            else:
                chord_end_time = duration_sec
            
            # 结束当前和弦
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
            
            # 生成新的三和弦 (根音 + 三音 + 五音)
            root_note = event.note
            third = root_note + 4  # 大三度
            fifth = root_note + 7  # 纯五度
            current_chord = [root_note, third, fifth]
            
            # 记录和弦信息
            root_name = self.note_names.get(root_note, f'Unknown({root_note})')
            chord_names_info.append({
                'time_sec': event.t_sec,
                'duration_sec': chord_end_time - event.t_sec,
                'root_note': root_note,
                'chord_name': f'{root_name} Major',
                'notes': current_chord,
                'note_names': [self.note_names.get(note, f'Unknown({note})') for note in current_chord]
            })
            
            # 开始新和弦
            start_time_ticks = event.t_sec * self.ticks_per_beat
            delta_time = start_time_ticks - current_time if current_time > 0 else start_time_ticks
            
            for j, note in enumerate(current_chord):
                note_on_time = delta_time if j == 0 else 0
                track.append(mido.Message('note_on', 
                                        channel=1, 
                                        note=note, 
                                        velocity=60,  # 较小的音量避免和声太突出
                                        time=note_on_time))
            
            current_time = start_time_ticks
        
        # 结束最后的和弦
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
        """将 MIDI 对象转换为字节"""
        bytes_io = BytesIO()
        mid.save(file=bytes_io)
        return bytes_io.getvalue()
    
    def _save_midi_file(self, mid: mido.MidiFile, filename: str) -> str:
        """
        保存MIDI文件到本地
        
        Args:
            mid: MIDI文件对象
            filename: 保存的文件名
            
        Returns:
            str: 保存的文件路径
        """
        import os
        # 确保输出目录存在
        output_dir = "midi_output"
        os.makedirs(output_dir, exist_ok=True)
        
        # 生成带时间戳的文件名
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        final_filename = f"{timestamp}_{filename}"
        filepath = os.path.join(output_dir, final_filename)
        
        # 保存文件
        mid.save(filepath)
        print(f"MIDI文件已保存到: {filepath}")
        return filepath


class ReferenceTemplates:
    """参考模板管理器"""
    
    @staticmethod
    def get_reference_template(reference_id: str) -> Dict[int, int]:
        """
        获取参考模板 (秒 -> 目标音符映射)
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
    """音乐评估器"""
    
    def __init__(self):
        self.reference_templates = ReferenceTemplates()
    
    def evaluate_performance(self, events: List[MusicEvent], reference_id: str, duration_sec: int) -> Dict:
        """
        评估演奏表现 - 支持任意数量的音符
        """
        try:
            reference = self.reference_templates.get_reference_template(reference_id)
        except ValueError:
            raise ValueError("Reference not found")
        
        # 将事件转换为时间->音符映射
        played_notes = {}
        for event in events:
            if event.t_sec < duration_sec:
                played_notes[event.t_sec] = event.note
        
        # 计算评分 - 只检查参考模板中实际存在的时间点
        total_points = 0
        correct_notes = 0
        mistakes = []
        
        # 获取参考模板中的有效时间范围
        reference_times = [t for t in reference.keys() if t < duration_sec]
        
        # 检查参考模板中的每个时间点
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
        
        # 检查多余的音符 - 只检查不在参考模板中的演奏音符
        for sec, note in played_notes.items():
            if sec not in reference or reference[sec] != note:
                # 避免重复添加已经记录的错误
                if not any(m.get("time_sec") == sec for m in mistakes):
                    mistakes.append({
                        "time_sec": sec,
                        "expected_note": reference.get(sec),
                        "played_note": note,
                        "error_type": "extra_note"
                    })
        
        # 计算得分 - 处理空参考的情况
        if total_points > 0:
            accuracy_score = (correct_notes / total_points) * 100
        else:
            # 如果没有参考点，但有演奏音符，给予基础分数
            accuracy_score = 50.0 if played_notes else 100.0
        
        # 时间精度评分
        timing_penalty = len([m for m in mistakes if m["error_type"] in ["missing_note", "extra_note"]]) * 10
        timing_score = max(0, 100 - timing_penalty)
        
        # 整体评分
        overall_score = (accuracy_score * 0.7 + timing_score * 0.3)
        
        # 生成建议
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
        """生成改进建议 - 处理各种情况"""
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
        
        # 处理零参考点的情况
        if total_points == 0:
            advice_parts.append("No reference template available for this duration.")
        elif correct_notes / total_points >= 0.8:
            advice_parts.append("You're doing well overall, just need minor adjustments.")
        elif correct_notes / total_points >= 0.6:
            advice_parts.append("Good progress, but practice more to improve accuracy.")
        else:
            advice_parts.append("Focus on learning the basic melody pattern first.")
        
        return " ".join(advice_parts) if advice_parts else "Keep practicing!"