<?php
include 'db_connection.php';
include 'error_log.php';

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods, Authorization, X-Requested-With");

function logError($message, $data = null) {
    $logMessage = date('Y-m-d H:i:s') . " - $message";
    if ($data !== null) {
        $logMessage .= " - Data: " . json_encode($data);
    }
    error_log($logMessage . PHP_EOL, 3, "error.log");
}

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id_doctor_service = isset($_GET['id_doctor_service']) ? intval($_GET['id_doctor_service']) : 0;

    logError("Received request", $_GET);

    if ($id_doctor_service == 0) {
        logError("Invalid doctor service ID", ['id_doctor_service' => $id_doctor_service]);
        echo json_encode([
            "success" => false,
            "message" => "Invalid doctor service ID."
        ]);
        exit;
    }

    $query = "SELECT st.has_fixed_price, 
                     CASE 
                         WHEN st.has_fixed_price = 0 AND ds.custom_price IS NOT NULL THEN ds.custom_price
                         ELSE st.fixed_price 
                     END AS price
              FROM doctor_services ds
              JOIN service_types st ON ds.id_service_type = st.id_service_type
              WHERE ds.id_doctor_service = ?";

    try {
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $id_doctor_service);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $response = [
                "success" => true,
                "has_fixed_price" => $row['has_fixed_price'] ? true : false,
                "price" => floatval($row['price'])
            ];
            logError("Price fetched successfully", $response);
            echo json_encode($response);
        } else {
            logError("No pricing information found", ['id_doctor_service' => $id_doctor_service]);
            echo json_encode([
                "success" => false,
                "message" => "No pricing information found for this service."
            ]);
        }
    } catch (Exception $e) {
        logError("Database error: " . $e->getMessage(), ['id_doctor_service' => $id_doctor_service]);
        echo json_encode([
            "success" => false,
            "message" => "A database error occurred."
        ]);
    }
} else {
    logError("Invalid request method: " . $_SERVER['REQUEST_METHOD']);
    echo json_encode([
        "success" => false,
        "message" => "Invalid request method."
    ]);
}

$conn->close();
?>