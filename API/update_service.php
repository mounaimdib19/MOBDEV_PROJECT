<?php
function exception_error_handler($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
}
set_error_handler("exception_error_handler");

error_reporting(E_ALL);
ini_set('display_errors', 1);

ob_start();

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

try {
    require_once 'db_connection.php';

    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $id_service_type = $_POST['id_service_type'];
        $nom = $_POST['nom'];
        $has_fixed_price = $_POST['has_fixed_price'];
        $fixed_price = $_POST['fixed_price'] !== '' ? $_POST['fixed_price'] : null;

        // Get the current picture filename
        $sql = "SELECT picture_url FROM service_types WHERE id_service_type = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id_service_type);
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $current_picture_url = $row['picture_url'];

        $picture_url = $current_picture_url; // Default to keeping the current picture

        // Handle file upload
        if(isset($_FILES['picture']) && $_FILES['picture']['error'] == 0) {
            $upload_dir = '../upload/services/';
            
            // If there's a current picture, use its name for the new picture
            if ($current_picture_url) {
                $picture_url = $current_picture_url;
            } else {
                // If there's no current picture, create a new filename based on the service name
                $file_extension = pathinfo($_FILES["picture"]["name"], PATHINFO_EXTENSION);
                $picture_url = strtolower(str_replace(' ', '_', $nom)) . '.' . $file_extension;
            }
            
            $upload_path = $upload_dir . $picture_url;

            if(move_uploaded_file($_FILES['picture']['tmp_name'], $upload_path)) {
                // The old picture is automatically overwritten if it exists
            } else {
                throw new Exception("Failed to upload picture");
            }
        }

        $sql = "UPDATE service_types SET nom = ?, has_fixed_price = ?, fixed_price = ?, picture_url = ? WHERE id_service_type = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("sissi", $nom, $has_fixed_price, $fixed_price, $picture_url, $id_service_type);

        if ($stmt->execute()) {
            $response = [
                'success' => true,
                'message' => 'Service updated successfully'
            ];
        } else {
            throw new Exception("Update failed: " . $conn->error);
        }

        $stmt->close();
    } else {
        $response = ['success' => false, 'message' => 'Invalid request method'];
    }
} catch (Exception $e) {
    $response = [
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ];
}

ob_end_clean();

echo json_encode($response);

if (isset($conn)) {
    $conn->close();
}
?>