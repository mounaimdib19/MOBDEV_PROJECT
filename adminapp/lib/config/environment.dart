class Environment {
  static String apiUrl = 'https://emassaha.com/API';
  static String baseImageUrl = 'https://emassaha.com/images';

  // Administrator endpoints
  static String addadmin() {
    return '$apiUrl/add_administrator.php';
  }
  static String completeAppointment() => '$apiUrl/admin_complete_appointment.php';
  static String getadmininfo(int adminId) => '$apiUrl/get_admin_info.php?id_admin=$adminId';
  
  static String toggleadminstatus() => '$apiUrl/toggle_admin_status.php';
  
  static String adminlogin() => '$apiUrl/admin_login.php';
  
  static String getadminprofile(int id) => '$apiUrl/get_admin_profile.php?id_admin=$id';
static String updateadminprofile() => '$apiUrl/update_admin_profile.php';
  
  static String searchNearbyDoctors({
    required int requestId,
    required double patientLat,
    required double patientLon,
  }) => '$apiUrl/search_nearby_doctors.php?requestId=$requestId&patientLat=$patientLat&patientLon=$patientLon';

  static String assignDoctor() => '$apiUrl/assign_doctor_app.php';

  static String searchNearbyGardeMalades({
    required int requestId,
    required double patientLat,
    required double patientLon,
  }) => '$apiUrl/search_nearby_gm.php?requestId=$requestId&patientLat=$patientLat&patientLon=$patientLon';
  
  static String assignGardeMalade() => '$apiUrl/assign_gm.php';

  static String getalladministrators() => '$apiUrl/get_all_administrators.php';
  
  static String deleteadministrator() => '$apiUrl/delete_administrator.php';

  static String getProfileImageUrl(String? photoPath) {
    return photoPath != null ? '$baseImageUrl/$photoPath' : '';
  }

  static String searchNearbyNurses({
    required int requestId, 
    required double patientLat, 
    required double patientLon,
    required int serviceTypeId,
  }) {
    return '$apiUrl/search_nearby_nurses.php?requestId=$requestId&patientLat=$patientLat&patientLon=$patientLon&serviceTypeId=$serviceTypeId';
  }

  static String assignNurse() {
    return '$apiUrl/assign_nurse.php';
  }

  // Doctor endpoints
  static String adddoctor() => '$apiUrl/add_doctor_with_services.php';
  
  static String getdoctors(String type) => '$apiUrl/get_doctors.php?type=$type';

  static String getdoctordetails(int doctorId) => '$apiUrl/get_doctor_details.php?id_doc=$doctorId';
  
  static String getdoctorappointments(String doctorId) => '$apiUrl/get_admin_doctor_appointments.php?id_doc=$doctorId';

    static String bandoctor() => '$apiUrl/ban_doctor.php';

  static String updateAdminFCMToken = '$apiUrl/update_admin_fcm_token.php';
  static String deactivateAdminToken = '$apiUrl/deactivate_admin_fcm_token.php';
  // Updated doctor endpoints for edit screen
  static String updatedoctor() => '$apiUrl/update_doctor_with_services.php';
  
  static String deletedoctor() => '$apiUrl/delete_doctor.php';

  // Patient endpoints
  static String addpatient() => '$apiUrl/add_patient.php';
  
  static String getpatients() => '$apiUrl/get_patients.php';
  
  static String deletepatient() => '$apiUrl/delete_patient.php';

  static String viewAssistants() => '$apiUrl/view_assistants.php';

  // Service endpoints
  static String addservice() => '$apiUrl/add_service.php';
  
  static String deleteservice() => '$apiUrl/delete_service.php';
  
  static String updateservice() => '$apiUrl/update_service.php';
  
  static String getservicetypes() => '$apiUrl/get_service_types.php';

  static String toggleservicestatus() => '$apiUrl/toggle_service_status.php';
  
  static String viewRequests({
    String type = 'all',
    String status = 'all',
    String search = '',
  }) => '$apiUrl/view_requests.php?type=$type&status=$status&search=$search';

  static String viewAppointments({
    String status = 'accepte',
  }) => '$apiUrl/view_appointments.php?status=$status';

  // Location endpoints
  static String getwilayas() => '$apiUrl/get_wilayas.php';
  
  static String getcommunes() => '$apiUrl/get_communes.php';

  // Specialty endpoints
  static String getspecialties() => '$apiUrl/get_specialties.php';
  static String getspecialties2() => '$apiUrl/get_specialties2.php';


  static String getsubspecialties([int? specialtyParent]) {
    String baseUrl = '$apiUrl/get_subspecialties.php';
    return specialtyParent != null ? '$baseUrl?specialite_parent=$specialtyParent' : baseUrl;
  }
  static String addspecialty() => '$apiUrl/add_specialty.php';
  static String addsubspecialty() => '$apiUrl/add_subspecialty.php';
  
  static String getsousspecialties() => '$apiUrl/get_sous_specialties.php';

  // Generic delete endpoint
  static String deleterecord() => '$apiUrl/delete_record.php';
}