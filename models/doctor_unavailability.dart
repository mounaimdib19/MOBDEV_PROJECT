// doctor_unavailability.dart

class DoctorUnavailability {
  final int idUnavailability;
  final int idDoc;
  final DateTime startTime;
  final DateTime endTime;
  final String reason;

  DoctorUnavailability({
    required this.idUnavailability,
    required this.idDoc,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  factory DoctorUnavailability.fromJson(Map<String, dynamic> json) {
    return DoctorUnavailability(
      idUnavailability: json['id_unavailability'],
      idDoc: json['id_doc'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_unavailability': idUnavailability,
      'id_doc': idDoc,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'reason': reason,
    };
  }
}