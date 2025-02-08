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
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

try {
    require_once 'db_connection.php';

    if ($_SERVER['REQUEST_METHOD'] == 'GET') {
        $search = isset($_GET['search']) ? $_GET['search'] : '';
        
        $sql = "SELECT id_service_type, nom, has_fixed_price, fixed_price, active 
                FROM service_types
                WHERE nom LIKE ?";
        
        $stmt = $conn->prepare($sql);
        $searchTerm = "%$search%";
        $stmt->bind_param("s", $searchTerm);
        $stmt->execute();
        $result = $stmt->get_result();

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

ob_end_clean();
echo json_encode($response);

if (isset($conn)) {
    $conn->close();
}
?>