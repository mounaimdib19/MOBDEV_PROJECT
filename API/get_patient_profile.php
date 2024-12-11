<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id_patient = (int)$_GET['id_patient'];
    $sql = "SELECT * FROM patient WHERE id_patient = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_patient);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 1) {
        $patient = $result->fetch_assoc();
        $response = [
            'success' => true,
            'patient' => $patient
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Patient not found'
        ];
    }

    echo json_encode($response);
}

$conn->close();
?>