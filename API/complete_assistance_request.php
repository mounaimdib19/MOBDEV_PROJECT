<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['id_request']) && !empty($_POST['id_request']) &&
        isset($_POST['id_doc']) && !empty($_POST['id_doc'])) {
        
        $id_request = $_POST['id_request'];
        $id_doc = $_POST['id_doc'];
        
        // Start transaction
        $conn->begin_transaction();
        
        try {
            // Update assistance_requests table
            $update_query = "UPDATE assistance_requests SET statut = 'complete' WHERE id_request = ?";
            $stmt = $conn->prepare($update_query);
            $stmt->bind_param("i", $id_request);
            $stmt->execute();
            
            // Check if the doctor is assigned to this request
            $check_query = "SELECT * FROM doctor_assignments WHERE id_request = ? AND id_doc = ?";
            $check_stmt = $conn->prepare($check_query);
            $check_stmt->bind_param("ii", $id_request, $id_doc);
            $check_stmt->execute();
            $result = $check_stmt->get_result();
            
            if ($result->num_rows === 0) {
                // If not assigned, create an assignment
                $assign_query = "INSERT INTO doctor_assignments (id_request, id_doc) VALUES (?, ?)";
                $assign_stmt = $conn->prepare($assign_query);
                $assign_stmt->bind_param("ii", $id_request, $id_doc);
                $assign_stmt->execute();
            }
            
            // Commit transaction
            $conn->commit();
            
            $response['success'] = true;
            $response['message'] = "Assistance request completed successfully.";
        } catch (Exception $e) {
            // Rollback transaction on error
            $conn->rollback();
            $response['success'] = false;
            $response['message'] = "Error completing assistance request: " . $e->getMessage();
        }
        
        $stmt->close();
        if (isset($check_stmt)) $check_stmt->close();
        if (isset($assign_stmt)) $assign_stmt->close();
    } else {
        $response['success'] = false;
        $response['message'] = "Request ID and Doctor ID are required.";
    }
} else {
    $response['success'] = false;
    $response['message'] = "Invalid request method.";
}

echo json_encode($response);
$conn->close();
?>