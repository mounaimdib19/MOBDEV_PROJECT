
<?php
header("Content-Type: application/json");
include "db_connection.php";

$nom = $_POST['nom'];
$prenom = $_POST['prenom'];
$email = $_POST['adresse_email'];
$password = password_hash($_POST['mot_de_passe'], PASSWORD_DEFAULT);
$type = $_POST['type'];
$statut = $_POST['statut'];

$sql = "INSERT INTO administrateur (nom, prenom, adresse_email, mot_de_passe, type, statut) 
        VALUES (?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssssss", $nom, $prenom, $email, $password, $type, $statut);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Administrator added successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Error: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>