<?php
// Add CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Max-Age: 3600");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

require_once 'db_connection.php';

$response = array();

try {
    // Validate input
    $id_patient = isset($_POST['id_patient']) ? intval($_POST['id_patient']) : 0;
    $id_service_type = isset($_POST['id_service_type']) ? intval($_POST['id_service_type']) : 0;
    $patient_latitude = isset($_POST['patient_latitude']) ? floatval($_POST['patient_latitude']) : 0.0;
    $patient_longitude = isset($_POST['patient_longitude']) ? floatval($_POST['patient_longitude']) : 0.0;
    $requested_time = isset($_POST['requested_time']) ? $_POST['requested_time'] : date('Y-m-d H:i:s');

    if ($id_patient <= 0 || $id_service_type <= 0) {
        throw new Exception("Invalid patient or service type");
    }

    // Start transaction
    $conn->begin_transaction();

    // Insert nurse assistance request
    $query = "INSERT INTO nurse_assistance_requests 
              (id_patient, patient_latitude, patient_longitude, requested_time, id_service_type) 
              VALUES (?, ?, ?, ?, ?)";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("iddsi", $id_patient, $patient_latitude, $patient_longitude, $requested_time, $id_service_type);
    $stmt->execute();

    $request_id = $conn->insert_id;

    // Attempt to find and assign a nearby nurse
    $find_nurse_query = "SELECT id_doc FROM docteur 
                         WHERE est_infirmier = TRUE 
                         AND status = 'active' 
                         ORDER BY (
                           6371 * ACOS(
                             COS(RADIANS(?)) * COS(RADIANS(Latitude)) * COS(RADIANS(longitude) - RADIANS(?)) +
                             SIN(RADIANS(?)) * SIN(RADIANS(Latitude))
                           )
                         ) ASC 
                         LIMIT 1";

    $find_nurse_stmt = $conn->prepare($find_nurse_query);
    $find_nurse_stmt->bind_param("ddd", $patient_latitude, $patient_longitude, $patient_latitude);
    $find_nurse_stmt->execute();
    $find_nurse_result = $find_nurse_stmt->get_result();

    if ($find_nurse_result->num_rows > 0) {
        $nurse = $find_nurse_result->fetch_assoc();
        
        // Insert nurse assignment
        $assign_query = "INSERT INTO nurse_assignment 
                         (id_request, id_nurse, assignment_date) 
                         VALUES (?, ?, NOW())";
        
        $assign_stmt = $conn->prepare($assign_query);
        $assign_stmt->bind_param("ii", $request_id, $nurse['id_doc']);
        $assign_stmt->execute();

        // Update request status to assigned
        $update_status_query = "UPDATE nurse_assistance_requests 
                                SET status = 'assigned' 
                                WHERE id_request = ?";
        $update_status_stmt = $conn->prepare($update_status_query);
        $update_status_stmt->bind_param("i", $request_id);
        $update_status_stmt->execute();
    }

    // Commit transaction
    $conn->commit();

    $response['success'] = true;
    $response['message'] = "Nurse assistance request created successfully";
    $response['request_id'] = $request_id;

} catch (Exception $e) {
    // Rollback transaction
    $conn->rollback();

    $response['success'] = false;
    $response['message'] = "Error creating nurse assistance request: " . $e->getMessage();
}

echo json_encode($response);
$conn->close();
?>