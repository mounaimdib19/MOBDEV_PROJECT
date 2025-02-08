<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

ob_start();

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'db_connection.php';

$response = array();

try {
    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        error_log("Received POST data: " . print_r($_POST, true));
        
        $nom_specialite = $_POST['nom_specialite'] ?? '';
        
        if (empty($nom_specialite)) {
            throw new Exception("Specialty name is required");
        }

        $sql = "INSERT INTO specialite (nom_specialite) VALUES (?)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $bind_result = $stmt->bind_param("s", $nom_specialite);
        if (!$bind_result) {
            throw new Exception("Binding parameters failed: " . $stmt->error);
        }

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $specialty_id = $conn->insert_id;

        $response['success'] = true;
        $response['message'] = "Specialty added successfully";
        $response['id_specialite'] = $specialty_id;
        
        $stmt->close();
    } else {
        throw new Exception("Invalid request method");
    }
} catch (Exception $e) {
    error_log("Error in add_specialty.php: " . $e->getMessage());
    $response['success'] = false;
    $response['message'] = "An error occurred: " . $e->getMessage();
}

$output = ob_get_clean();
if (!empty($output)) {
    error_log("Unexpected output before JSON: " . $output);
}

echo json_encode($response);

$conn->close();
?>