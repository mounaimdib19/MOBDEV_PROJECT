<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

if (isset($_POST['id_rendez_vous'])) {
    $id_rendez_vous = $_POST['id_rendez_vous'];

    $query = "UPDATE rendez_vous SET statut = 'annule' WHERE id_rendez_vous = ?";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_rendez_vous);
    
    if ($stmt->execute()) {
        echo json_encode(array("success" => true, "message" => "Appointment cancelled successfully"));
    } else {
        echo json_encode(array("success" => false, "message" => "Failed to cancel appointment"));
    }

    $stmt->close();
} else {
    echo json_encode(array("success" => false, "message" => "Missing id_rendez_vous parameter"));
}

$conn->close();
?>