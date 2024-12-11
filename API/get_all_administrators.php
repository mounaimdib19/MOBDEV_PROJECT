<?php
header("Content-Type: application/json");
include "db_connection.php";

$sql = "SELECT * FROM administrateur";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $administrators = array();
    while($row = $result->fetch_assoc()) {
        $administrators[] = $row;
    }
    echo json_encode($administrators);
} else {
    echo json_encode([]);
}

$conn->close();
?>