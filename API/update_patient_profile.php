<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_patient = isset($_POST['id_patient']) ? (int)$_POST['id_patient'] : 0;
    
    if ($id_patient <= 0) {
        echo json_encode(['success' => false, 'message' => 'Invalid patient ID']);
        exit;
    }

    $columns = [
        'nom' => 's', 'prenom' => 's', 'adresse' => 's', 'numero_telephone' => 'i',
        'wilaya' => 's', 'commune' => 's', 'parent_nom' => 's', 'parent_num' => 'i',
        'adresse_email' => 's', 'groupe_sanguin' => 's', 'sexe' => 's',
        'date_naissance' => 's', 'latitude' => 'd', 'longitude' => 'd'
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
        $sql = "UPDATE patient SET " . implode(', ', $updateFields) . " WHERE id_patient = ?";
        $stmt = $conn->prepare($sql);

        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }

        $updateValues[] = $id_patient;
        $types .= 'i'; // for id_patient

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