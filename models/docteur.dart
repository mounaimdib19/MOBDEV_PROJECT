class Docteur {
  final int idDoc;
  final String nom;
  final String prenom;
  final String? adresse;
  final int? idWilaya;
  final int? idCommune;
  final String adresseEmail;
  final String motDePasse;
  final String? numeroTelephone;
  final bool consultationDomicile;
  final bool consultationCabinet;
  final bool estInfirmier;
  final int? prixConsultation;
  final String? photoProfil;
  final double? latitude;
  final double? longitude;
  final String status;

  Docteur({
    required this.idDoc,
    required this.nom,
    required this.prenom,
    this.adresse,
    this.idWilaya,
    this.idCommune,
    required this.adresseEmail,
    required this.motDePasse,
    this.numeroTelephone,
    required this.consultationDomicile,
    required this.consultationCabinet,
    required this.estInfirmier,
    this.prixConsultation,
    this.photoProfil,
    this.latitude,
    this.longitude,
    required this.status,
  });

  factory Docteur.fromJson(Map<String, dynamic> json) {
    return Docteur(
      idDoc: json['id_doc'],
      nom: json['nom'],
      prenom: json['prenom'],
      adresse: json['adresse'],
      idWilaya: json['id_wilaya'],
      idCommune: json['id_commune'],
      adresseEmail: json['adresse_email'],
      motDePasse: json['mot_de_passe'],
      numeroTelephone: json['numero_telephone'],
      consultationDomicile: json['consultation_domicile'],
      consultationCabinet: json['consultation_cabinet'],
      estInfirmier: json['est_infirmier'],
      prixConsultation: json['prix_consultation'],
      photoProfil: json['photo_profil'],
      latitude: json['Latitude'],
      longitude: json['longitude'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_doc': idDoc,
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'id_wilaya': idWilaya,
      'id_commune': idCommune,
      'adresse_email': adresseEmail,
      'mot_de_passe': motDePasse,
      'numero_telephone': numeroTelephone,
      'consultation_domicile': consultationDomicile,
      'consultation_cabinet': consultationCabinet,
      'est_infirmier': estInfirmier,
      'prix_consultation': prixConsultation,
      'photo_profil': photoProfil,
      'Latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
