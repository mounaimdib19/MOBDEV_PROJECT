<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

ob_start();

// CORS Headers
header("Access-Control-Allow-Origin: *"); // Allow requests from any origin
header("Access-Control-Allow-Methods: POST, OPTIONS"); // Allow POST and OPTIONS methods
header("Access-Control-Allow-Headers: Content-Type"); // Allow Content-Type header
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'db_connection.php';

$response = array();

try {
    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        error_log("Received POST data: " . print_r($_POST, true));
        error_log("Received FILES data: " . print_r($_FILES, true));

        $nom = $_POST['nom'] ?? '';
        $has_fixed_price = $_POST['has_fixed_price'] ?? '';
        $fixed_price = $_POST['fixed_price'] ?? '';
        
        $picture_url = null;
        if (isset($_FILES['image'])) {
            $target_dir = "../upload/services/";
            if (!file_exists($target_dir)) {
                if (!mkdir($target_dir, 0777, true)) {
                    throw new Exception("Failed to create upload directory");
                }
            }
            
            // Use the service name for the image filename
            $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
            $picture_url = strtolower(str_replace(' ', '_', $nom)) . '.' . $file_extension;
            $target_file = $target_dir . $picture_url;
            
            // Check if file already exists, if so, add a number to the filename
            $counter = 1;
            while (file_exists($target_file)) {
                $picture_url = strtolower(str_replace(' ', '_', $nom)) . '_' . $counter . '.' . $file_extension;
                $target_file = $target_dir . $picture_url;
                $counter++;
            }
            
            if (!move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
                throw new Exception("Sorry, there was an error uploading your file.");
            }
        }

        $sql = "INSERT INTO service_types (nom, has_fixed_price, fixed_price, picture_url) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $bind_result = $stmt->bind_param("sids", $nom, $has_fixed_price, $fixed_price, $picture_url);
        if (!$bind_result) {
            throw new Exception("Binding parameters failed: " . $stmt->error);
        }

        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        $response['success'] = true;
        $response['message'] = "Service added successfully";
        
        $stmt->close();
    } else {
        throw new Exception("Invalid request method");
    }
} catch (Exception $e) {
    error_log("Error in add_service.php: " . $e->getMessage());
    $response['success'] = false;
    $response['message'] = "An error occurred: " . $e->getMessage();
}

$output = ob_get_clean();
if (!empty($output)) {
    error_log("Unexpected output before JSON: " . $output);
}

echo json_encode($response);

$conn->close();
?>