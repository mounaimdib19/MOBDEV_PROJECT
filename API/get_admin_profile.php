<?php
header("Content-Type: application/json");
include "db_connection.php";

if (isset($_GET['id_admin'])) {
    $id_admin = $_GET['id_admin'];

    $stmt = $conn->prepare("SELECT id_admin, nom, prenom, adresse_email FROM administrateur WHERE id_admin = ?");
    $stmt->bind_param("i", $id_admin);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $admin = $result->fetch_assoc();
        echo json_encode(['success' => true, 'admin' => $admin]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Admin not found']);
    }

    $stmt->close();
} else {
    echo json_encode(['success' => false, 'message' => 'Missing id_admin parameter']);
}

$conn->close();
?>