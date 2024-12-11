<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_rendez_vous = $_POST['id_rendez_vous'];
    $id_doc = $_POST['id_doc'];

    // Start transaction
    $conn->begin_transaction();

    try {
        // Update appointment status
        $sql = "UPDATE rendez_vous SET statut = 'accepte' WHERE id_rendez_vous = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id_rendez_vous);
        $stmt->execute();

        // Update doctor status
        $sql = "UPDATE docteur SET status = 'inactive' WHERE id_doc = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id_doc);
        $stmt->execute();

        // Commit transaction
        $conn->commit();

        $response = ['success' => true, 'message' => 'Appointment accepted and doctor status updated'];
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        $response = ['success' => false, 'message' => 'Failed to accept appointment: ' . $e->getMessage()];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>