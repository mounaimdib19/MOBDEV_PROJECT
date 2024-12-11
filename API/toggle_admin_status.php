<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_doc = $_POST['id_doc'];
    $status = $_POST['status'];
    $location_permission = isset($_POST['location_permission']) ? $_POST['location_permission'] : 'denied';

    // Validate status
    if ($status !== 'active' && $status !== 'inactive') {
        echo json_encode(['success' => false, 'message' => 'Invalid status']);
        exit;
    }

    // Check location permission when activating status
    if ($status === 'active' && $location_permission !== 'granted') {
        echo json_encode(['success' => false, 'message' => 'Location permission is required to activate status']);
        exit;
    }

    $sql = "UPDATE docteur SET status = ? WHERE id_doc = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $status, $id_doc);
    
    if ($stmt->execute()) {
        $response = [
            'success' => true,
            'message' => 'Status updated successfully',
            'new_status' => $status
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Failed to update status: ' . $conn->error
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>