<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Validate input
    if (!isset($_POST['id_doc']) || !isset($_POST['latitude']) || !isset($_POST['longitude'])) {
        echo json_encode([
            'success' => false,
            'message' => 'Missing required fields'
        ]);
        exit;
    }

    $id_doc = $_POST['id_doc'];
    $latitude = $_POST['latitude'];
    $longitude = $_POST['longitude'];

    // Validate coordinates
    if (!is_numeric($latitude) || !is_numeric($longitude) ||
        $latitude < -90 || $latitude > 90 || 
        $longitude < -180 || $longitude > 180) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid coordinates'
        ]);
        exit;
    }

    // Update location with timestamp
    $sql = "UPDATE docteur SET 
            latitude = ?, 
            longitude = ?, 
            last_location_update = CURRENT_TIMESTAMP 
            WHERE id_doc = ?";
            
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ddi", $latitude, $longitude, $id_doc);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Location updated successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update location: ' . $stmt->error
        ]);
    }

    $stmt->close();
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method'
    ]);
}

$conn->close();
?>