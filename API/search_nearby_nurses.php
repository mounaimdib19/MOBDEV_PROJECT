<?php
// Prevent any HTML error output
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);
ini_set('error_log', 'nurse_search_errors.log');

// Add these CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
header('Content-Type: application/json');

function sendResponse($success, $message = null, $nurses = [], $request = null) {
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'nurses' => $nurses,
        'request' => $request,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    exit;
}

function logError($message, $context = []) {
    error_log("Nurse Search Error: $message " . json_encode($context));
}

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    require_once 'db_connection.php';
    
    // Validate required parameters
    $requestId = $_GET['requestId'] ?? null;
    $patientLat = $_GET['patientLat'] ?? null;
    $patientLon = $_GET['patientLon'] ?? null;
    $serviceTypeId = $_GET['serviceTypeId'] ?? null;

    // Log incoming parameters
    error_log("Incoming parameters: " . json_encode($_GET));

    if (!$requestId || !$patientLat || !$patientLon || !$serviceTypeId) {
        sendResponse(false, 'Missing required parameters', [], null);
    }

    // Validate numeric values
    if (!is_numeric($patientLat) || !is_numeric($patientLon) || !is_numeric($serviceTypeId)) {
        logError('Invalid parameter types', $_GET);
        sendResponse(false, null, 'Invalid parameter types');
    }

    // Get request details
    $stmt = $conn->prepare("
        SELECT nr.*, p.id_patient, p.numero_telephone
        FROM nurse_assistance_requests nr
        JOIN patient p ON nr.id_patient = p.id_patient
        WHERE nr.id_request = ?
    ");
    
    if (!$stmt) {
        logError('Failed to prepare request details query', ['error' => $conn->error]);
        sendResponse(false, null, 'Database error');
    }

    $stmt->bind_param('i', $requestId);
    
    if (!$stmt->execute()) {
        logError('Failed to execute request details query', ['error' => $stmt->error]);
        sendResponse(false, null, 'Database error');
    }

    $request = $stmt->get_result()->fetch_assoc();
    
    if (!$request) {
        sendResponse(false, null, 'Request not found');
    }

    // Find nearby nurses
    $sql = "
        SELECT 
            d.id_doc,
            d.nom,
            d.prenom,
            d.numero_telephone,
            d.photo_profil,
            d.Latitude,
            d.longitude,
            (6371 * acos(
                cos(radians(?)) * 
                cos(radians(d.Latitude)) * 
                cos(radians(d.longitude) - radians(?)) + 
                sin(radians(?)) * 
                sin(radians(d.Latitude))
            )) AS distance
        FROM docteur d
        INNER JOIN doctor_services ds ON d.id_doc = ds.id_doc
        INNER JOIN service_types st ON ds.id_service_type = st.id_service_type
        WHERE 
            d.status = 'active' AND 
            d.est_banni = 0 AND

            st.id_service_type = ? AND 
            (6371 * acos(
                cos(radians(?)) * 
                cos(radians(d.Latitude)) * 
                cos(radians(d.longitude) - radians(?)) + 
                sin(radians(?)) * 
                sin(radians(d.Latitude))
            )) <= 10
        ORDER BY distance
        LIMIT 10
    ";

    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        logError('Failed to prepare nearby nurses query', ['error' => $conn->error]);
        sendResponse(false, null, 'Database error');
    }

    $stmt->bind_param('dddiddd', 
        $patientLat, 
        $patientLon, 
        $patientLat, 
        $serviceTypeId,
        $patientLat,
        $patientLon,
        $patientLat
    );

    if (!$stmt->execute()) {
        logError('Failed to execute nearby nurses query', ['error' => $stmt->error]);
        sendResponse(false, null, 'Database error');
    }

    $result = $stmt->get_result();
    $nurses = [];

    while ($nurse = $result->fetch_assoc()) {
        $nurses[] = [
            'id_doc' => $nurse['id_doc'],
            'name' => $nurse['nom'] . ' ' . $nurse['prenom'],
            'phone' => $nurse['numero_telephone'],
            'photo' => $nurse['photo_profil'],
            'distance' => round($nurse['distance'], 2),
            'latitude' => $nurse['Latitude'],
            'longitude' => $nurse['longitude']
        ];
    }

    sendResponse(true, null, $nurses, [
        'id' => $request['id_request'],
        'patient_phone' => $request['numero_telephone']
    ]);

} catch (Exception $e) {
    logError('Unexpected error', [
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
    
    sendResponse(false, null, 'An unexpected error occurred');
}