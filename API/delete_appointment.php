<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_rendez_vous = $_POST['id_rendez_vous'];

    $sql = "UPDATE rendez_vous SET statut = 'annule' WHERE id_rendez_vous = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_rendez_vous);

    if ($stmt->execute()) {
        $response = ['success' => true, 'message' => 'Appointment deleted successfully'];
    } else {
        $response = ['success' => false, 'message' => 'Failed to delete appointment'];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>