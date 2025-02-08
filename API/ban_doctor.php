<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: *");
header("Content-Type: application/json");

include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    
    if (isset($data->id_doc)) {
        $id_doc = $data->id_doc;
        
        $query = "UPDATE docteur SET est_banni = NOT est_banni WHERE id_doc = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $id_doc);
        
        if ($stmt->execute()) {
            // Get the updated ban status
            $status_query = "SELECT est_banni FROM docteur WHERE id_doc = ?";
            $status_stmt = $conn->prepare($status_query);
            $status_stmt->bind_param("i", $id_doc);
            $status_stmt->execute();
            $result = $status_stmt->get_result();
            $row = $result->fetch_assoc();
            
            echo json_encode([
                "success" => true,
                "message" => "Doctor ban status updated successfully",
                "est_banni" => (bool)$row['est_banni']
            ]);
        } else {
            echo json_encode([
                "success" => false,
                "message" => "Failed to update doctor ban status"
            ]);
        }
        
        $stmt->close();
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Doctor ID is required"
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "Invalid request method"
    ]);
}

$conn->close();
?>