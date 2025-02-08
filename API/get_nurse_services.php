<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *"); // Add CORS header if needed
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

require_once 'db_connection.php';

$response = array();

try {
    // Check if database connection is successful
    if (!$conn) {
        throw new Exception("Database connection failed: " . mysqli_connect_error());
    }

    // Fetch only active service types
    $query = "SELECT id_service_type, nom, has_fixed_price, fixed_price, picture_url 
          FROM service_types 
          WHERE active = TRUE";

    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        throw new Exception("Query preparation failed: " . $conn->error);
    }

    if (!$stmt->execute()) {
        throw new Exception("Query execution failed: " . $stmt->error);
    }

    $result = $stmt->get_result();
    
    if (!$result) {
        throw new Exception("Failed to get result set: " . $stmt->error);
    }

    $services = array();
    while ($row = $result->fetch_assoc()) {
        // Sanitize and validate data
        $row['id_service_type'] = (string)$row['id_service_type'];
        $row['fixed_price'] = $row['fixed_price'] ? (float)$row['fixed_price'] : null;
        $row['has_fixed_price'] = (bool)$row['has_fixed_price'];
        $services[] = $row;
    }

    $response['success'] = true;
    $response['services'] = $services;
    $response['timestamp'] = time();

} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = "Error: " . $e->getMessage();
    $response['error_code'] = $e->getCode();
} finally {
    if (isset($stmt)) {
        $stmt->close();
    }
    if (isset($conn)) {
        $conn->close();
    }
}

echo json_encode($response);
?>