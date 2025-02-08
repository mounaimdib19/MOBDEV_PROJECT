<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('HTTP/1.1 204 No Content');
    exit;
}

header('Content-Type: application/json');
require_once 'db_connection.php';

$requestId = $_POST['requestId'] ?? null;
$gardeMaladeId = $_POST['gardeMaladeId'] ?? null;

if (!$requestId || !$gardeMaladeId) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameters'
    ]);
    exit;
}

try {
    $conn->begin_transaction();

    $patientStmt = $conn->prepare("SELECT id_patient FROM garde_malade_requests WHERE id_request = ?");
    $patientStmt->bind_param('i', $requestId);
    $patientStmt->execute();
    $patientResult = $patientStmt->get_result();
    $patientData = $patientResult->fetch_assoc();
    
    if (!$patientData) {
        throw new Exception('Patient not found for this request');
    }
    $patientId = $patientData['id_patient'];

    $insertAssignmentStmt = $conn->prepare("
        INSERT INTO garde_malade_assignment (id_request, id_gm, assignment_date) 
        VALUES (?, ?, NOW())
    ");
    $insertAssignmentStmt->bind_param('ii', $requestId, $gardeMaladeId);
    $insertAssignmentStmt->execute();

    // Update garde malade status to inactive
    $updateGMStatus = $conn->prepare("
        UPDATE docteur 
        SET status = 'inactive'
        WHERE id_doc = ?
    ");
    $updateGMStatus->bind_param('i', $gardeMaladeId);
    $updateGMStatus->execute();

    $gmServiceStmt = $conn->prepare("
        SELECT id_doctor_service 
        FROM doctor_services 
        WHERE id_doc = ? AND id_service_type = 22
    ");
    $gmServiceStmt->bind_param('i', $gardeMaladeId);
    $gmServiceStmt->execute();
    $gmServiceResult = $gmServiceStmt->get_result();
    $gmServiceData = $gmServiceResult->fetch_assoc();
    
    if (!$gmServiceData) {
        throw new Exception('Garde malade service not found for this provider');
    }
    
    $gmServiceId = $gmServiceData['id_doctor_service'];

    $updateRequestStmt = $conn->prepare("
        UPDATE garde_malade_requests 
        SET status = 'assigned'
        WHERE id_request = ? AND status = 'pending'
    ");
    $updateRequestStmt->bind_param('i', $requestId);
    $updateRequestStmt->execute();

    if ($updateRequestStmt->affected_rows === 0) {
        throw new Exception('Request already assigned or not found');
    }

    $rendezVousStmt = $conn->prepare("
        INSERT INTO rendez_vous 
        (id_doc, id_patient, id_doctor_service, date_heure_rendez_vous, statut) 
        VALUES (?, ?, ?, NOW(), 'accepte')
    ");
    $rendezVousStmt->bind_param('iii', $gardeMaladeId, $patientId, $gmServiceId);
    $rendezVousStmt->execute();

    $conn->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Garde malade assigned successfully'
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}