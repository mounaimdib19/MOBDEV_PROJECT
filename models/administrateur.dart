class Administrateur {
  final int idAdmin;
  final String nom;
  final String prenom;
  final String adresseEmail;
  final String motDePasse;
  final String? statut;
  final String type;
  final String? photoProfil;

  Administrateur({
    required this.idAdmin,
    required this.nom,
    required this.prenom,
    required this.adresseEmail,
    required this.motDePasse,
    this.statut,
    required this.type,
    this.photoProfil,
  });

  factory Administrateur.fromJson(Map<String, dynamic> json) {
    return Administrateur(
      idAdmin: json['id_admin'],
      nom: json['nom'],
      prenom: json['prenom'],
      adresseEmail: json['adresse_email'],
      motDePasse: json['mot_de_passe'],
      statut: json['statut'],
      type: json['type'],
      photoProfil: json['photo_profil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_admin': idAdmin,
      'nom': nom,
      'prenom': prenom,
      'adresse_email': adresseEmail,
      'mot_de_passe': motDePasse,
      'statut': statut,
      'type': type,
      'photo_profil': photoProfil,
    };
  }
}
