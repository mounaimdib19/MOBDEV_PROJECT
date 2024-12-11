<?php
// File: get_doctors.php

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

include 'db_connection.php';

$type = isset($_GET['type']) ? $_GET['type'] : '';

if (empty($type)) {
    echo json_encode(['success' => false, 'message' => 'Type parameter is required']);
    exit;
}

$conditions = '';
switch ($type) {
    case 'doctor':
        $conditions = 'est_infirmier = 0 AND est_gm = 0';
        break;
    case 'nurse':
        $conditions = 'est_infirmier = 1 AND est_gm = 0';
        break;
    case 'gm':
        $conditions = 'est_gm = 1';
        break;
    default:
        echo json_encode(['success' => false, 'message' => 'Invalid type']);
        exit;
}

$query = "SELECT d.id_doc, d.nom, d.prenom, d.adresse_email, d.adresse, c.nom_commune AS commune, w.nom_wilaya AS wilaya,
          (SELECT COUNT(*) FROM rendez_vous WHERE id_doc = d.id_doc) AS appointments_count,
          (SELECT COALESCE(SUM(p.montant), 0) FROM paiements p
           JOIN rendez_vous r ON p.id_rendez_vous = r.id_rendez_vous
           WHERE r.id_doc = d.id_doc) AS total_earnings
          FROM docteur d
          LEFT JOIN commune c ON d.id_commune = c.id_commune
          LEFT JOIN wilaya w ON d.id_wilaya = w.id_wilaya
          WHERE $conditions";

$result = mysqli_query($conn, $query);

if ($result) {
    $doctors = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $doctors[] = $row;
    }
    echo json_encode(['success' => true, 'doctors' => $doctors]);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to fetch doctors']);
}

mysqli_close($conn);
?>