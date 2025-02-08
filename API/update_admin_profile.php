<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

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

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $json_input = file_get_contents('php://input');
        $input_data = json_decode($json_input, true);

        $admin_id = $input_data['idAdmin'];
        $nom = $input_data['nom'] ?? '';
        $prenom = $input_data['prenom'] ?? '';
        $adresse_email = $input_data['adresse_email'] ?? '';
        $new_password = $input_data['mot_de_passe'] ?? '';

        // First get the existing password
        $stmt = $conn->prepare("SELECT mot_de_passe FROM administrateur WHERE id_admin = ?");
        $stmt->bind_param("i", $admin_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $admin = $result->fetch_assoc();
        $stmt->close();

        // If new password is empty, keep the old password
        // If new password is provided, hash it
        $final_password = empty($new_password) ? $admin['mot_de_passe'] : password_hash($new_password, PASSWORD_DEFAULT);

        $sql = "UPDATE administrateur 
                SET nom = ?, prenom = ?, adresse_email = ?, mot_de_passe = ? 
                WHERE id_admin = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssssi", $nom, $prenom, $adresse_email, $final_password, $admin_id);

        if ($stmt->execute()) {
            sendJsonResponse(true, 'Profile updated successfully', [
                'nom' => $nom,
                'prenom' => $prenom,
                'adresse_email' => $adresse_email
            ]);
        } else {
            sendJsonResponse(false, 'Failed to update profile: ' . $stmt->error);
        }
        
        $stmt->close();
    } else {
        sendJsonResponse(false, 'Invalid request method');
    }

    $conn->close();
} catch (Exception $e) {
    error_log('Exception in update_admin_profile.php: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
    sendJsonResponse(false, 'An error occurred: ' . $e->getMessage());
}