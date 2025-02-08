<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include "db_connection.php";

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

try {
    // Validate required fields
    $required_fields = ['nom', 'prenom', 'adresse_email', 'mot_de_passe', 'type', 'statut'];
    foreach ($required_fields as $field) {
        if (!isset($_POST[$field]) || empty($_POST[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }

    $nom = $_POST['nom'];
    $prenom = $_POST['prenom'];
    $email = $_POST['adresse_email'];
    $password = password_hash($_POST['mot_de_passe'], PASSWORD_DEFAULT);
    $type = $_POST['type'];
    $statut = $_POST['statut'];

    $sql = "INSERT INTO administrateur (nom, prenom, adresse_email, mot_de_passe, type, statut) 
            VALUES (?, ?, ?, ?, ?, ?)";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssssss", $nom, $prenom, $email, $password, $type, $statut);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true, 
            "message" => "Administrator added successfully"
        ]);
    } else {
        throw new Exception($stmt->error);
    }
} catch (Exception $e) {
    error_log("Error in add_administrator.php: " . $e->getMessage());
    echo json_encode([
        "success" => false, 
        "message" => "Error: " . $e->getMessage()
    ]);
}

$stmt->close();
$conn->close();
?>