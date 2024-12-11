<?php
// admin_login.php

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Allow cross-origin requests (adjust as needed for security)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Database connection details
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "mabase";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(array("success" => false, "message" => "Connection failed: " . $conn->connect_error)));
}

// Check if the request method is POST
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get email and password from POST data
    $email = $_POST['adresse_email'];
    $password = $_POST['mot_de_passe'];

    // Prepare SQL statement to prevent SQL injection
    $stmt = $conn->prepare("SELECT id_admin, type FROM administrateur WHERE adresse_email = ? AND mot_de_passe = ?");
    $stmt->bind_param("ss", $email, $password);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Login successful
        $row = $result->fetch_assoc();
        echo json_encode(array("success" => true, "message" => "Login successful", "id_admin" => $row['id_admin'], "type" => $row['type']));
    } else {
        // Login failed
        echo json_encode(array("success" => false, "message" => "Invalid email or password"));
    }

    $stmt->close();
} else {
    // If not a POST request
    echo json_encode(array("success" => false, "message" => "Invalid request method"));
}

$conn->close();
?>