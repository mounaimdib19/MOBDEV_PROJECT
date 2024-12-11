<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', 'php_errors.log');

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

$response = array();

try {
    if (isset($_GET['id_admin'])) {
        $id_admin = intval($_GET['id_admin']);

        $query = "SELECT nom, prenom, statut, type FROM administrateur WHERE id_admin = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $id_admin);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $response = array(
                "success" => true,
                "nom" => $row['nom'],
                "prenom" => $row['prenom'],
                "statut" => $row['statut'],
                "type" => $row['type']
            );
        } else {
            $response = array(
                "success" => false,
                "message" => "Admin not found"
            );
        }
    } else {
        $response = array(
            "success" => false,
            "message" => "Missing id_admin parameter"
        );
    }
} catch (Exception $e) {
    $response = array(
        "success" => false,
        "message" => "An error occurred: " . $e->getMessage()
    );
    error_log("Error in get_admin_info.php: " . $e->getMessage());
}

echo json_encode($response);

$conn->close();
?>