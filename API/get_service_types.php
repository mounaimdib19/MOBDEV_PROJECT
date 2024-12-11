<?php
// Error handling
function exception_error_handler($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
}
set_error_handler("exception_error_handler");

// Disable error reporting
error_reporting(0);

// Start output buffering
ob_start();

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

try {
    require_once 'db_connection.php';

    if ($_SERVER['REQUEST_METHOD'] == 'GET') {
        $sql = "SELECT id_service_type, nom, has_fixed_price, fixed_price FROM service_types";
        $result = $conn->query($sql);

        if ($result === false) {
            throw new Exception("Query failed: " . $conn->error);
        }

        if ($result->num_rows > 0) {
            $services = array();
            while($row = $result->fetch_assoc()) {
                $services[] = $row;
            }
            $response = [
                'success' => true,
                'service_types' => $services
            ];
        } else {
            $response = [
                'success' => false,
                'message' => 'No services found'
            ];
        }
    } else {
        $response = ['success' => false, 'message' => 'Invalid request method'];
    }
} catch (Exception $e) {
    $response = [
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ];
}

// Clear the output buffer
ob_end_clean();

// Output the JSON response
echo json_encode($response);

if (isset($conn)) {
    $conn->close();
}
?>