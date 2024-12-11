<?php
header('Content-Type: application/json');
include 'db_connection.php';

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Log incoming data
$raw_data = file_get_contents('php://input');
error_log("Received data: " . $raw_data);

$data = json_decode($raw_data, true);

// Log decoded data
error_log("Decoded data: " . print_r($data, true));

try {
    $conn->begin_transaction();

    // Insert into docteur table
    $stmt = $conn->prepare("INSERT INTO docteur (nom, prenom, adresse, id_wilaya, id_commune, adresse_email, mot_de_passe, numero_telephone, consultation_domicile, consultation_cabinet, est_infirmier, est_gm, assistant, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("sssiisssiiiiis", 
        $data['nom'], 
        $data['prenom'], 
        $data['adresse'], 
        $data['id_wilaya'], 
        $data['id_commune'], 
        $data['adresse_email'], 
        $data['mot_de_passe'], 
        $data['numero_telephone'], 
        $data['consultation_domicile'], 
        $data['consultation_cabinet'], 
        $data['est_infirmier'], 
        $data['est_gm'], 
        $data['assistant'], 
        $data['status']
    );
    $stmt->execute();
    $doctorId = $conn->insert_id;

    // Log the inserted doctor data
    error_log("Inserted doctor with ID: " . $doctorId);

    // Insert into docteur_specialite table
    $stmt = $conn->prepare("INSERT INTO docteur_specialite (id_doc, id_specialite) VALUES (?, ?)");
    $stmt->bind_param("ii", $doctorId, $data['specialite']);
    $stmt->execute();

    // Insert into docteur_sous_specialite table if sous_specialite is provided
    if (isset($data['sous_specialite']) && $data['sous_specialite'] !== null) {
        $stmt = $conn->prepare("INSERT INTO docteur_sous_specialite (id_doc, id_sous_specialite) VALUES (?, ?)");
        $stmt->bind_param("ii", $doctorId, $data['sous_specialite']);
        $stmt->execute();
    }

    // Insert into doctor_services table
    $stmt = $conn->prepare("INSERT INTO doctor_services (id_doc, id_service_type, custom_price) VALUES (?, ?, ?)");
    foreach ($data['services'] as $service) {
        $stmt->bind_param("iid", $doctorId, $service['id_service_type'], $service['price']);
        $stmt->execute();
    }

    $conn->commit();
    echo json_encode(['success' => true, 'message' => 'Doctor added successfully']);
} catch (Exception $e) {
    $conn->rollback();
    error_log("Error in add_doctor_with_services.php: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}

$conn->close();
?>