<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_doc = $_POST['id_doc'];
    $latitude = $_POST['latitude'];
    $longitude = $_POST['longitude'];

    $sql = "UPDATE docteur SET latitude = ?, longitude = ? WHERE id_doc = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ddi", $latitude, $longitude, $id_doc);
    
    if ($stmt->execute()) {
        $response = [
            'success' => true,
            'message' => 'Location updated successfully'
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Failed to update location'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>