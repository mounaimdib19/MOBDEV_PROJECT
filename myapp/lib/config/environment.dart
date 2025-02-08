class Environment {
  static String apiUrl = 'https://emassaha.com/API';
  static String baseImageUrl = 'https://emassaha.com/images';
  static String baseUploadUrl = 'https://emassaha.com/upload';

  // Authentication Endpoints
  static String patientSignup = '$apiUrl/patient_signup.php';
  static String patientLogin = '$apiUrl/patient_login.php';
  static String logout = '$apiUrl/logout.php';

  static String get checkAssistantAssignment => "$apiUrl/check_assignment.php";

  static const Duration timeoutDuration = Duration(seconds: 30);

  // Patient-related Endpoints
  // In environment.dart, add this new endpoint:
static String get adminNotifications => "$apiUrl/admin_notifications.php";
  static String getUserInfo(int patientId) => '$apiUrl/get_user_info.php?id_patient=$patientId';
  static String getPatientPhoneNumber(int patientId) => '$apiUrl/get_patient_phone.php?id_patient=$patientId';
  static String submitAssistanceRequest = '$apiUrl/submit_assistance_request.php';
  static String changePassword = '$apiUrl/change_password.php';
  
  // Patient Profile Endpoints
  static String getPatientProfile(int patientId) => '$apiUrl/get_patient_profile.php?id_patient=$patientId';
  static String updatePatientProfile = '$apiUrl/update_patient_profile.php';

  // Appointment-related Endpoints
  static String getUpcomingAppointments(String patientId) => '$apiUrl/get_upcoming_appointments.php?id_patient=$patientId';
  static String deleteAppointment = '$apiUrl/delete_appointment.php';
  static String acceptAppointment = '$apiUrl/accept_appointment.php';
  static String completeAppointment = '$apiUrl/complete_appointment.php';
  static String cancelAppointment = '$apiUrl/cancel_appointment.php';

  // Patient Appointments Endpoints
  static String getPatientCompletedAppointments(String patientId) => '$apiUrl/get_patient_completed_appointments.php?id_patient=$patientId';
  static String getPatientPendingAcceptedAppointments(String patientId) => '$apiUrl/get_patient_pending_accepted_appointments.php?id_patient=$patientId';

  // Doctor and Nurse Endpoints
  static String searchNearestDoctor = '$apiUrl/search_nearest_doctor.php';
  static String createDoctorRequest = '$apiUrl/create_doctor_request.php';
  static String searchNearestNurse = '$apiUrl/search_nearest_nurse.php';
  static String bookNurseAppointment = '$apiUrl/book_nurse_appointment.php';
  static String createGardeMaladeRequest = '$apiUrl/create_garde_malade_request.php';

  // Services Endpoints
  static String getNurseServices = '$apiUrl/get_nurse_services.php';
  static String get fetchAssistanceRequests => '$apiUrl/fetch_assistance_requests.php';


  // Image and Upload Endpoints
  static String getProfileImageUrl(String? photoPath) {
    return photoPath != null ? '$baseImageUrl/$photoPath' : '';
  }
 static String getServiceImageUrl(int serviceId) {
  // Common image formats including medical imaging formats
  final formats = [
    // Standard web formats
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'tif',
    
    // Medical imaging formats
    'dcm', 'dicom', 'dnp', 'dmp',
    
    // Raw formats
    'raw', 'cr2', 'nef', 'arw',
    
    // Other formats
    'heic', 'heif', 'svg'
  ];
  
  // Create URLs for each possible format
  for (var format in formats) {
    final url = '$baseUploadUrl/services/$serviceId.$format';
    return url;  // Return the first possible URL
  }
  
  // Fallback if no image is found
  return '';
}
}