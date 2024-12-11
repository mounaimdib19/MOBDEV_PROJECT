class Specialite {
  final int idSpecialite;
  final String nomSpecialite;

  Specialite({required this.idSpecialite, required this.nomSpecialite});

  factory Specialite.fromJson(Map<String, dynamic> json) {
    return Specialite(
      idSpecialite: json['id_specialite'],
      nomSpecialite: json['nom_specialite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_specialite': idSpecialite,
      'nom_specialite': nomSpecialite,
    };
  }
}
