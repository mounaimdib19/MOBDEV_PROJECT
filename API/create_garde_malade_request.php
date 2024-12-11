<?php
// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers for CORS and content type
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Log incoming request
file_put_contents('garde_malade_request_log.txt', 
    date('Y-m-d H:i:s') . " - Incoming Request\n" . 
    "POST Data: " . print_r($_POST, true) . 
    "SERVER Data: " . print_r($_SERVER, true) . 
    "\n---\n", 
    FILE_APPEND
);

include 'db_connection.php';

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    $error_log = date('Y-m-d H:i:s') . " - Connection Error: " . $conn->connect_error . "\n";
    file_put_contents('garde_malade_request_error_log.txt', $error_log, FILE_APPEND);
    die(json_encode(["success" => false, "message" => "Connection failed: " . $conn->connect_error]));
}

// Validate incoming data
if (!isset($_POST['id_patient']) || 
    !isset($_POST['description']) || 
    !isset($_POST['patient_latitude']) || 
    !isset($_POST['patient_longitude'])) {
    
    $missing_params = [];
    if (!isset($_POST['id_patient'])) $missing_params[] = 'id_patient';
    if (!isset($_POST['description'])) $missing_params[] = 'description';
    if (!isset($_POST['patient_latitude'])) $missing_params[] = 'patient_latitude';
    if (!isset($_POST['patient_longitude'])) $missing_params[] = 'patient_longitude';
    
    $error_log = date('Y-m-d H:i:s') . " - Missing Parameters: " . implode(', ', $missing_params) . "\n";
    file_put_contents('garde_malade_request_error_log.txt', $error_log, FILE_APPEND);
    
    echo json_encode([
        "success" => false, 
        "message" => "Missing parameters: " . implode(', ', $missing_params),
        "received_data" => $_POST
    ]);
    exit;
}

// Get parameters
$id_patient = $_POST['id_patient'];
$description = $_POST['description'];
$patient_latitude = $_POST['patient_latitude'];
$patient_longitude = $_POST['patient_longitude'];

// Start transaction
$conn->begin_transaction();

try {
    // Insert garde malade request
    $sql_request = "INSERT INTO garde_malade_requests 
                    (id_patient, description, patient_latitude, patient_longitude, status) 
                    VALUES (?, ?, ?, ?, 'pending')";
    
    $stmt = $conn->prepare($sql_request);
    $stmt->bind_param("isdd", $id_patient, $description, $patient_latitude, $patient_longitude);
    $stmt->execute();

    // Check for SQL errors
    if ($stmt->error) {
        throw new Exception("SQL Execution Error: " . $stmt->error);
    }

    // Get the ID of the newly inserted request
    $request_id = $conn->insert_id;

    // Commit transaction
    $conn->commit();

    echo json_encode([
        "success" => true, 
        "message" => "Garde Malade request created successfully", 
        "request_id" => $request_id
    ]);

} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    
    // Log the full error
    $error_log = date('Y-m-d H:i:s') . " - Exception: " . $e->getMessage() . 
                 "\nTrace: " . $e->getTraceAsString() . "\n";
    file_put_contents('garde_malade_request_error_log.txt', $error_log, FILE_APPEND);
    
    echo json_encode([
        "success" => false, 
        "message" => "Error creating garde malade request: " . $e->getMessage()
    ]);
}

$conn->close();
?>