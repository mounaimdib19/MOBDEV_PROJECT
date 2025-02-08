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
$doctorId = $_POST['doctorId'] ?? null;

if (!$requestId || !$doctorId) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameters'
    ]);
    exit;
}

try {
    $conn->begin_transaction();

    $patientStmt = $conn->prepare("SELECT id_patient FROM doctor_requests WHERE id_request = ?");
    $patientStmt->bind_param('i', $requestId);
    $patientStmt->execute();
    $patientResult = $patientStmt->get_result();
    $patientData = $patientResult->fetch_assoc();
    
    if (!$patientData) {
        throw new Exception('Patient not found for this request');
    }
    $patientId = $patientData['id_patient'];

    $insertAssignmentStmt = $conn->prepare("
        INSERT INTO doctor_assignment (id_request, id_doc, assignment_date) 
        VALUES (?, ?, NOW())
    ");
    $insertAssignmentStmt->bind_param('ii', $requestId, $doctorId);
    $insertAssignmentStmt->execute();

    // Update doctor status to inactive
    $updateDoctorStatus = $conn->prepare("
        UPDATE docteur 
        SET status = 'inactive'
        WHERE id_doc = ?
    ");
    $updateDoctorStatus->bind_param('i', $doctorId);
    $updateDoctorStatus->execute();

    $serviceTypeStmt = $conn->prepare("SELECT id_service_type FROM service_types WHERE id_service_type = 1");
    $serviceTypeStmt->execute();
    $serviceTypeResult = $serviceTypeStmt->get_result();
    
    if ($serviceTypeResult->num_rows === 0) {
        throw new Exception('Doctor visitation service type not found');
    }

    $doctorServiceStmt = $conn->prepare("
        SELECT id_doctor_service 
        FROM doctor_services 
        WHERE id_doc = ? AND id_service_type = 1
    ");
    $doctorServiceStmt->bind_param('i', $doctorId);
    $doctorServiceStmt->execute();
    $doctorServiceResult = $doctorServiceStmt->get_result();
    $doctorServiceData = $doctorServiceResult->fetch_assoc();
    
    if (!$doctorServiceData) {
        throw new Exception('Doctor service for visitation not found for this doctor');
    }
    
    $doctorServiceId = $doctorServiceData['id_doctor_service'];

    $updateRequestStmt = $conn->prepare("
        UPDATE doctor_requests 
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
    $rendezVousStmt->bind_param('iii', $doctorId, $patientId, $doctorServiceId);
    $rendezVousStmt->execute();

    $conn->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Doctor assigned successfully',
        'patientId' => $patientId,
        'doctorServiceId' => $doctorServiceId
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}