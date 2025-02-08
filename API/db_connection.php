<?php
$servername = "localhost"; 
$username = "u910666616_6paxnm";
$password = "#Da6paxnm";
$dbname = "u910666616_mabase";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>