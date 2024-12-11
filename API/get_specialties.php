<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $sql = "SELECT id_specialite, nom_specialite FROM specialite ORDER BY nom_specialite";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $specialites = array();
        while($row = $result->fetch_assoc()) {
            $specialites[] = $row;
        }
        $response = [
            'success' => true,
            'specialites' => $specialites
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'No specialties found'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>