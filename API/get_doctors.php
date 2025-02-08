<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: *");
header("Content-Type: application/json");

include 'db_connection.php';

$type = isset($_GET['type']) ? $_GET['type'] : 'doctor';
$ban_status = isset($_GET['ban_status']) ? $_GET['ban_status'] : 'all';

// Base query
$query = "SELECT d.*, 
          COUNT(DISTINCT r.id_rendez_vous) as appointments_count,
          COALESCE(SUM(p.montant), 0) as total_earnings
          FROM docteur d
          LEFT JOIN rendez_vous r ON d.id_doc = r.id_doc
          LEFT JOIN paiements p ON r.id_rendez_vous = p.id_rendez_vous
          WHERE 1=1";

if ($type == 'doctor') {
    $query .= " AND d.est_infirmier = 0 AND d.est_gm = 0 AND d.assistant = 0";
} elseif ($type == 'nurse') {
    $query .= " AND d.est_infirmier = 1";
} elseif ($type == 'gm') {
    $query .= " AND d.est_gm = 1";
} elseif ($type == 'assistant') {
    $query .= " AND d.assistant = 1";
}

// Add ban status condition if specified
if ($ban_status !== 'all') {
    $is_banned = $ban_status === 'banned' ? 1 : 0;
    $query .= " AND d.est_banni = $is_banned";
}

$query .= " GROUP BY d.id_doc";

$result = $conn->query($query);

if ($result) {
    $doctors = array();
    while ($row = $result->fetch_assoc()) {
        $doctors[] = $row;
    }
    echo json_encode([
        "success" => true,
        "doctors" => $doctors
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Failed to fetch doctors"
    ]);
}

$conn->close();
?>