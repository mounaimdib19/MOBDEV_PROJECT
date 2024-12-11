<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET' && isset($_GET['specialite'])) {
    $specialite = $_GET['specialite'];
    $sql = "SELECT ss.id_sous_specialite, ss.nom_sous_specialite FROM sous_specialite ss
            JOIN specialite s ON ss.specialite_parent = s.id_specialite
            WHERE s.nom_specialite = ?
            ORDER BY ss.nom_sous_specialite";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $specialite);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $sous_specialites = array();
        while($row = $result->fetch_assoc()) {
            $sous_specialites[] = $row;
        }
        $response = [
            'success' => true,
            'sous_specialites' => $sous_specialites
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'No sous-specialities found for the specified speciality'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request or missing specialite parameter']);
}

$conn->close();
?>