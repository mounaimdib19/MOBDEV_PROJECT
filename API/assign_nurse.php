// assign_nurse.php
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
$nurseId = $_POST['id_doc'] ?? null;

if (!$requestId || !$nurseId) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameters'
    ]);
    exit;
}

try {
    $conn->begin_transaction();

    $requestStmt = $conn->prepare("
        SELECT id_patient, id_service_type 
        FROM nurse_assistance_requests 
        WHERE id_request = ?
    ");
    $requestStmt->bind_param('i', $requestId);
    $requestStmt->execute();
    $requestResult = $requestStmt->get_result();
    $requestData = $requestResult->fetch_assoc();
    
    if (!$requestData) {
        throw new Exception('Request not found');
    }
    
    $patientId = $requestData['id_patient'];
    $serviceTypeId = $requestData['id_service_type'];

    $nurseCheckStmt = $conn->prepare("
        SELECT id_doc FROM docteur 
        WHERE id_doc = ? AND status = 'active'
    ");
    $nurseCheckStmt->bind_param('i', $nurseId);
    $nurseCheckStmt->execute();
    if ($nurseCheckStmt->get_result()->num_rows === 0) {
        throw new Exception('Nurse not found or inactive');
    }

    $insertAssignmentStmt = $conn->prepare("
        INSERT INTO nurse_assignment (id_request, id_nurse, assignment_date) 
        VALUES (?, ?, NOW())
    ");
    $insertAssignmentStmt->bind_param('ii', $requestId, $nurseId);
    $insertAssignmentStmt->execute();

    // Update nurse status to inactive
    $updateNurseStatus = $conn->prepare("
        UPDATE docteur 
        SET status = 'inactive'
        WHERE id_doc = ?
    ");
    $updateNurseStatus->bind_param('i', $nurseId);
    $updateNurseStatus->execute();

    $nurseServiceStmt = $conn->prepare("
        SELECT id_doctor_service 
        FROM doctor_services 
        WHERE id_doc = ? AND id_service_type = ?
    ");
    $nurseServiceStmt->bind_param('ii', $nurseId, $serviceTypeId);
    $nurseServiceStmt->execute();
    $nurseServiceResult = $nurseServiceStmt->get_result();
    $nurseServiceData = $nurseServiceResult->fetch_assoc();
    
    if (!$nurseServiceData) {
        throw new Exception('Nurse service not found for this nurse');
    }
    
    $nurseServiceId = $nurseServiceData['id_doctor_service'];

    $updateRequestStmt = $conn->prepare("
        UPDATE nurse_assistance_requests 
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
    $rendezVousStmt->bind_param('iii', $nurseId, $patientId, $nurseServiceId);
    $rendezVousStmt->execute();

    $conn->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Nurse assigned successfully',
        'patientId' => $patientId,
        'nurseServiceId' => $nurseServiceId
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}