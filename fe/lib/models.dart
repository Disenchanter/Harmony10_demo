class MusicEvent {
  final int tSec;
  final int note;
  final int vel;

  const MusicEvent({
    required this.tSec,
    required this.note,
    this.vel = 96,
  });

  factory MusicEvent.fromJson(Map<String, dynamic> json) => MusicEvent(
        tSec: json['t_sec'] as int,
        note: json['note'] as int,
        vel: json['vel'] as int? ?? 96,
      );

  Map<String, dynamic> toJson() => {
        't_sec': tSec,
        'note': note,
        'vel': vel,
      };
}

class HarmonizeRequest {
  final String version;
  final String mode;
  final int durationSec;
  final String quantize;
  final String octaveBase;
  final String key;
  final String returnMode;
  final List<MusicEvent> events;

  const HarmonizeRequest({
    this.version = '1.0',
    this.mode = 'harmonize',
    required this.durationSec,
    this.quantize = '1s',
    this.octaveBase = 'C4',
    this.key = 'C major',
    this.returnMode = 'bytes',
    required this.events,
  });

  factory HarmonizeRequest.fromJson(Map<String, dynamic> json) =>
      HarmonizeRequest(
        version: json['version'] as String,
        mode: json['mode'] as String,
        durationSec: json['duration_sec'] as int,
        quantize: json['quantize'] as String,
        octaveBase: json['octave_base'] as String,
        key: json['key'] as String,
        returnMode: json['return_mode'] as String,
        events: (json['events'] as List)
            .map((e) => MusicEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'mode': mode,
        'duration_sec': durationSec,
        'quantize': quantize,
        'octave_base': octaveBase,
        'key': key,
        'return_mode': returnMode,
        'events': events.map((e) => e.toJson()).toList(),
      };
}

class EvaluateRequest {
  final String version;
  final String mode;
  final int durationSec;
  final String quantize;
  final String octaveBase;
  final String key;
  final String referenceId;
  final List<MusicEvent> events;

  const EvaluateRequest({
    this.version = '1.0',
    this.mode = 'evaluate',
    required this.durationSec,
    this.quantize = '1s',
    this.octaveBase = 'C4',
    this.key = 'C major',
    this.referenceId = 'exercise_c_major_01',
    required this.events,
  });

  factory EvaluateRequest.fromJson(Map<String, dynamic> json) =>
      EvaluateRequest(
        version: json['version'] as String,
        mode: json['mode'] as String,
        durationSec: json['duration_sec'] as int,
        quantize: json['quantize'] as String,
        octaveBase: json['octave_base'] as String,
        key: json['key'] as String,
        referenceId: json['reference_id'] as String,
        events: (json['events'] as List)
            .map((e) => MusicEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'mode': mode,
        'duration_sec': durationSec,
        'quantize': quantize,
        'octave_base': octaveBase,
        'key': key,
        'reference_id': referenceId,
        'events': events.map((e) => e.toJson()).toList(),
      };
}

class EvaluateResponse {
  final double score;
  final Map<String, double> subscores;
  final List<Mistake> mistakes;
  final String advice;

  const EvaluateResponse({
    required this.score,
    required this.subscores,
    required this.mistakes,
    required this.advice,
  });

  factory EvaluateResponse.fromJson(Map<String, dynamic> json) =>
      EvaluateResponse(
        score: (json['score'] as num).toDouble(),
        subscores: Map<String, double>.from(
          (json['subscores'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        ),
        mistakes: (json['mistakes'] as List)
            .map((e) => Mistake.fromJson(e as Map<String, dynamic>))
            .toList(),
        advice: json['advice'] as String,
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'subscores': subscores,
        'mistakes': mistakes.map((e) => e.toJson()).toList(),
        'advice': advice,
      };
}

class Mistake {
  final int timeSec;
  final int? expectedNote;
  final int? playedNote;
  final String errorType;

  const Mistake({
    required this.timeSec,
    this.expectedNote,
    this.playedNote,
    required this.errorType,
  });

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
        timeSec: json['time_sec'] as int,
        expectedNote: json['expected_note'] as int?,
        playedNote: json['played_note'] as int?,
        errorType: json['error_type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'time_sec': timeSec,
        'expected_note': expectedNote,
        'played_note': playedNote,
        'error_type': errorType,
      };
}

class ErrorResponse {
  final String errorCode;
  final String message;
  final Map<String, dynamic>? details;

  const ErrorResponse({
    required this.errorCode,
    required this.message,
    this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
        errorCode: json['error_code'] as String,
        message: json['message'] as String,
        details: json['details'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'error_code': errorCode,
        'message': message,
        if (details != null) 'details': details!,
      };
}