class Commune {
  final int idCommune;
  final String nomCommune;
  final int idWilaya;

  Commune({required this.idCommune, required this.nomCommune, required this.idWilaya});

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      idCommune: json['id_commune'],
      nomCommune: json['nom_commune'],
      idWilaya: json['id_wilaya'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_commune': idCommune,
      'nom_commune': nomCommune,
      'id_wilaya': idWilaya,
    };
  }
}
