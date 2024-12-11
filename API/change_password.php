<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Include your existing database connection file
include_once 'db_connection.php';

// Assuming your db_connect.php file creates a database connection
// and assigns it to a variable named $conn
// If it uses a different variable name, please adjust the following line accordingly
$db = $conn;

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->id_patient) &&
    !empty($data->current_password) &&
    !empty($data->new_password) &&
    !empty($data->confirm_password)
) {
    if ($data->new_password !== $data->confirm_password) {
        http_response_code(400);
        echo json_encode(array("message" => "New password and confirm password do not match."));
        exit();
    }

    $query = "SELECT mot_de_passe FROM patient WHERE id_patient = ?";
    $stmt = $db->prepare($query);
    $stmt->bind_param("i", $data->id_patient);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        if (password_verify($data->current_password, $row['mot_de_passe'])) {
            $hashed_password = password_hash($data->new_password, PASSWORD_DEFAULT);
            
            $update_query = "UPDATE patient SET mot_de_passe = ? WHERE id_patient = ?";
            $update_stmt = $db->prepare($update_query);
            $update_stmt->bind_param("si", $hashed_password, $data->id_patient);
            
            if ($update_stmt->execute()) {
                http_response_code(200);
                echo json_encode(array("message" => "Password was successfully updated."));
            } else {
                http_response_code(503);
                echo json_encode(array("message" => "Unable to update password."));
            }
        } else {
            http_response_code(401);
            echo json_encode(array("message" => "Current password is incorrect."));
        }
    } else {
        http_response_code(404);
        echo json_encode(array("message" => "Patient not found."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Unable to change password. Data is incomplete."));
}
?>