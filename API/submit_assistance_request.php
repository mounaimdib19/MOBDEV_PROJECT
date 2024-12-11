<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['phone_number']) && !empty($_POST['phone_number'])) {
        $phone_number = $_POST['phone_number'];
        
        // Insert the request with pending status
        $insert_query = "INSERT INTO assistance_requests (numero_telephone, status) VALUES (?, 'pending')";
        $stmt = $conn->prepare($insert_query);
        $stmt->bind_param("s", $phone_number);
        
        if ($stmt->execute()) {
            $request_id = $stmt->insert_id;
            $response['success'] = true;
            $response['message'] = "Assistance request submitted successfully.";
            $response['request_id'] = $request_id;
        } else {
            $response['success'] = false;
            $response['message'] = "Failed to submit the assistance request.";
        }
        
        $stmt->close();
    } else {
        $response['success'] = false;
        $response['message'] = "Phone number is required.";
    }
} else {
    $response['success'] = false;
    $response['message'] = "Invalid request method.";
}

echo json_encode($response);
$conn->close();
?>