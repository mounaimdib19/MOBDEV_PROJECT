class Environment {
  static String apiUrl = 'http://10.80.10.234/siteweb22/API';
  static String baseImageUrl = 'http://10.80.10.234/siteweb22/images';

  // Administrator endpoints
  static String addadmin() {
    return '$apiUrl/add_administrator.php';
  }
  
  static String getadmininfo(int adminId) => '$apiUrl/get_admin_info.php?id_admin=$adminId';
  
  static String toggleadminstatus() => '$apiUrl/toggle_admin_status.php';
  
  static String adminlogin() => '$apiUrl/admin_login.php';
  
  static String updateadminprofile() => '$apiUrl/update_admin_profile.php';
  
  static String getadminprofile(int adminId) => '$apiUrl/update_admin_profile.php?id_admin=$adminId';
  
  static String getalladministrators() => '$apiUrl/get_all_administrators.php';
  
  static String deleteadministrator() => '$apiUrl/delete_administrator.php';

  static String getProfileImageUrl(String? photoPath) {
    return photoPath != null ? '$baseImageUrl/$photoPath' : '';
  }

  // Doctor endpoints
  static String adddoctor() => '$apiUrl/add_doctor_with_services.php';
  
  static String getdoctors(String type) => '$apiUrl/get_doctors.php?type=$type';
  
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

  // Location endpoints
  static String getwilayas() => '$apiUrl/get_wilayas.php';
  
  static String getcommunes() => '$apiUrl/get_communes.php';

  // Specialty endpoints
  static String getspecialties() => '$apiUrl/get_specialties.php';
  
  static String getsousspecialties() => '$apiUrl/get_sous_specialties.php';

  // Generic delete endpoint
  static String deleterecord() => '$apiUrl/delete_record.php';
}