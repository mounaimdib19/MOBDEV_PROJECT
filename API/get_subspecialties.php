<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

ob_start();

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
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
    if ($_SERVER['REQUEST_METHOD'] == 'GET') {
        $specialite_parent = isset($_GET['specialite_parent']) ? intval($_GET['specialite_parent']) : null;
        
        $sql = "SELECT ss.id_sous_specialite, ss.nom_sous_specialite, ss.specialite_parent, 
                       s.nom_specialite as parent_specialite_nom
                FROM sous_specialite ss
                JOIN specialite s ON ss.specialite_parent = s.id_specialite";
        
        if ($specialite_parent !== null) {
            $sql .= " WHERE ss.specialite_parent = ?";
        }
        
        $sql .= " ORDER BY s.nom_specialite, ss.nom_sous_specialite";
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        if ($specialite_parent !== null) {
            $stmt->bind_param("i", $specialite_parent);
        }

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $result = $stmt->get_result();
        $subspecialties = array();
        
        while ($row = $result->fetch_assoc()) {
            $subspecialties[] = $row;
        }

        $response['success'] = true;
        $response['subspecialties'] = $subspecialties;
        
        $stmt->close();
    } else {
        throw new Exception("Invalid request method");
    }
} catch (Exception $e) {
    error_log("Error in get_subspecialties.php: " . $e->getMessage());
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