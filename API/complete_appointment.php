<?php
include 'db_connection.php';
include 'error_log.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

function logError($message, $data = null) {
    $logMessage = date('Y-m-d H:i:s') . " - $message";
    if ($data !== null) {
        $logMessage .= " - Data: " . json_encode($data);
    }
    error_log($logMessage . PHP_EOL, 3, "error.log");
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id_rendez_vous = isset($_POST['id_rendez_vous']) ? intval($_POST['id_rendez_vous']) : 0;
    $id_doc = isset($_POST['id_doc']) ? intval($_POST['id_doc']) : 0;
    $id_doctor_service = isset($_POST['id_doctor_service']) ? intval($_POST['id_doctor_service']) : 0;

    logError("Received request", $_POST);

    if ($id_rendez_vous == 0 || $id_doc == 0 || $id_doctor_service == 0) {
        logError("Invalid appointment, doctor, or service ID", ['id_rendez_vous' => $id_rendez_vous, 'id_doc' => $id_doc, 'id_doctor_service' => $id_doctor_service]);
        echo json_encode(['success' => false, 'message' => 'Invalid appointment, doctor, or service ID']);
        exit;
    }

    $conn->begin_transaction();

    try {
        // Fetch the appointment details and price
        $sql = "SELECT r.id_doc, d.id_doctor_service, 
                COALESCE(d.custom_price, st.fixed_price) AS price
                FROM rendez_vous r
                JOIN doctor_services d ON r.id_doctor_service = d.id_doctor_service
                JOIN service_types st ON d.id_service_type = st.id_service_type
                WHERE r.id_rendez_vous = ? AND r.id_doc = ? AND d.id_doctor_service = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iii", $id_rendez_vous, $id_doc, $id_doctor_service);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows == 0) {
            throw new Exception("Appointment not found or details mismatch");
        }
        
        $row = $result->fetch_assoc();
        $montant = $row['price'];

        // Update appointment status
        $sql = "UPDATE rendez_vous SET statut = 'complete' WHERE id_rendez_vous = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id_rendez_vous);
        $result = $stmt->execute();
        if (!$result) {
            throw new Exception("Failed to update rendez_vous: " . $stmt->error);
        }

        // Update doctor status
        $sql = "UPDATE docteur SET status = 'active' WHERE id_doc = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id_doc);
        $result = $stmt->execute();
        if (!$result) {
            throw new Exception("Failed to update docteur status: " . $stmt->error);
        }

        // Insert payment record
        $sql = "INSERT INTO paiements (id_rendez_vous, montant, statut_paiement, methode_paiement) VALUES (?, ?, 'complete', 'cash')";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("id", $id_rendez_vous, $montant);
        $result = $stmt->execute();
        if (!$result) {
            throw new Exception("Failed to insert payment: " . $stmt->error);
        }

        $conn->commit();
        logError("Appointment completed successfully", ['id_rendez_vous' => $id_rendez_vous, 'id_doc' => $id_doc, 'montant' => $montant]);
        echo json_encode(['success' => true, 'message' => 'Appointment completed, doctor status updated, and payment recorded', 'amount' => $montant]);
    } catch (Exception $e) {
        $conn->rollback();
        logError("Failed to complete appointment: " . $e->getMessage(), ['id_rendez_vous' => $id_rendez_vous, 'id_doc' => $id_doc]);
        echo json_encode(['success' => false, 'message' => 'Failed to complete appointment: ' . $e->getMessage()]);
    }
} else {
    logError("Invalid request method: " . $_SERVER['REQUEST_METHOD']);
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>