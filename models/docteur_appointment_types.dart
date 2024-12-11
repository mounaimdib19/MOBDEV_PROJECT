class DoctorAppointmentType {
  final int idDoctorAppointmentType;
  final int idDoc;
  final int idAppointmentType;
  final int duration;

  DoctorAppointmentType({
    required this.idDoctorAppointmentType,
    required this.idDoc,
    required this.idAppointmentType,
    required this.duration,
  });

  factory DoctorAppointmentType.fromJson(Map<String, dynamic> json) {
    return DoctorAppointmentType(
      idDoctorAppointmentType: json['id_doctor_appointment_type'],
      idDoc: json['id_doc'],
      idAppointmentType: json['id_appointment_type'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_doctor_appointment_type': idDoctorAppointmentType,
      'id_doc': idDoc,
      'id_appointment_type': idAppointmentType,
      'duration': duration,
    };
  }
}
