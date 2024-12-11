<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Include the database connection file
require_once 'db_connection.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->table) && !empty($data->id) && !empty($data->id_column)) {
    $table = $data->table;
    $id = $data->id;
    $id_column = $data->id_column;

    $query = "DELETE FROM " . $table . " WHERE " . $id_column . " = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(array("message" => "Record was deleted."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to delete record."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to delete record. Data is incomplete."));
}

$conn->close();
?>