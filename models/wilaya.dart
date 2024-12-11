class Wilaya {
  final int idWilaya;
  final String nomWilaya;

  Wilaya({required this.idWilaya, required this.nomWilaya});

  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      idWilaya: json['id_wilaya'],
      nomWilaya: json['nom_wilaya'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_wilaya': idWilaya,
      'nom_wilaya': nomWilaya,
    };
  }
}
