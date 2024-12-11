<?php
header("Content-Type: application/json");
include "db_connection.php";

$patients = array();

$query = "
    SELECT 
        p.id_patient, 
        p.nom, 
        p.prenom, 
        p.numero_telephone, 
        p.adresse_email,
        COUNT(DISTINCT r.id_rendez_vous) as appointment_count,
        COALESCE(SUM(pa.montant), 0) as total_payment
    FROM 
        patient p
    LEFT JOIN 
        rendez_vous r ON p.id_patient = r.id_patient
    LEFT JOIN 
        paiements pa ON r.id_rendez_vous = pa.id_rendez_vous
    GROUP BY 
        p.id_patient
";

$result = mysqli_query($conn, $query);

if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $patients[] = $row;
    }
    echo json_encode(["success" => true, "patients" => $patients]);
} else {
    echo json_encode(["success" => false, "message" => "Error: " . mysqli_error($conn)]);
}

mysqli_close($conn);
?>