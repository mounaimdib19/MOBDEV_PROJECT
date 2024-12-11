// rendez_vous_traitements.dart

class RendezVousTraitement {
  final int idRendezVous;
  final int idTraitement;

  RendezVousTraitement({
    required this.idRendezVous,
    required this.idTraitement,
  });

  factory RendezVousTraitement.fromJson(Map<String, dynamic> json) {
    return RendezVousTraitement(
      idRendezVous: json['id_rendez_vous'],
      idTraitement: json['id_traitement'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_rendez_vous': idRendezVous,
      'id_traitement': idTraitement,
    };
  }
}