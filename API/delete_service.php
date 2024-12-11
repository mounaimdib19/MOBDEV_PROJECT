<?
("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $id_service_type = $data['id_service_type'];

    $query = "DELETE FROM service_types WHERE id_service_type = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_service_type);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Service deleted successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete service']);
    }

    $stmt->close();
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();