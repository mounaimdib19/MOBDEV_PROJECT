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
        
        $nom_sous_specialite = $_POST['nom_sous_specialite'] ?? '';
        $specialite_parent = $_POST['specialite_parent'] ?? null;
        
        if (empty($nom_sous_specialite) || empty($specialite_parent)) {
            throw new Exception("Sub-specialty name and parent specialty are required");
        }

        // Verify parent specialty exists
        $check_sql = "SELECT id_specialite FROM specialite WHERE id_specialite = ?";
        $check_stmt = $conn->prepare($check_sql);
        if (!$check_stmt) {
            throw new Exception("Prepare check failed: " . $conn->error);
        }

        $check_stmt->bind_param("i", $specialite_parent);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        
        if ($check_result->num_rows === 0) {
            throw new Exception("Parent specialty does not exist");
        }
        $check_stmt->close();

        // Insert sub-specialty
        $sql = "INSERT INTO sous_specialite (nom_sous_specialite, specialite_parent) VALUES (?, ?)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $bind_result = $stmt->bind_param("si", $nom_sous_specialite, $specialite_parent);
        if (!$bind_result) {
            throw new Exception("Binding parameters failed: " . $stmt->error);
        }

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $subspecialty_id = $conn->insert_id;

        $response['success'] = true;
        $response['message'] = "Sub-specialty added successfully";
        $response['id_sous_specialite'] = $subspecialty_id;
        
        $stmt->close();
    } else {
        throw new Exception("Invalid request method");
    }
} catch (Exception $e) {
    error_log("Error in add_subspecialty.php: " . $e->getMessage());
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