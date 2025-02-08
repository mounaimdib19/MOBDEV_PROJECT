<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Include database connection
require_once 'db_connection.php';

// Allow cross-origin requests (adjust as needed for security)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Check if the request method is POST
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get email and password from POST data
    $email = $_POST['adresse_email'];
    $password = $_POST['mot_de_passe'];

    // Prepare SQL statement to prevent SQL injection
    $stmt = $conn->prepare("SELECT id_admin, type, mot_de_passe FROM administrateur WHERE adresse_email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        // Verify the password against the stored hash
        if (password_verify($password, $row['mot_de_passe'])) {
            // Login successful
            echo json_encode(array(
                "success" => true, 
                "message" => "Login successful", 
                "id_admin" => $row['id_admin'], 
                "type" => $row['type']
            ));
        } else {
            // Password doesn't match
            echo json_encode(array(
                "success" => false, 
                "message" => "Invalid email or password"
            ));
        }
    } else {
        // Email not found
        echo json_encode(array(
            "success" => false, 
            "message" => "Invalid email or password"
        ));
    }

    $stmt->close();
} else {
    // If not a POST request
    echo json_encode(array(
        "success" => false, 
        "message" => "Invalid request method"
    ));
}

$conn->close();
?>