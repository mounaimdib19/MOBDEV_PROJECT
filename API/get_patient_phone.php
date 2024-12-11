<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

$response = array();

if (isset($_GET['id_patient']) && !empty($_GET['id_patient'])) {
    $id_patient = $_GET['id_patient'];
    
    $query = "SELECT numero_telephone FROM patient WHERE id_patient = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_patient);
    
    if ($stmt->execute()) {
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $response['success'] = true;
            $response['phone_number'] = $row['numero_telephone'];
        } else {
            $response['success'] = false;
            $response['message'] = "Patient not found";
        }
    } else {
        $response['success'] = false;
        $response['message'] = "Database query failed";
    }
    
    $stmt->close();
} else {
    $response['success'] = false;
    $response['message'] = "Invalid patient ID";
}

echo json_encode($response);
$conn->close();
?>