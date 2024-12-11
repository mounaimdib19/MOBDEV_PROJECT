class RendezVous {
  final int idRendezVous;
  final int idDoc;
  final int idPatient;
  final DateTime dateHeureRendezVous;
  final String? motifConsultation;
  final String statut;
  final DateTime? dateHeureCreation;

  RendezVous({
    required this.idRendezVous,
    required this.idDoc,
    required this.idPatient,
    required this.dateHeureRendezVous,
    this.motifConsultation,
    required this.statut,
    this.dateHeureCreation,
  });

  factory RendezVous.fromJson(Map<String, dynamic> json) {
    return RendezVous(
      idRendezVous: json['id_rendez_vous'],
      idDoc: json['id_doc'],
      idPatient: json['id_patient'],
      dateHeureRendezVous: DateTime.parse(json['date_heure_rendez_vous']),
      motifConsultation: json['motif_consultation'],
      statut: json['statut'],
      dateHeureCreation: json['date_heure_creation'] != null
          ? DateTime.parse(json['date_heure_creation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_rendez_vous': idRendezVous,
      'id_doc': idDoc,
      'id_patient': idPatient,
      'date_heure_rendez_vous': dateHeureRendezVous.toIso8601String(),
      'motif_consultation': motifConsultation,
      'statut': statut,
      'date_heure_creation': dateHeureCreation?.toIso8601String(),
    };
  }
}
