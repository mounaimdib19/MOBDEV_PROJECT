<?php
// delete_doctor.php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $id_doc = $data['id_doc'];

    $query = "DELETE FROM docteur WHERE id_doc = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_doc);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Doctor deleted successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete doctor']);
    }

    $stmt->close();
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();