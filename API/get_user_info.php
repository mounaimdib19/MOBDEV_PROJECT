<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id_patient = $_GET['id_patient'];

    $sql = "SELECT nom, prenom FROM patient WHERE id_patient = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_patient);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 1) {
        $row = $result->fetch_assoc();
        $response = [
            'success' => true,
            'nom' => $row['nom'],
            'prenom' => $row['prenom']
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