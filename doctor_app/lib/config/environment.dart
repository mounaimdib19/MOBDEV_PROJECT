class Environment {
  static String apiUrl = 'https://emassaha.com/API';
  static String baseImageUrl = 'https://emassaha.com/images';
    static String logout = '$apiUrl/logout.php';


 static String doctorLogin = '$apiUrl/doctor_login.php';
  static String getDoctorProfile(int doctorId) => '$apiUrl/get_doctor_profile.php?id_doc=$doctorId';
  static String updateDoctorProfile = '$apiUrl/update_doctor_profile.php';
  static String changeDoctorPassword = '$apiUrl/change_doctor_password.php';
  static String getDoctorInfo(String doctorId) => '$apiUrl/get_doctor_info.php?id_doc=$doctorId';
  static String toggleDoctorStatus = '$apiUrl/toggle_doctor_status.php';
  static String updateDoctorLocation = '$apiUrl/update_doctor_location.php';  static String get assignAssistanceRequest =>'$apiUrl/assign_assistance_request.php';
  static String getUpcomingAppointments(String doctorId) => '$apiUrl/get_upcoming_appointments.php?id_doc=$doctorId';
  static String deleteAppointment = '$apiUrl/delete_appointment.php';
  static String acceptAppointment = '$apiUrl/accept_appointment.php';
  static String completeAppointment(int idRendezVous) => '$apiUrl/complete_appointment.php?id_rendez_vous=$idRendezVous';
  static String get fetchAssistanceRequests => '$apiUrl/fetch_assistance_requests.php';



  static String fetchAssignedRequests(String doctorId) => '$apiUrl/fetch_assigned_requests.php?id_doc=$doctorId';

  static String updateFCMToken = '$apiUrl/update_fcm_token.php';
  static String deactivateToken = '$apiUrl/deactivate_fcm_token.php';  // Add this line



  static String completeAssistanceRequest = '$apiUrl/complete_assistance_request.php';
    static String getCompletedAppointments(String doctorId) => '$apiUrl/get_doctor_completed_appointments.php?id_doc=$doctorId';

 static String getProfileImageUrl(String? photoPath) {
    return photoPath != null ? '$baseImageUrl/$photoPath' : '';
  }

}