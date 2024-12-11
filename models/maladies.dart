class Maladie {
  final int idMaladie;
  final String nomMaladie;

  Maladie({required this.idMaladie, required this.nomMaladie});

  factory Maladie.fromJson(Map<String, dynamic> json) {
    return Maladie(
      idMaladie: json['id_maladie'],
      nomMaladie: json['nom_maladie'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_maladie': idMaladie,
      'nom_maladie': nomMaladie,
    };
  }
}
