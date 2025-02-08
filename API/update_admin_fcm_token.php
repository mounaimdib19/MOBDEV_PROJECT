<?php
// update_admin_fcm_token.php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'db_connection.php';

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', 'admin_fcm_token_errors.log');

$response = [
    'success' => false,
    'message' => ''
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $id_admin = mysqli_real_escape_string($conn, $input['id_admin'] ?? '');
    $fcm_token = mysqli_real_escape_string($conn, $input['fcm_token'] ?? '');
    $device_info = mysqli_real_escape_string($conn, $input['device_info'] ?? '{}');

    if (empty($id_admin) || empty($fcm_token)) {
        $response['message'] = 'Missing required parameters';
    } else {
        mysqli_begin_transaction($conn);
        
        try {
            // Check if admin exists
            $check_query = "SELECT id_admin FROM administrateur WHERE id_admin = ?";
            $check_stmt = mysqli_prepare($conn, $check_query);
            
            if ($check_stmt) {
                mysqli_stmt_bind_param($check_stmt, "s", $id_admin);
                mysqli_stmt_execute($check_stmt);
                $result = mysqli_stmt_get_result($check_stmt);
                
                if (mysqli_fetch_assoc($result)) {
                    // Check if token exists
                    $token_query = "SELECT id_device FROM admin_devices WHERE fcm_token = ?";
                    $token_stmt = mysqli_prepare($conn, $token_query);
                    mysqli_stmt_bind_param($token_stmt, "s", $fcm_token);
                    mysqli_stmt_execute($token_stmt);
                    $token_result = mysqli_stmt_get_result($token_stmt);
                    
                    if (mysqli_fetch_assoc($token_result)) {
                        // Update existing token
                        $update_query = "UPDATE admin_devices 
                                       SET last_used = CURRENT_TIMESTAMP,
                                           is_active = TRUE,
                                           device_info = ?
                                       WHERE fcm_token = ?";
                        $update_stmt = mysqli_prepare($conn, $update_query);
                        mysqli_stmt_bind_param($update_stmt, "ss", $device_info, $fcm_token);
                        mysqli_stmt_execute($update_stmt);
                    } else {
                        // Insert new token
                        $insert_query = "INSERT INTO admin_devices 
                                       (id_admin, fcm_token, device_info, is_active) 
                                       VALUES (?, ?, ?, TRUE)";
                        $insert_stmt = mysqli_prepare($conn, $insert_query);
                        mysqli_stmt_bind_param($insert_stmt, "sss", $id_admin, $fcm_token, $device_info);
                        mysqli_stmt_execute($insert_stmt);
                    }
                    
                    mysqli_commit($conn);
                    $response['success'] = true;
                    $response['message'] = 'Admin FCM token updated successfully';
                } else {
                    throw new Exception('Admin not found');
                }
            }
        } catch (Exception $e) {
            mysqli_rollback($conn);
            $response['message'] = 'Error: ' . $e->getMessage();
        }
    }
}

echo json_encode($response);
mysqli_close($conn);