class DocteurSousSpecialite {
  final int idDoc;
  final int idSousSpecialite;

  DocteurSousSpecialite({required this.idDoc, required this.idSousSpecialite});

  factory DocteurSousSpecialite.fromJson(Map<String, dynamic> json) {
    return DocteurSousSpecialite(
      idDoc: json['id_doc'],
      idSousSpecialite: json['id_sous_specialite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_doc': idDoc,
      'id_sous_specialite': idSousSpecialite,
    };
  }
}
