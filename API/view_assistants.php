<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Include the database connection file
require_once 'db_connection.php';

$query = "SELECT * FROM docteur WHERE assistant = TRUE";
$result = $conn->query($query);

if ($result->num_rows > 0) {
    $assistants_arr = array();
    $assistants_arr["records"] = array();

    while ($row = $result->fetch_assoc()) {
        $assistant_item = array(
            "id_doc" => $row['id_doc'],
            "nom" => $row['nom'],
            "prenom" => $row['prenom'],
            "adresse_email" => $row['adresse_email'],
            "numero_telephone" => $row['numero_telephone']
        );

        array_push($assistants_arr["records"], $assistant_item);
    }

    http_response_code(200);
    echo json_encode($assistants_arr);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No assistants found."));
}

$conn->close();
?>