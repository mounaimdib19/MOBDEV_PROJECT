<?php
// Add these CORS headers
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
    // Get request details
    $stmt = $conn->prepare("
        SELECT dr.*, p.id_patient, p.numero_telephone
        FROM doctor_requests dr
        JOIN patient p ON dr.id_patient = p.id_patient
        WHERE dr.id_request = ?
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

    // Find nearby active doctors within 10km radius
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
        WHERE d.status = 'active' AND
        d.est_banni = 0 

        HAVING distance <= 10
        ORDER BY distance
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param('ddd', $patientLat, $patientLon, $patientLat);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $doctors = [];
    while ($doctor = $result->fetch_assoc()) {
        $doctors[] = [
            'id' => $doctor['id_doc'],
            'name' => $doctor['nom'] . ' ' . $doctor['prenom'],
            'phone' => $doctor['numero_telephone'],
            'photo' => $doctor['photo_profil'],
            'distance' => round($doctor['distance'], 2),
            'latitude' => $doctor['Latitude'],
            'longitude' => $doctor['longitude']
        ];
    }

    echo json_encode([
        'success' => true,
        'request' => [
            'id' => $request['id_request'],
            'patient_phone' => $request['numero_telephone']
        ],
        'doctors' => $doctors
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}