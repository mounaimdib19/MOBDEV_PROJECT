class Horaires {
  final int idHoraire;
  final int idDoc;
  final String jour;
  final String ouverture;
  final String fermeture;
  final String statut;

  Horaires({
    required this.idHoraire,
    required this.idDoc,
    required this.jour,
    required this.ouverture,
    required this.fermeture,
    required this.statut,
  });

  factory Horaires.fromJson(Map<String, dynamic> json) {
    return Horaires(
      idHoraire: json['id_horaire'],
      idDoc: json['id_doc'],
      jour: json['jour'],
      ouverture: json['ouverture'],
      fermeture: json['fermeture'],
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_horaire': idHoraire,
      'id_doc': idDoc,
      'jour': jour,
      'ouverture': ouverture,
      'fermeture': fermeture,
      'statut': statut,
    };
  }
}
