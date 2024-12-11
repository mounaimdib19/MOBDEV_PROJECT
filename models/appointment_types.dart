class AppointmentType {
  final int idAppointmentType;
  final String name;

  AppointmentType({required this.idAppointmentType, required this.name});

  factory AppointmentType.fromJson(Map<String, dynamic> json) {
    return AppointmentType(
      idAppointmentType: json['id_appointment_type'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_appointment_type': idAppointmentType,
      'name': name,
    };
  }
}
