<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

if (isset($_GET['id_doc'])) {
    $id_doc = $_GET['id_doc'];

    $query = "SELECT r.id_rendez_vous, r.date_heure_rendez_vous, p.nom as patient_nom, p.prenom as patient_prenom, pa.montant
              FROM rendez_vous r
              JOIN patient p ON r.id_patient = p.id_patient
              LEFT JOIN paiements pa ON r.id_rendez_vous = pa.id_rendez_vous
              WHERE r.id_doc = ? AND r.statut = 'complete'
              ORDER BY r.date_heure_rendez_vous DESC";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id_doc);
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
    echo json_encode(array("success" => false, "message" => "Missing id_doc parameter"));
}

$conn->close();
?>