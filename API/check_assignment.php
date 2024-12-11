<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

$response = array('success' => false, 'assigned' => false);

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['request_id'])) {
    $request_id = intval($_GET['request_id']);
    
    // Check if request exists and is already assigned
    $check_query = "SELECT status FROM assistance_requests WHERE id_request = ?";
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("i", $request_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        if ($row['status'] === 'pending') {
            // Try to find and assign an available assistant
            $conn->begin_transaction();
            
            try {
                // Find available assistant
                $find_assistant = "SELECT id_doc FROM docteur 
                                 WHERE assistant = TRUE 
                                 AND status = 'active' 
                                 ORDER BY RAND() 
                                 LIMIT 1 
                                 FOR UPDATE";
                                 
                $assistant_result = $conn->query($find_assistant);
                
                if ($assistant_result->num_rows > 0) {
                    $assistant = $assistant_result->fetch_assoc();
                    $assistant_id = $assistant['id_doc'];
                    
                    // Update assistant status to inactive
                    $update_assistant = "UPDATE docteur SET status = 'inactive' WHERE id_doc = ?";
                    $update_stmt = $conn->prepare($update_assistant);
                    $update_stmt->bind_param("i", $assistant_id);
                    $update_stmt->execute();
                    
                    // Create assignment
                    $assign_query = "INSERT INTO assistant_assignment (id_request, id_assistant) VALUES (?, ?)";
                    $assign_stmt = $conn->prepare($assign_query);
                    $assign_stmt->bind_param("ii", $request_id, $assistant_id);
                    $assign_stmt->execute();
                    
                    // Update request status
                    $update_request = "UPDATE assistance_requests SET status = 'assigned' WHERE id_request = ?";
                    $update_req_stmt = $conn->prepare($update_request);
                    $update_req_stmt->bind_param("i", $request_id);
                    $update_req_stmt->execute();
                    
                    $conn->commit();
                    
                    $response['success'] = true;
                    $response['assigned'] = true;
                } else {
                    $conn->commit();
                    $response['success'] = true;
                    $response['assigned'] = false;
                }
            } catch (Exception $e) {
                $conn->rollback();
                $response['success'] = false;
                $response['message'] = "Error during assignment: " . $e->getMessage();
            }
        } else if ($row['status'] === 'assigned') {
            $response['success'] = true;
            $response['assigned'] = true;
        }
    } else {
        $response['success'] = false;
        $response['message'] = "Request not found";
    }
    
    $stmt->close();
} else {
    $response['success'] = false;
    $response['message'] = "Invalid request";
}

echo json_encode($response);
$conn->close();
?>