<?php
// Error handling
function exception_error_handler($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
}
set_error_handler("exception_error_handler");

error_reporting(0);
ob_start();

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

try {
    require_once 'db_connection.php';

    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['id_service_type'])) {
            throw new Exception("Service ID is required");
        }

        $serviceId = $data['id_service_type'];
        
        // First get current status
        $checkSql = "SELECT active FROM service_types WHERE id_service_type = ?";
        $checkStmt = $conn->prepare($checkSql);
        $checkStmt->bind_param("i", $serviceId);
        $checkStmt->execute();
        $result = $checkStmt->get_result();
        $currentStatus = $result->fetch_assoc()['active'];
        
        // Toggle the status
        $newStatus = $currentStatus ? 0 : 1;
        
        $sql = "UPDATE service_types SET active = ? WHERE id_service_type = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $newStatus, $serviceId);
        
        if ($stmt->execute()) {
            $response = [
                'success' => true,
                'message' => 'Service status updated successfully',
                'new_status' => (bool)$newStatus
            ];
        } else {
            throw new Exception("Failed to update service status");
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

ob_end_clean();
echo json_encode($response);

if (isset($conn)) {
    $conn->close();
}
?>