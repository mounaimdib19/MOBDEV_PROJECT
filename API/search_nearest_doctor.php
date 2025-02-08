<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'db_connection.php';

// Get parameters
$latitude = $_POST['latitude'];
$longitude = $_POST['longitude'];
$id_patient = $_POST['id_patient'];

// Update patient's location
$update_sql = "UPDATE patient SET latitude = ?, longitude = ? WHERE id_patient = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("ddi", $latitude, $longitude, $id_patient);
$update_stmt->execute();

// Search for nearest doctor
$sql = "SELECT id_doc, nom, prenom, latitude, longitude,
        (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
        cos(radians(longitude) - radians(?)) + 
        sin(radians(?)) * sin(radians(latitude)))) AS distance
        FROM docteur
        WHERE status = 'active' 
        AND est_infirmier = 0 
        AND est_gm = 0 
        AND assistant = 0
        ORDER BY distance
        LIMIT 1";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ddd", $latitude, $longitude, $latitude);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $doctor = [
        'id_doc' => $row['id_doc'],
        'nom' => $row['nom'],
        'prenom' => $row['prenom'],
        'distance' => floatval($row['distance'])
    ];
    echo json_encode(["success" => true, "doctor" => $doctor]);
} else {
    echo json_encode(["success" => false, "message" => "No doctor found nearby"]);
}

$conn->close();
?>