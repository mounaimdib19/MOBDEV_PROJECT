<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', '1');

// Start session to manage authentication
session_start();

// CORS headers
header("Access-Control-Allow-Origin: *"); // Allow requests from any origin
header("Access-Control-Allow-Methods: GET, POST, OPTIONS"); // Allowed HTTP methods
header("Access-Control-Allow-Headers: Content-Type, Authorization"); // Allowed headers
header("Content-Type: application/json"); // JSON response

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

function sendJsonResponse($success, $message, $data = null) {
    $response = ['success' => $success, 'message' => $message];
    if ($data !== null) {
        $response['data'] = $data;
    }
    echo json_encode($response);
    exit;
}

try {
    include "db_connection.php";

    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Check if admin is logged in (you'll need to implement proper authentication)
        $id_admin = $_SESSION['id_admin'] ?? $_GET['id_admin'] ?? null;
        if (!$id_admin) {
            sendJsonResponse(false, 'Not authenticated or missing id_admin');
        }

        $stmt = $conn->prepare("SELECT nom, prenom, adresse_email, mot_de_passe FROM administrateur WHERE id_admin = ?");
        $stmt->bind_param("i", $id_admin);
        $stmt->execute();
        $result = $stmt->get_result();
        $admin_data = $result->fetch_assoc();

        if ($admin_data) {
            sendJsonResponse(true, 'Admin data retrieved successfully', $admin_data);
        } else {
            sendJsonResponse(false, 'Admin not found');
        }
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Parse JSON input for POST requests
        $json_input = file_get_contents('php://input');
        $input_data = json_decode($json_input, true);

        // Automatically get admin ID from session or authentication
        $id_admin = $_SESSION['id_admin'] ?? null;
        if (!$id_admin) {
            sendJsonResponse(false, 'Not authenticated');
        }

        // Extract other fields from input or existing data
        $nom = $input_data['nom'] ?? '';
        $prenom = $input_data['prenom'] ?? '';
        $adresse_email = $input_data['adresse_email'] ?? '';
        $mot_de_passe = $input_data['mot_de_passe'] ?? '';

        $sql = "UPDATE administrateur SET nom = ?, prenom = ?, adresse_email = ?, mot_de_passe = ? WHERE id_admin = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            sendJsonResponse(false, 'Failed to prepare statement: ' . $conn->error);
        }

        $stmt->bind_param("ssssi", $nom, $prenom, $adresse_email, $mot_de_passe, $id_admin);

        if ($stmt->execute()) {
            sendJsonResponse(true, 'Profile updated successfully', [
                'nom' => $nom,
                'prenom' => $prenom,
                'adresse_email' => $adresse_email,
                'mot_de_passe' => $mot_de_passe
            ]);
        } else {
            sendJsonResponse(false, 'Failed to update profile: ' . $stmt->error);
        }
    } else {
        sendJsonResponse(false, 'Invalid request method');
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    error_log('Exception in update_admin_profile.php: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
    sendJsonResponse(false, 'An error occurred: ' . $e->getMessage());
}
?>