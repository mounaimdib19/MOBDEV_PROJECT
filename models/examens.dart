// examens.dart

class Examen {
  final int idExamen;
  final String nom;
  final String description;
  final double prix;

  Examen({
    required this.idExamen,
    required this.nom,
    required this.description,
    required this.prix,
  });

  factory Examen.fromJson(Map<String, dynamic> json) {
    return Examen(
      idExamen: json['id_examen'],
      nom: json['nom'],
      description: json['description'],
      prix: json['prix'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_examen': idExamen,
      'nom': nom,
      'description': description,
      'prix': prix,
    };
  }
}