class SousSpecialite {
  final int idSousSpecialite;
  final String nomSousSpecialite;
  final int specialiteParent;

  SousSpecialite({
    required this.idSousSpecialite,
    required this.nomSousSpecialite,
    required this.specialiteParent,
  });

  factory SousSpecialite.fromJson(Map<String, dynamic> json) {
    return SousSpecialite(
      idSousSpecialite: json['id_sous_specialite'],
      nomSousSpecialite: json['nom_sous_specialite'],
      specialiteParent: json['specialite_parent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_sous_specialite': idSousSpecialite,
      'nom_sous_specialite': nomSousSpecialite,
      'specialite_parent': specialiteParent,
    };
  }
}
