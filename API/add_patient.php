<?php
header("Content-Type: application/json");
include "db_connection.php";

$data = json_decode(file_get_contents("php://input"), true);

$nom = mysqli_real_escape_string($conn, $data['nom']);
$prenom = mysqli_real_escape_string($conn, $data['prenom']);
$mot_de_passe = password_hash($data['mot_de_passe'], PASSWORD_DEFAULT);
$adresse_email = mysqli_real_escape_string($conn, $data['adresse_email']);
$numero_telephone = mysqli_real_escape_string($conn, $data['numero_telephone']);

$query = "INSERT INTO patient (nom, prenom, mot_de_passe, adresse_email, numero_telephone) 
          VALUES ('$nom', '$prenom', '$mot_de_passe', '$adresse_email', '$numero_telephone')";

if (mysqli_query($conn, $query)) {
    echo json_encode(["success" => true, "message" => "Patient added successfully"]);
} else {
    echo json_encode(["success" => false, "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>