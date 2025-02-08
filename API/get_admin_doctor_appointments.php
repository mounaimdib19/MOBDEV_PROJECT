<?php
// get_admin_doctor_appointments.php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Content-Type: application/json; charset=UTF-8");

require_once 'db_connection.php';

// Get and sanitize the doctor ID from the URL
$id_doc = isset($_GET['id_doc']) ? $conn->real_escape_string($_GET['id_doc']) : null;

// Check if doctor ID was provided
if (!$id_doc) {
    echo json_encode(array("error" => "Doctor ID is required"));
    $conn->close();
    exit();
}

// Create the SQL query to fetch completed appointments with service type and payment information
$query = "
    SELECT 
        r.id_rendez_vous,
        r.date_heure_rendez_vous,
        p.nom,
        p.prenom,
        pay.montant,
        ds.custom_price,
        st.fixed_price,
        st.nom as service_name
    FROM 
        rendez_vous r
        INNER JOIN patient p ON r.id_patient = p.id_patient
        INNER JOIN doctor_services ds ON r.id_doctor_service = ds.id_doctor_service
        INNER JOIN service_types st ON ds.id_service_type = st.id_service_type
        LEFT JOIN paiements pay ON r.id_rendez_vous = pay.id_rendez_vous
    WHERE 
        r.id_doc = ?
        AND r.statut = 'complete'
    ORDER BY 
        r.date_heure_rendez_vous DESC";

// Prepare and execute the query using prepared statement
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $id_doc);
$stmt->execute();
$result = $stmt->get_result();

// Check if the query was successful
if ($result) {
    $appointments = array();
    
    // Fetch all appointments
    while ($row = $result->fetch_assoc()) {
        // Format the date
        $date = new DateTime($row['date_heure_rendez_vous']);
        $formatted_date = $date->format('Y-m-d H:i:s');
        
        // Build the appointment data
        $appointment = array(
            'id_rendez_vous' => $row['id_rendez_vous'],
            'nom' => $row['nom'],
            'prenom' => $row['prenom'],
            'date_heure_rendez_vous' => $formatted_date,
            'montant' => $row['montant'] ?? ($row['custom_price'] ?? $row['fixed_price']),
            'service_name' => $row['service_name']
        );
        
        $appointments[] = $appointment;
    }
    
    // Return the appointments as JSON
    echo json_encode($appointments);
} else {
    // Handle query error
    echo json_encode(array("error" => "Error fetching appointments: " . $conn->error));
}

// Close the statement and connection
$stmt->close();
$conn->close();
?>