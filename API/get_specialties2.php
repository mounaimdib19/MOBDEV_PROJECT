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
        $sql = "SELECT id_specialite, nom_specialite FROM specialite ORDER BY nom_specialite";
        $result = $conn->query($sql);

        if (!$result) {
            throw new Exception("Query failed: " . $conn->error);
        }

        $specialties = array();
        while ($row = $result->fetch_assoc()) {
            $specialties[] = $row;
        }

        $response['success'] = true;
        $response['specialties'] = $specialties;
    } else {
        throw new Exception("Invalid request method");
    }
} catch (Exception $e) {
    error_log("Error in get_specialties.php: " . $e->getMessage());
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