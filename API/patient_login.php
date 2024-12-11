<?php
include 'db_connection.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $numero_telephone = $_POST['numero_telephone'];

    // Comprehensive phone number validation
    if (empty($numero_telephone)) {
        $response = ['success' => false, 'message' => 'Phone number is required'];
        echo json_encode($response);
        exit;
    }

    // Check if contains only digits
    if (!preg_match('/^[0-9]+$/', $numero_telephone)) {
        $response = ['success' => false, 'message' => 'Phone number must contain only digits'];
        echo json_encode($response);
        exit;
    }

    // Check length
    if (strlen($numero_telephone) !== 10) {
        $response = ['success' => false, 'message' => 'Phone number must be exactly 10 digits'];
        echo json_encode($response);
        exit;
    }

    // Check prefix (must start with 07, 06, or 05)
    if (!preg_match('/^(07|06|05)/', $numero_telephone)) {
        $response = ['success' => false, 'message' => 'Phone number must start with 07, 06, or 05'];
        echo json_encode($response);
        exit;
    }

    // If all validation passes, proceed with database operations
    $sql = "SELECT * FROM patient WHERE numero_telephone = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $numero_telephone);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 1) {
        $patient = $result->fetch_assoc();
        // Phone number exists, login successful
        $response = [
            'success' => true,
            'message' => 'Login successful',
            'id_patient' => (int)$patient['id_patient']
        ];
    } else {
        // Phone number not found, create new patient account
        $sql_insert = "INSERT INTO patient (numero_telephone, date_naissance, latitude, longitude) VALUES (?, CURRENT_DATE, 0, 0)";
        $stmt_insert = $conn->prepare($sql_insert);
        $stmt_insert->bind_param("s", $numero_telephone);
        
        if ($stmt_insert->execute()) {
            $new_patient_id = $stmt_insert->insert_id;
            $response = [
                'success' => true,
                'message' => 'New account created',
                'id_patient' => $new_patient_id
            ];
        } else {
            $response = [
                'success' => false,
                'message' => 'Error creating account'
            ];
        }
    }

    echo json_encode($response);
}
?>