<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_doc = isset($_POST['id_doc']) ? (int)$_POST['id_doc'] : 0;
    
    if ($id_doc <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid doctor ID']);
        exit;
    }

    $columns = [
        'nom' => 's', 'prenom' => 's', 'adresse' => 's', 'id_wilaya' => 'i',
        'id_commune' => 'i', 'adresse_email' => 's', 'numero_telephone' => 's',
        'Latitude' => 'd', 'longitude' => 'd', 'status' => 's'
    ];
    
    $updateFields = [];
    $updateValues = [];
    $types = '';

    foreach ($columns as $column => $type) {
        if (isset($_POST[$column]) && $_POST[$column] !== '') {
            $updateFields[] = "$column = ?";
            
            switch ($type) {
                case 'i':
                    $updateValues[] = (int)$_POST[$column];
                    break;
                case 'd':
                    $updateValues[] = (float)$_POST[$column];
                    break;
                case 's':
                default:
                    $updateValues[] = $_POST[$column];
                    break;
            }
            
            $types .= $type;
        }
    }

    if (empty($updateFields)) {
        echo json_encode(['success' => false, 'message' => 'No fields to update']);
        exit;
    }

    try {
        $sql = "UPDATE docteur SET " . implode(', ', $updateFields) . " WHERE id_doc = ?";
        $stmt = $conn->prepare($sql);

        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $updateValues[] = $id_doc;
        $types .= 'i'; // for id_doc

        $stmt->bind_param($types, ...$updateValues);
        
        if (!$stmt->execute()) {
            throw new Exception("Execute failed: " . $stmt->error);
        }

        if ($stmt->affected_rows > 0) {
            echo json_encode(['success' => true, 'message' => 'Profile updated successfully']);
        } else {
            echo json_encode(['success' => false, 'message' => 'No changes were made to the profile']);
        }

        $stmt->close();
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => 'Error updating profile: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>