<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'db_connection.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['id_doc']) && !empty($_GET['id_doc'])) {
        $id_doc = $_GET['id_doc'];
        
        $query = "SELECT ar.id_request, ar.numero_telephone, ar.description, ar.statut, ar.cree_le,
                         p.nom AS patient_name, p.prenom AS patient_surname
                  FROM assistance_requests ar
                  LEFT JOIN doctor_assignments da ON ar.id_request = da.id_request
                  LEFT JOIN patient p ON ar.numero_telephone = p.numero_telephone
                  WHERE da.id_doc = ? AND ar.statut != 'complete'
                  ORDER BY ar.cree_le DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $id_doc);
        
        if ($stmt->execute()) {
            $result = $stmt->get_result();
            $requests = array();
            
            while ($row = $result->fetch_assoc()) {
                $requests[] = array(
                    'id_request' => $row['id_request'],
                    'patient_name' => $row['patient_name'] . ' ' . $row['patient_surname'],
                    'patient_phone' => $row['numero_telephone'],
                    'reason' => $row['description'],
                    'status' => $row['statut'],
                    'request_datetime' => $row['cree_le']
                );
            }
            
            $response['success'] = true;
            $response['requests'] = $requests;
        } else {
            $response['success'] = false;
            $response['message'] = "Failed to fetch assistance requests.";
        }
        
        $stmt->close();
    } else {
        $response['success'] = false;
        $response['message'] = "Doctor ID is required.";
    }
} else {
    $response['success'] = false;
    $response['message'] = "Invalid request method.";
}

echo json_encode($response);
$conn->close();
?>