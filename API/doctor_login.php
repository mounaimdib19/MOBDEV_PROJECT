<?php
require_once 'db_connection.php';  // Include the database connection

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $email = $_POST['email'];
    $password = $_POST['password'];

    $stmt = $conn->prepare("SELECT id_doc, nom, prenom, mot_de_passe FROM docteur WHERE adresse_email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 1) {
        $row = $result->fetch_assoc();
        if (password_verify($password, $row['mot_de_passe'])) {  // Verify hashed password
            echo json_encode([
                'success' => true,
                'id_doc' => $row['id_doc'],
                'name' => $row['nom'] . ' ' . $row['prenom']
            ]);
        } else {
            echo json_encode([
                'success' => false, 
                'message' => 'Invalid email or password'
            ]);
        }
    } else {
        echo json_encode([
            'success' => false, 
            'message' => 'Invalid email or password'
        ]);
    }

    $stmt->close();
} else {
    echo json_encode([
        'success' => false, 
        'message' => 'Invalid request method'
    ]);
}

$conn->close();
?>