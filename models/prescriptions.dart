// prescriptions.dart

class Prescription {
  final int idPrescription;
  final int idRendezVous;
  final String description;
  final DateTime creeLe;

  Prescription({
    required this.idPrescription,
    required this.idRendezVous,
    required this.description,
    required this.creeLe,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      idPrescription: json['id_prescription'],
      idRendezVous: json['id_rendez_vous'],
      description: json['description'],
      creeLe: DateTime.parse(json['cree_le']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_prescription': idPrescription,
      'id_rendez_vous': idRendezVous,
      'description': description,
      'cree_le': creeLe.toIso8601String(),
    };
  }
}