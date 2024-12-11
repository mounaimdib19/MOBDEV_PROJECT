// paiements.dart

class Paiement {
  final int idPaiement;
  final int idRendezVous;
  final double montant;
  final String statutPaiement;
  final String methodePaiement;
  final DateTime datePaiement;

  Paiement({
    required this.idPaiement,
    required this.idRendezVous,
    required this.montant,
    required this.statutPaiement,
    required this.methodePaiement,
    required this.datePaiement,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      idPaiement: json['id_paiement'],
      idRendezVous: json['id_rendez_vous'],
      montant: json['montant'],
      statutPaiement: json['statut_paiement'],
      methodePaiement: json['methode_paiement'],
      datePaiement: DateTime.parse(json['date_paiement']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_paiement': idPaiement,
      'id_rendez_vous': idRendezVous,
      'montant': montant,
      'statut_paiement': statutPaiement,
      'methode_paiement': methodePaiement,
      'date_paiement': datePaiement.toIso8601String(),
    };
  }
}