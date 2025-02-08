<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'db_connection.php';

// Get parameters
$id_doc = $_POST['id_doc'];
$id_patient = $_POST['id_patient'];

// Start transaction
$conn->begin_transaction();

// Get parameters
$id_doc = $_POST['id_doc'];
$id_patient = $_POST['id_patient'];

// Start transaction

try {
    // Get the 'visite' service type ID
    $sql_service = "SELECT id_service_type FROM service_types WHERE nom = 'visite'";
    $result_service = $conn->query($sql_service);
    
    if ($result_service->num_rows == 0) {
        throw new Exception("Service type 'visite' not found");
    }
    
    $row_service = $result_service->fetch_assoc();
    $id_service_type = $row_service['id_service_type'];

    // Get the doctor's service price
    $sql_price = "SELECT id_doctor_service, COALESCE(custom_price, fixed_price) AS price 
                  FROM doctor_services 
                  JOIN service_types USING (id_service_type)
                  WHERE id_doc = ? AND id_service_type = ?";
    $stmt_price = $conn->prepare($sql_price);
    $stmt_price->bind_param("ii", $id_doc, $id_service_type);
    $stmt_price->execute();
    $result_price = $stmt_price->get_result();
    
    if ($result_price->num_rows == 0) {
        throw new Exception("Price for 'visite' service not found for this doctor");
    }
    
    $row_price = $result_price->fetch_assoc();
    $id_doctor_service = $row_price['id_doctor_service'];
    $price = $row_price['price'];

    // Book appointment
    $current_datetime = date('Y-m-d H:i:s');
    $sql_appointment = "INSERT INTO rendez_vous (id_doc, id_patient, id_doctor_service, date_heure_rendez_vous, statut) 
                        VALUES (?, ?, ?, ?, 'en_attente')";
    $stmt_appointment = $conn->prepare($sql_appointment);
    $stmt_appointment->bind_param("iiis", $id_doc, $id_patient, $id_doctor_service, $current_datetime);
    $stmt_appointment->execute();

    // Commit transaction
    $conn->commit();

    echo json_encode(["success" => true, "message" => "Appointment booked successfully", "price" => $price]);
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Error booking appointment: " . $e->getMessage()]);
}

$conn->close();
?>