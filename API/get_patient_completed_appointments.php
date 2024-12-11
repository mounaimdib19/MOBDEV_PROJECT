<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

if (isset($_GET['id_patient'])) {
    $id_patient = $_GET['id_patient'];

    $query = "SELECT r.id_rendez_vous, r.date_heure_rendez_vous, d.nom as doctor_nom, d.prenom as doctor_prenom, pa.montant
              FROM rendez_vous r
              JOIN docteur d ON r.id_doc = d.id_doc
              LEFT JOIN paiements pa ON r.id_rendez_vous = pa.id_rendez_vous
              WHERE r.id_patient = ? AND r.statut = 'complete'
              ORDER BY r.date_heure_rendez_vous DESC";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_patient);
    $stmt->execute();
    $result = $stmt->get_result();

    $appointments = array();

    while ($row = $result->fetch_assoc()) {
        $appointments[] = $row;
    }

    if (count($appointments) > 0) {
        echo json_encode(array("success" => true, "appointments" => $appointments));
    } else {
        echo json_encode(array("success" => false, "message" => "No completed appointments found"));
    }

    $stmt->close();
} else {
    echo json_encode(array("success" => false, "message" => "Missing id_patient parameter"));
}

$conn->close();
?>