<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db_connection.php';

error_reporting(E_ALL);
ini_set('display_errors', 1);

// Handle GET request to fetch doctor details
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $doctorId = isset($_GET['id']) ? intval($_GET['id']) : null;    
    if (!$doctorId) {
        echo json_encode(['success' => false, 'message' => 'Doctor ID is required']);
        exit();
    }

    try {
        // Fetch doctor's basic information
        $stmt = $conn->prepare("
            SELECT d.*, ds.id_specialite, dss.id_sous_specialite 
            FROM docteur d 
            LEFT JOIN docteur_specialite ds ON d.id_doc = ds.id_doc
            LEFT JOIN docteur_sous_specialite dss ON d.id_doc = dss.id_doc
            WHERE d.id_doc = ?
        ");
        $stmt->bind_param("i", $doctorId);
        $stmt->execute();
        $result = $stmt->get_result();
        $doctor = $result->fetch_assoc();

        // Fetch doctor's services
        $stmt = $conn->prepare("
            SELECT ds.*, st.nom 
            FROM doctor_services ds
            JOIN service_types st ON ds.id_service_type = st.id_service_type
            WHERE ds.id_doc = ?
        ");
        $stmt->bind_param("i", $doctorId);
        $stmt->execute();
        $services = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

        echo json_encode([
            'success' => true,
            'doctor' => $doctor,
            'services' => $services
        ]);
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit();
}

// Handle POST request to update doctor
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw_data = file_get_contents('php://input');
    $data = json_decode($raw_data, true);
    
    if (!isset($data['id_doc'])) {
        echo json_encode(['success' => false, 'message' => 'Doctor ID is required']);
        exit();
    }

    try {
        $conn->begin_transaction();

        // Update docteur table
        $stmt = $conn->prepare("
            UPDATE docteur 
            SET nom=?, prenom=?, adresse=?, id_wilaya=?, id_commune=?, 
                adresse_email=?, numero_telephone=?, consultation_domicile=?, 
                consultation_cabinet=?, est_infirmier=?, est_gm=?, assistant=?, 
                status=?
            WHERE id_doc=?
        ");
        
        $stmt->bind_param("sssiissiiiiisi", 
            $data['nom'], 
            $data['prenom'], 
            $data['adresse'], 
            $data['id_wilaya'], 
            $data['id_commune'], 
            $data['adresse_email'],
            $data['numero_telephone'], 
            $data['consultation_domicile'], 
            $data['consultation_cabinet'], 
            $data['est_infirmier'], 
            $data['est_gm'], 
            $data['assistant'], 
            $data['status'],
            $data['id_doc']
        );
        $stmt->execute();

        // Update specialite
        $stmt = $conn->prepare("UPDATE docteur_specialite SET id_specialite=? WHERE id_doc=?");
        $stmt->bind_param("ii", $data['specialite'], $data['id_doc']);
        $stmt->execute();

        // Update sous_specialite
        if (isset($data['sous_specialite']) && $data['sous_specialite'] !== null) {
            $stmt = $conn->prepare("
                INSERT INTO docteur_sous_specialite (id_doc, id_sous_specialite) 
                VALUES (?, ?) 
                ON DUPLICATE KEY UPDATE id_sous_specialite=?
            ");
            $stmt->bind_param("iii", $data['id_doc'], $data['sous_specialite'], $data['sous_specialite']);
            $stmt->execute();
        }

        // Update services
        $stmt = $conn->prepare("DELETE FROM doctor_services WHERE id_doc=?");
        $stmt->bind_param("i", $data['id_doc']);
        $stmt->execute();

        $stmt = $conn->prepare("INSERT INTO doctor_services (id_doc, id_service_type, custom_price) VALUES (?, ?, ?)");
        foreach ($data['services'] as $service) {
            $stmt->bind_param("iid", $data['id_doc'], $service['id_service_type'], $service['price']);
            $stmt->execute();
        }

        $conn->commit();
        echo json_encode(['success' => true, 'message' => 'Doctor updated successfully']);
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
    }
}

$conn->close();
?>