class BadgeDocteur {
  final int idBadge;
  final int idDoc;

  BadgeDocteur({required this.idBadge, required this.idDoc});

  factory BadgeDocteur.fromJson(Map<String, dynamic> json) {
    return BadgeDocteur(
      idBadge: json['id_badge'],
      idDoc: json['id_doc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_badge': idBadge,
      'id_doc': idDoc,
    };
  }
}
