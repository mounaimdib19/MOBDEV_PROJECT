<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $sql = "SELECT id_wilaya, nom_wilaya FROM wilaya ORDER BY nom_wilaya";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $wilayas = array();
        while($row = $result->fetch_assoc()) {
            $wilayas[] = $row;
        }
        $response = [
            'success' => true,
            'wilayas' => $wilayas
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'No wilayas found'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>