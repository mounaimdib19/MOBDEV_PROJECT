class Badge {
  final int idBadge;
  final String nomBadge;

  Badge({required this.idBadge, required this.nomBadge});

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      idBadge: json['id_badge'],
      nomBadge: json['nom_badge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_badge': idBadge,
      'nom_badge': nomBadge,
    };
  }
}
