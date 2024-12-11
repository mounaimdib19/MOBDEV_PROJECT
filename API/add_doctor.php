<?php
include 'db_connection.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"));

    if (
        !empty($data->nom) &&
        !empty($data->prenom) &&
        !empty($data->adresse) &&
        !empty($data->wilaya) &&
        !empty($data->commune) &&
        !empty($data->adresse_email) &&
        !empty($data->mot_de_passe) &&
        !empty($data->status) &&
        !empty($data->specialite)
    ) {
        $sql = "INSERT INTO docteur 
                (nom, prenom, adresse, id_wilaya, id_commune, adresse_email, mot_de_passe, consultation_domicile, consultation_cabinet, est_infirmier, est_gm, status)
                VALUES (?, ?, ?, 
                    (SELECT id_wilaya FROM wilaya WHERE nom_wilaya = ?), 
                    (SELECT id_commune FROM commune WHERE nom_commune = ?), 
                    ?, ?, ?, ?, ?, ?, ?)";

        $stmt = $conn->prepare($sql);
        $hashed_password = password_hash($data->mot_de_passe, PASSWORD_DEFAULT);
        $stmt->bind_param("sssssssiiiis", 
            $data->nom, 
            $data->prenom, 
            $data->adresse, 
            $data->wilaya, 
            $data->commune, 
            $data->adresse_email, 
            $hashed_password, 
            $data->consultation_domicile, 
            $data->consultation_cabinet, 
            $data->est_infirmier, 
            $data->est_gm, 
            $data->status
        );

        if ($stmt->execute()) {
            $doctor_id = $conn->insert_id;

            // Insert speciality
            $spec_sql = "INSERT INTO docteur_specialite (id_doc, id_specialite) 
                         VALUES (?, (SELECT id_specialite FROM specialite WHERE nom_specialite = ?))";
            $spec_stmt = $conn->prepare($spec_sql);
            $spec_stmt->bind_param("is", $doctor_id, $data->specialite);
            $spec_stmt->execute();

            // Insert sub-speciality if provided
            if (!empty($data->sous_specialite)) {
                $sub_spec_sql = "INSERT INTO docteur_sous_specialite (id_doc, id_sous_specialite) 
                                 VALUES (?, (SELECT id_sous_specialite FROM sous_specialite WHERE nom_sous_specialite = ?))";
                $sub_spec_stmt = $conn->prepare($sub_spec_sql);
                $sub_spec_stmt->bind_param("is", $doctor_id, $data->sous_specialite);
                $sub_spec_stmt->execute();
            }

            $response = [
                'success' => true,
                'message' => 'Doctor was added successfully.'
            ];
        } else {
            $response = [
                'success' => false,
                'message' => 'Unable to add doctor.'
            ];
        }
    } else {
        $response = [
            'success' => false,
            'message' => 'Unable to add doctor. Data is incomplete.'
        ];
    }

    echo json_encode($response);
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request method']);
}

$conn->close();
?>