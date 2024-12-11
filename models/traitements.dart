// traitements.dart

class Traitement {
  final int idTraitement;
  final String nom;
  final String description;
  final double prix;

  Traitement({
    required this.idTraitement,
    required this.nom,
    required this.description,
    required this.prix,
  });

  factory Traitement.fromJson(Map<String, dynamic> json) {
    return Traitement(
      idTraitement: json['id_traitement'],
      nom: json['nom'],
      description: json['description'],
      prix: json['prix'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_traitement': idTraitement,
      'nom': nom,
      'description': description,
      'prix': prix,
    };
  }
}