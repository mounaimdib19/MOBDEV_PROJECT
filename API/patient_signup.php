<?php
include 'db_connection.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $numero_telephone = $_POST['numero_telephone'];
    
    // First check if phone number already exists
    $check_sql = "SELECT numero_telephone FROM patient WHERE numero_telephone = ?";
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bind_param("s", $numero_telephone);
    $check_stmt->execute();
    $result = $check_stmt->get_result();
    
    if ($result->num_rows > 0) {
        $response = ['success' => false, 'message' => 'Phone number already exists'];
        echo json_encode($response);
        exit;
    }
    
    // If phone doesn't exist, proceed with registration
    $sql = "INSERT INTO patient (numero_telephone) VALUES (?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $numero_telephone);
    
    if ($stmt->execute()) {
        $response = ['success' => true, 'message' => 'Patient registered successfully'];
    } else {
        $response = ['success' => false, 'message' => 'Registration failed'];
    }
    
    echo json_encode($response);
}
?>