<?
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $id_patient = $data['id_patient'];

    $query = "DELETE FROM patient WHERE id_patient = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_patient);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Patient deleted successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete patient']);
    }

    $stmt->close();
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();