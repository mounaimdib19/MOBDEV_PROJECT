<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET' && isset($_GET['wilaya'])) {
    $wilaya = $_GET['wilaya'];
    $sql = "SELECT c.id_commune, c.nom_commune FROM commune c
            JOIN wilaya w ON c.id_wilaya = w.id_wilaya
            WHERE w.nom_wilaya = ?
            ORDER BY c.nom_commune";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $wilaya);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $communes = array();
        while($row = $result->fetch_assoc()) {
            $communes[] = $row;
        }
        $response = [
            'success' => true,
            'communes' => $communes
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'No communes found for the specified wilaya'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request or missing wilaya parameter']);
}

$conn->close();
?>