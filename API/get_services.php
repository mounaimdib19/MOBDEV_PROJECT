<?php
header("Content-Type: application/json");
include_once 'db_connect.php';

$sql = "SELECT * FROM service_types";
$result = $conn->query($sql);

$services = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $services[] = $row;
    }
}

echo json_encode($services);

$conn->close();
?>