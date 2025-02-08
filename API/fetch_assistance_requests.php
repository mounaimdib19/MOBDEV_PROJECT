<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

error_reporting(E_ALL);
ini_set('display_errors', 0);

require_once '../vendor/autoload.php';
require_once 'db_connection.php';

use Google\Cloud\Storage\StorageClient;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;

function logError($message) {
    $logEntry = date('Y-m-d H:i:s') . " - ERROR: " . $message . PHP_EOL;
    file_put_contents('../logs/error.log', $logEntry, FILE_APPEND);
}

function logNotificationAttempt($token, $success, $error = null) {
    $logEntry = date('Y-m-d H:i:s') . " - Token: $token - Success: " . ($success ? 'Yes' : 'No');
    if ($error) {
        $logEntry .= " - Error: $error";
    }
    file_put_contents('../logs/notification_attempts.log', $logEntry . PHP_EOL, FILE_APPEND);
}

function sendFCMNotification($tokens, $title, $body, $data = []) {
    if (empty($tokens)) {
        logError("No FCM tokens provided");
        return false;
    }

    try {
        $factory = (new Factory)->withServiceAccount('service-account.json');
        $messaging = $factory->createMessaging();
        
        // Updated Android configuration to match working admin notifications
        $androidConfig = AndroidConfig::fromArray([
            'priority' => 'high',
            'direct_boot_ok' => true,
            'notification' => [
                'channel_id' => 'default_notification_channel',
                'priority' => 'high',
                'default_sound' => true,
                'default_vibrate_timings' => true,
                'time_to_live' => 2419200  // 28 days
            ],
            'android_direct_boot_ok' => true,
            'wake_lock_timeout' => 30000  // 30 seconds
        ]);

        $apnsConfig = ApnsConfig::fromArray([
            'headers' => [
                'apns-priority' => '10',
                'apns-push-type' => 'alert',
            ],
            'payload' => [
                'aps' => [
                    'alert' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'sound' => 'default',
                    'badge' => 1,
                    'content-available' => 1,
                ]
            ]
        ]);

        $notification = Notification::create($title, $body);
        $message = CloudMessage::new()
            ->withNotification($notification)
            ->withAndroidConfig($androidConfig)
            ->withApnsConfig($apnsConfig)
            ->withData($data);

        $sendReport = [];
        foreach ($tokens as $token) {
            try {
                $result = $messaging->send($message->withTarget('token', $token));
                $sendReport[] = $result;
                logNotificationAttempt($token, true);
            } catch (\Kreait\Firebase\Exception\MessagingException $e) {
                logNotificationAttempt($token, false, $e->getMessage());
                continue;
            }
        }
        
        return !empty($sendReport);
        
    } catch (\Exception $e) {
        logError("FCM Error: " . $e->getMessage());
        return false;
    }
}

function getActiveDoctorTokens($conn) {
    $tokens = [];
    $tokenQuery = "SELECT DISTINCT dd.fcm_token 
                   FROM doctor_devices dd
                   INNER JOIN docteur d ON d.id_doc = dd.id_doc
                   WHERE d.status = 'active' 
                   AND dd.is_active = TRUE
                   AND dd.fcm_token IS NOT NULL 
                   AND dd.fcm_token != ''
                   AND dd.last_used >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
    
    $tokenResult = mysqli_query($conn, $tokenQuery);
    if ($tokenResult) {
        while ($tokenRow = mysqli_fetch_assoc($tokenResult)) {
            if (!empty($tokenRow['fcm_token'])) {
                $tokens[] = $tokenRow['fcm_token'];
            }
        }
    }
    return array_unique($tokens);
}

function getActiveAdminTokens($conn) {
    $tokens = [];
    $query = "SELECT DISTINCT ad.fcm_token 
              FROM admin_devices ad
              INNER JOIN administrateur a ON a.id_admin = ad.id_admin
              WHERE ad.is_active = TRUE
              AND ad.fcm_token IS NOT NULL 
              AND ad.fcm_token != ''
              AND ad.last_used >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
    
    $result = mysqli_query($conn, $query);
    if ($result) {
        while ($row = mysqli_fetch_assoc($result)) {
            if (!empty($row['fcm_token'])) {
                $tokens[] = $row['fcm_token'];
            }
        }
    }
    return array_unique($tokens);
}

