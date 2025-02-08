<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token, Authorization');
header('Content-Type: application/json');

require_once 'db_connection.php';

// Get request parameters
$requestId = $_GET['requestId'] ?? null;
$patientLat = $_GET['patientLat'] ?? null;
$patientLon = $_GET['patientLon'] ?? null;

if (!$requestId || !$patientLat || !$patientLon) {
    echo json_encode([
        'success' => false,
        'message' => 'Missing required parameters'
    ]);
    exit;
}

try {
    // Updated to use garde_malade_requests table instead of doctor_requests
    $stmt = $conn->prepare("
        SELECT gmr.*, p.id_patient, p.numero_telephone
        FROM garde_malade_requests gmr
        JOIN patient p ON gmr.id_patient = p.id_patient
        WHERE gmr.id_request = ?
    ");
    $stmt->bind_param('i', $requestId);  
    $stmt->execute();
    $request = $stmt->get_result()->fetch_assoc();

    if (!$request) {
        echo json_encode([
            'success' => false,
            'message' => 'Request not found'
        ]);
        exit;
    }

    // Find nearby active garde malades within 10km radius
    $sql = "
        SELECT 
            d.*,
            (6371 * acos(
                cos(radians(?)) * 
                cos(radians(d.Latitude)) * 
                cos(radians(d.longitude) - radians(?)) + 
                sin(radians(?)) * 
                sin(radians(d.Latitude))
            )) AS distance
        FROM docteur d
        WHERE d.status = 'active' 
            AND d.est_banni = 0 
            AND d.est_gm = 1
        HAVING distance <= 10
        ORDER BY distance
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param('ddd', $patientLat, $patientLon, $patientLat);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $garde_malades = [];
    while ($gm = $result->fetch_assoc()) {
        $garde_malades[] = [
            'id' => $gm['id_doc'],
            'name' => $gm['nom'] . ' ' . $gm['prenom'],
            'phone' => $gm['numero_telephone'],
            'photo' => $gm['photo_profil'],
            'distance' => round($gm['distance'], 2),
            'latitude' => $gm['Latitude'],
            'longitude' => $gm['longitude']
        ];
    }

    echo json_encode([
        'success' => true,
        'request' => [
            'id' => $request['id_request'],
            'patient_phone' => $request['numero_telephone']
        ],
        'garde_malades' => $garde_malades
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}