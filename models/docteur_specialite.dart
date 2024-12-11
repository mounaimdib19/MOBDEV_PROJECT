class DocteurSpecialite {
  final int idDoc;
  final int idSpecialite;

  DocteurSpecialite({required this.idDoc, required this.idSpecialite});

  factory DocteurSpecialite.fromJson(Map<String, dynamic> json) {
    return DocteurSpecialite(
      idDoc: json['id_doc'],
      idSpecialite: json['id_specialite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_doc': idDoc,
      'id_specialite': idSpecialite,
    };
  }
}
