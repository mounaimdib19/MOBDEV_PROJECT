<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_doc = (int)$_POST['id_doc'];
    $new_password = $_POST['new_password'];

    // Hash the new password
    $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

    $sql = "UPDATE docteur SET mot_de_passe = ? WHERE id_doc = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $hashed_password, $id_doc);
    
    if ($stmt->execute()) {
        $response = [
            'success' => true,
            'message' => 'Password updated successfully'
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Failed to update password'
        ];
    }

    echo json_encode($response);
}

$conn->close();
?>