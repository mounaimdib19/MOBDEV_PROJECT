// rendez_vous_examens.dart

class RendezVousExamen {
  final int idRendezVous;
  final int idExamen;

  RendezVousExamen({
    required this.idRendezVous,
    required this.idExamen,
  });

  factory RendezVousExamen.fromJson(Map<String, dynamic> json) {
    return RendezVousExamen(
      idRendezVous: json['id_rendez_vous'],
      idExamen: json['id_examen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_rendez_vous': idRendezVous,
      'id_examen': idExamen,
    };
  }
}