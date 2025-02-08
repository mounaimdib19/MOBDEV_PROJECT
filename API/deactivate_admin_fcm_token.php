<?php
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
    $fcm_token = mysqli_real_escape_string($conn, $input['fcm_token'] ?? '');

    if (empty($fcm_token)) {
        $response['message'] = 'FCM token is required';
    } else {
        mysqli_begin_transaction($conn);
        
        try {
            $update_query = "UPDATE admin_devices 
                           SET is_active = FALSE 
                           WHERE fcm_token = ?";
            
            $update_stmt = mysqli_prepare($conn, $update_query);
            mysqli_stmt_bind_param($update_stmt, "s", $fcm_token);
            
            if (mysqli_stmt_execute($update_stmt)) {
                mysqli_commit($conn);
                $response['success'] = true;
                $response['message'] = 'Admin token deactivated successfully';
            } else {
                throw new Exception('Failed to deactivate token');
            }
        } catch (Exception $e) {
            mysqli_rollback($conn);
            $response['message'] = 'Error: ' . $e->getMessage();
        }
    }
}

echo json_encode($response);
mysqli_close($conn);