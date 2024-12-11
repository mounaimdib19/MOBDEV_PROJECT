<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id_doc = (int)$_GET['id_doc'];
    $sql = "SELECT id_doc, nom, prenom, adresse, id_wilaya, id_commune, adresse_email, numero_telephone, Latitude, longitude, status FROM docteur WHERE id_doc = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_doc);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 1) {
        $doctor = $result->fetch_assoc();
        $response = [
            'success' => true,
            'doctor' => $doctor
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Doctor not found'
        ];
    }

    echo json_encode($response);
}

$conn->close();
?>