function cleanupInactiveTokens($conn) {
    $cleanup_query = "UPDATE doctor_devices 
                     SET is_active = FALSE 
                     WHERE last_used < DATE_SUB(NOW(), INTERVAL 30 DAY) 
                     AND is_active = TRUE";
    mysqli_query($conn, $cleanup_query);
}

function sendNotificationsForNewRequests($conn) {
    try {
        mysqli_begin_transaction($conn);
        cleanupInactiveTokens($conn);
        
        $query = "SELECT 
                    id_request, 
                    numero_telephone,
                    description,
                    cree_le
                 FROM assistance_requests 
                 WHERE status = 'pending' 
                 AND (notification_sent = FALSE OR notification_sent IS NULL)
                 FOR UPDATE";
                 
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            throw new Exception("Query error: " . mysqli_error($conn));
        }
        
        $newRequests = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $newRequests[] = $row;
        }
        
        if (!empty($newRequests)) {
            $doctorTokens = getActiveDoctorTokens($conn);
            $adminTokens = getActiveAdminTokens($conn);
            
            $tokens = array_merge($doctorTokens, $adminTokens);
            
            if (!empty($tokens)) {
                $newRequestsCount = count($newRequests);
                $notificationTitle = "New Assistance Request" . ($newRequestsCount > 1 ? "s" : "");
                $notificationBody = "$newRequestsCount new urgent assistance request" . 
                                  ($newRequestsCount > 1 ? "s" : "") . " received";
                
                $data = [
                    'type' => 'assistance_request',
                    'request_count' => $newRequestsCount,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
                ];
                
                $notificationSent = sendFCMNotification($tokens, $notificationTitle, $notificationBody, $data);
                
                if ($notificationSent) {
                    $requestIds = array_map(function($request) {
                        return (int)$request['id_request'];
                    }, $newRequests);
                    
                    $requestIdsStr = implode(',', $requestIds);
                    $updateQuery = "UPDATE assistance_requests 
                                  SET notification_sent = TRUE,
                                      notification_sent_at = CURRENT_TIMESTAMP
                                  WHERE id_request IN ($requestIdsStr)";
                    
                    if (!mysqli_query($conn, $updateQuery)) {
                        throw new Exception("Failed to update notification status");
                    }
                }
            }
        }
        
        mysqli_commit($conn);
        
        return [
            'success' => true,
            'new_requests' => $newRequests,
            'new_requests_count' => count($newRequests)
        ];
        
    } catch (Exception $e) {
        mysqli_rollback($conn);
        logError("Error in sendNotificationsForNewRequests: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'An error occurred while processing new requests'
        ];
    }
}

function getAllPendingRequests($conn) {
    $query = "SELECT 
                id_request, 
                numero_telephone,
                description,
                cree_le,
                notification_sent,
                notification_sent_at
              FROM assistance_requests 
              WHERE status = 'pending'
              ORDER BY cree_le ASC";
              
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        throw new Exception("Error fetching pending requests: " . mysqli_error($conn));
    }
    
    $requests = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $requests[] = $row;
    }
    
    return $requests;
}

try {
    if (!isset($conn) || !$conn) {
        throw new Exception("Database connection failed");
    }

    $notificationResult = sendNotificationsForNewRequests($conn);
    $pendingRequests = getAllPendingRequests($conn);
    
    $response = [
        'success' => true,
        'requests' => $pendingRequests,
        'total_requests' => count($pendingRequests),
        'new_notifications_sent' => $notificationResult['success'] && !empty($notificationResult['new_requests']),
        'new_requests_count' => $notificationResult['success'] ? $notificationResult['new_requests_count'] : 0,
        'message' => count($pendingRequests) > 0 ? 'Requests found' : 'No pending requests'
    ];

} catch (Exception $e) {
    logError("Error: " . $e->getMessage());
    $response = [
        'success' => false,
        'message' => 'An error occurred while processing your request'
    ];
} finally {
    if (isset($conn) && $conn) {
        mysqli_close($conn);
    }
    echo json_encode($response);
    exit();
}