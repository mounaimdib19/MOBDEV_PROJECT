<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

error_reporting(E_ALL);
ini_set('display_errors', 0);

require_once '../vendor/autoload.php';
require_once 'db_connection.php';

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\ApnsConfig;

// Logging functions
function logError($message) {
    $logEntry = date('Y-m-d H:i:s') . " - ERROR: " . $message . PHP_EOL;
    file_put_contents('../logs/notification_errors.log', $logEntry, FILE_APPEND);
}

function logNotificationAttempt($type, $token, $success, $error = null) {
    $logEntry = date('Y-m-d H:i:s') . " - Type: $type - Token: $token - Success: " . ($success ? 'Yes' : 'No');
    if ($error) {
        $logEntry .= " - Error: $error";
    }
    file_put_contents('../logs/notification_attempts.log', $logEntry . PHP_EOL, FILE_APPEND);
}

// Token management functions
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

// Firebase notification configuration
function getNotificationConfigs($title, $body) {
    $androidConfig = AndroidConfig::fromArray([
        'priority' => 'high',
        'direct_boot_ok' => true,
        'notification' => [
            'channel_id' => 'admin_channel',
            'priority' => 'high',
            'default_sound' => true,
            'default_vibrate_timings' => true,
            'time_to_live' => 2419200
        ],
        'android_direct_boot_ok' => true,
        'wake_lock_timeout' => 30000
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
            ]
        ]
    ]);

    return [
        'android' => $androidConfig,
        'apns' => $apnsConfig
    ];
}

// Send FCM notifications
function sendAdminFCMNotification($tokens, $title, $body, $data = []) {
    if (empty($tokens)) {
        logError("No admin FCM tokens provided");
        return false;
    }

    try {
        $factory = (new Factory)->withServiceAccount('service-account.json');
        $messaging = $factory->createMessaging();
        
        $configs = getNotificationConfigs($title, $body);
        
        $notification = Notification::create($title, $body);
        $message = CloudMessage::new()
            ->withNotification($notification)
            ->withAndroidConfig($configs['android'])
            ->withApnsConfig($configs['apns'])
            ->withData($data);

        $sendReport = [];
        foreach ($tokens as $token) {
            try {
                $result = $messaging->send($message->withTarget('token', $token));
                $sendReport[] = $result;
                logNotificationAttempt('admin', $token, true);
            } catch (Exception $e) {
                logNotificationAttempt('admin', $token, false, $e->getMessage());
                continue;
            }
        }
        
        return !empty($sendReport);
    } catch (Exception $e) {
        logError("Admin FCM Error: " . $e->getMessage());
        return false;
    }
}

// Check for new requests of all types
function checkNewRequests($conn) {
    try {
        mysqli_begin_transaction($conn);
        
        // Get counts for all request types
        $requestCounts = [
            'doctor' => getRequestCount($conn, 'doctor_requests'),
            'nurse' => getRequestCount($conn, 'nurse_assistance_requests'),
            'garde_malade' => getRequestCount($conn, 'garde_malade_requests'),
            'assistance' => getRequestCount($conn, 'assistance_requests')
        ];
        
        $totalNewRequests = array_sum($requestCounts);

        if ($totalNewRequests > 0) {
            $tokens = getActiveAdminTokens($conn);
            
            if (!empty($tokens)) {
                $notificationData = prepareNotificationData($requestCounts, $totalNewRequests);
                $notificationSent = sendAdminFCMNotification(
                    $tokens,
                    $notificationData['title'],
                    $notificationData['body'],
                    $notificationData['data']
                );

                if ($notificationSent) {
                    updateNotificationStatus($conn);
                }
            }
        }

        mysqli_commit($conn);
        
        return [
            'success' => true,
            'new_requests' => $totalNewRequests,
            'details' => [
                'doctor_requests' => $requestCounts['doctor'],
                'nurse_requests' => $requestCounts['nurse'],
                'gm_requests' => $requestCounts['garde_malade'],
                'assistant_requests' => $requestCounts['assistance']
            ]
        ];

    } catch (Exception $e) {
        mysqli_rollback($conn);
        logError("Error in checkNewRequests: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'An error occurred while processing new requests'
        ];
    }
}

// Helper functions
function getRequestCount($conn, $table) {
    $query = "SELECT COUNT(*) as count FROM $table 
              WHERE notification_sent = FALSE OR notification_sent IS NULL";
    $result = mysqli_query($conn, $query);
    return mysqli_fetch_assoc($result)['count'];
}

function prepareNotificationData($counts, $total) {
    $title = "New Service Requests";
    $body = "You have $total new request(s) pending review";
    
    $data = [
        'type' => 'new_requests',
        'doctor_count' => $counts['doctor'],
        'nurse_count' => $counts['nurse'],
        'gm_count' => $counts['garde_malade'],
        'assistant_count' => $counts['assistance'],
        'total_count' => $total,
        'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
    ];

    return [
        'title' => $title,
        'body' => $body,
        'data' => $data
    ];
}

function updateNotificationStatus($conn) {
    $tables = [
        'doctor_requests',
        'nurse_assistance_requests',
        'garde_malade_requests',
        'assistance_requests'
    ];

    foreach ($tables as $table) {
        $query = "UPDATE $table 
                 SET notification_sent = TRUE,
                     notification_sent_at = CURRENT_TIMESTAMP 
                 WHERE notification_sent = FALSE 
                 OR notification_sent IS NULL";
        
        if (!mysqli_query($conn, $query)) {
            throw new Exception("Failed to update notification status for $table");
        }
    }
}

// Main execution
try {
    if (!isset($conn) || !$conn) {
        throw new Exception("Database connection failed");
    }

    $result = checkNewRequests($conn);
    echo json_encode($result);

} catch (Exception $e) {
    logError("Error: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'An error occurred while processing your request'
    ]);
} finally {
    if (isset($conn) && $conn) {
        mysqli_close($conn);
    }
}