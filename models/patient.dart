class Patient {
  final int idPatient;
  final String nom;
  final String prenom;
  final String? adresse;
  final int? numeroTelephone;
  final String wilaya;
  final String? commune;
  final String? parentNom;
  final int? parentNum;
  final String adresseEmail;
  final String motDePasse;
  final String? groupeSanguin;
  final String? sexe;
  final DateTime dateNaissance;
  final String? photoProfil;
  final double latitude;
  final double longitude;

  Patient({
    required this.idPatient,
    required this.nom,
    required this.prenom,
    this.adresse,
    this.numeroTelephone,
    required this.wilaya,
    this.commune,
    this.parentNom,
    this.parentNum,
    required this.adresseEmail,
    required this.motDePasse,
    this.groupeSanguin,
    this.sexe,
    required this.dateNaissance,
    this.photoProfil,
    required this.latitude,
    required this.longitude,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      idPatient: json['id_patient'],
      nom: json['nom'],
      prenom: json['prenom'],
      adresse: json['adresse'],
      numeroTelephone: json['numero_telephone'],
      wilaya: json['wilaya'],
      commune: json['commune'],
      parentNom: json['parent_nom'],
      parentNum: json['parent_num'],
      adresseEmail: json['adresse_email'],
      motDePasse: json['mot_de_passe'],
      groupeSanguin: json['groupe_sanguin'],
      sexe: json['sexe'],
      dateNaissance: DateTime.parse(json['date_naissance']),
      photoProfil: json['photo_profil'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_patient': idPatient,
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'numero_telephone': numeroTelephone,
      'wilaya': wilaya,
      'commune': commune,
      'parent_nom': parentNom,
      'parent_num': parentNum,
      'adresse_email': adresseEmail,
      'mot_de_passe': motDePasse,
      'groupe_sanguin': groupeSanguin,
      'sexe': sexe,
      'date_naissance': dateNaissance.toIso8601String(),
      'photo_profil': photoProfil,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
