<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

file_put_contents('debug.log', "Script accessed at " . date('Y-m-d H:i:s') . "\n", FILE_APPEND);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(E_ALL);
ini_set('display_errors', 1);
include 'db_connection.php'; // Include your DB connection here
$latitude = $_POST['latitude'];
$longitude = $_POST['longitude'];
$id_patient = $_POST['id_patient'];
$id_service_type = $_POST['id_service_type'];

// Update patient's location
$update_sql = "UPDATE patient SET latitude = ?, longitude = ? WHERE id_patient = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("ddi", $latitude, $longitude, $id_patient);
$update_stmt->execute();

// Search for nearest nurses with the specified service
$sql = "SELECT d.id_doc, d.nom, d.prenom, d.latitude, d.longitude,
        (6371 * acos(cos(radians(?)) * cos(radians(d.latitude)) * 
        cos(radians(d.longitude) - radians(?)) + 
        sin(radians(?)) * sin(radians(d.latitude)))) AS distance
        FROM docteur d
        JOIN doctor_services ds ON d.id_doc = ds.id_doc
        WHERE d.status = 'active' AND d.est_infirmier = 1 AND ds.id_service_type = ?
        ORDER BY distance
        LIMIT 1";

$stmt = $conn->prepare($sql);
$stmt->bind_param("dddi", $latitude, $longitude, $latitude, $id_service_type);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $nurse = $result->fetch_assoc();
    echo json_encode(["success" => true, "nurse" => $nurse]);
} else {
    echo json_encode(["success" => false, "message" => "No nurses found nearby with the specified service"]);
}

file_put_contents('debug.log', "Script completed at " . date('Y-m-d H:i:s') . "\n", FILE_APPEND);

$conn->close();
?>