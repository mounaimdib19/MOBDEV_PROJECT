<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id_doc = $_GET['id_doc'];

    $sql = "SELECT nom, prenom, status, assistant FROM docteur WHERE id_doc = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_doc);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows == 1) {
        $row = $result->fetch_assoc();
        $response = [
            'success' => true,
            'nom' => $row['nom'],
            'prenom' => $row['prenom'],
            'status' => $row['status'],
            'assistant' => $row['assistant'] == 1 // Convert to boolean
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Doctor not found'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>