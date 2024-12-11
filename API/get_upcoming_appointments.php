<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $id_doc = $_GET['id_doc'];

    $sql = "SELECT 
        r.id_rendez_vous,
        r.statut,
        p.nom AS patient_name,
        p.prenom AS patient_surname,
        p.numero_telephone AS patient_phone,
        st.nom AS service_name,
        r.date_heure_rendez_vous
      FROM rendez_vous r
      JOIN patient p ON r.id_patient = p.id_patient
      JOIN doctor_services ds ON r.id_doctor_service = ds.id_doctor_service
      JOIN service_types st ON ds.id_service_type = st.id_service_type
      WHERE r.id_doc = ? 
        AND r.statut IN ('en_attente', 'accepte')
      ORDER BY r.date_heure_rendez_vous ASC";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id_doc);
    $stmt->execute();
    $result = $stmt->get_result();

    $appointments = array();
    while ($row = $result->fetch_assoc()) {
        $appointments[] = array(
            'id_rendez_vous' => $row['id_rendez_vous'],
            'statut' => $row['statut'],
            'patient_name' => $row['patient_name'] . ' ' . $row['patient_surname'],
            'patient_phone' => $row['patient_phone'],
            'service_name' => $row['service_name'],
            'appointment_datetime' => $row['date_heure_rendez_vous']
        );
    }

    $response = array(
        'success' => true,
        'appointments' => $appointments
    );

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>