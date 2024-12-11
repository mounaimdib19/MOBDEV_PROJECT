// patient_maladies.dart

class PatientMaladie {
  final int idPatient;
  final int idMaladie;
  final DateTime dateDiagnostic;

  PatientMaladie({
    required this.idPatient,
    required this.idMaladie,
    required this.dateDiagnostic,
  });

  factory PatientMaladie.fromJson(Map<String, dynamic> json) {
    return PatientMaladie(
      idPatient: json['id_patient'],
      idMaladie: json['id_maladie'],
      dateDiagnostic: DateTime.parse(json['date_diagnostic']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_patient': idPatient,
      'id_maladie': idMaladie,
      'date_diagnostic': dateDiagnostic.toIso8601String(),
    };
  }
}