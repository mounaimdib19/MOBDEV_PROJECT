<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'db_connection.php';

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', 'fcm_token_errors.log');

$response = [
    'success' => false,
    'message' => ''
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $id_doc = mysqli_real_escape_string($conn, $input['id_doc'] ?? '');
    $fcm_token = mysqli_real_escape_string($conn, $input['fcm_token'] ?? '');
    $device_info = mysqli_real_escape_string($conn, $input['device_info'] ?? '{}');

    error_log("Received update request - ID: $id_doc, Token: $fcm_token");

    if (empty($id_doc) || empty($fcm_token)) {
        $response['message'] = 'Missing required parameters';
        error_log("Missing parameters - ID: $id_doc, Token: $fcm_token");
    } else {
        mysqli_begin_transaction($conn);
        
        try {
            // First check if the doctor exists
            $check_query = "SELECT id_doc FROM docteur WHERE id_doc = ?";
            $check_stmt = mysqli_prepare($conn, $check_query);
            
            if ($check_stmt) {
                mysqli_stmt_bind_param($check_stmt, "s", $id_doc);
                mysqli_stmt_execute($check_stmt);
                $result = mysqli_stmt_get_result($check_stmt);
                
                if (mysqli_fetch_assoc($result)) {
                    // Check if token already exists
                    $token_query = "SELECT id_device FROM doctor_devices WHERE fcm_token = ?";
                    $token_stmt = mysqli_prepare($conn, $token_query);
                    mysqli_stmt_bind_param($token_stmt, "s", $fcm_token);
                    mysqli_stmt_execute($token_stmt);
                    $token_result = mysqli_stmt_get_result($token_stmt);
                    
                    if ($existing_device = mysqli_fetch_assoc($token_result)) {
                        // Token exists, update last_used timestamp
                        $update_query = "UPDATE doctor_devices 
                                       SET last_used = CURRENT_TIMESTAMP,
                                           is_active = TRUE,
                                           device_info = ?
                                       WHERE fcm_token = ?";
                        $update_stmt = mysqli_prepare($conn, $update_query);
                        mysqli_stmt_bind_param($update_stmt, "ss", $device_info, $fcm_token);
                        mysqli_stmt_execute($update_stmt);
                    } else {
                        // New token, insert new record
                        $insert_query = "INSERT INTO doctor_devices 
                                       (id_doc, fcm_token, device_info, is_active) 
                                       VALUES (?, ?, ?, TRUE)";
                        $insert_stmt = mysqli_prepare($conn, $insert_query);
                        mysqli_stmt_bind_param($insert_stmt, "sss", $id_doc, $fcm_token, $device_info);
                        mysqli_stmt_execute($insert_stmt);
                    }
                    
                    mysqli_commit($conn);
                    $response['success'] = true;
                    $response['message'] = 'FCM token updated successfully';
                    error_log("Token updated successfully for ID: $id_doc");
                } else {
                    throw new Exception('Doctor not found');
                }
            }
        } catch (Exception $e) {
            mysqli_rollback($conn);
            $response['message'] = 'Error: ' . $e->getMessage();
            error_log("Error updating token: " . $e->getMessage());
        }
    }
}

echo json_encode($response);
mysqli_close($conn);