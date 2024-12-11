SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

CREATE DATABASE IF NOT EXISTS mabase;
USE mabase;

-- Table Wilaya
CREATE TABLE IF NOT EXISTS `wilaya` (
  `id_wilaya` int(2) NOT NULL,
  `nom_wilaya` varchar(20) NOT NULL,
  PRIMARY KEY (`id_wilaya`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Commune
CREATE TABLE IF NOT EXISTS `commune` (
  `id_commune` int(5) NOT NULL,
  `nom_commune` varchar(50) NOT NULL,
  `id_wilaya` int(10) NOT NULL,
  PRIMARY KEY (`id_commune`),
  FOREIGN KEY (`id_wilaya`) REFERENCES `wilaya`(`id_wilaya`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Administrateur
CREATE TABLE IF NOT EXISTS `administrateur` (
  `id_admin` int(10) NOT NULL AUTO_INCREMENT,
  `nom` varchar(25) NOT NULL,
  `prenom` varchar(25) NOT NULL,
  `adresse_email` varchar(25) NOT NULL,
  `mot_de_passe` varchar(255) NOT NULL,
  `statut` varchar(10) DEFAULT NULL,
  `type` ENUM('admin', 'superadmin') NOT NULL,
  `photo_profil` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id_admin`),
  UNIQUE KEY `adresse_email` (`adresse_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `docteur` (
  `id_doc` int(10) NOT NULL AUTO_INCREMENT,
  `nom` varchar(50) NOT NULL,
  `prenom` varchar(50) NOT NULL,  
  `adresse` varchar(150) DEFAULT NULL,
  `id_wilaya` int(10) DEFAULT NULL,
  `id_commune` int(10) DEFAULT NULL,
  `adresse_email` varchar(50) NOT NULL,
  `mot_de_passe` varchar(255) NOT NULL,
  `numero_telephone` varchar(13) DEFAULT NULL,
  `consultation_domicile` BOOLEAN NOT NULL DEFAULT FALSE,
  `consultation_cabinet` BOOLEAN NOT NULL DEFAULT FALSE,
  `est_infirmier` BOOLEAN NOT NULL DEFAULT FALSE,
  `est_gm` BOOLEAN NOT NULL DEFAULT FALSE,
  `assistant` BOOLEAN NOT NULL DEFAULT FALSE,
  `prix_consultation` int(10) DEFAULT NULL,
  `photo_profil` VARCHAR(255) DEFAULT NULL,
  `Latitude` DECIMAL(9, 6) DEFAULT NULL,
  `longitude` DECIMAL(9, 6) DEFAULT NULL,
  `status` ENUM('active', 'inactive') NOT NULL DEFAULT 'inactive',



  PRIMARY KEY (`id_doc`),
  FOREIGN KEY (`id_wilaya`) REFERENCES `wilaya`(`id_wilaya`),
  FOREIGN KEY (`id_commune`) REFERENCES `commune`(`id_commune`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Horaires
CREATE TABLE IF NOT EXISTS `horaires` (
  `id_horaire` int(10) NOT NULL AUTO_INCREMENT,
  `id_doc` int(10) NOT NULL,
  `jour` ENUM('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche') NOT NULL,
  `ouverture` time NOT NULL,
  `fermeture` time NOT NULL,
  `statut` ENUM('actif', 'inactif') NOT NULL DEFAULT 'actif',
  PRIMARY KEY (`id_horaire`),
  FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`),
  UNIQUE KEY `unique_doctor_day` (`id_doc`, `jour`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Spécialité
CREATE TABLE IF NOT EXISTS `specialite` (
  `id_specialite` int(10) NOT NULL AUTO_INCREMENT,
  `nom_specialite` varchar(50) NOT NULL,
  PRIMARY KEY (`id_specialite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Sous-spécialité
CREATE TABLE IF NOT EXISTS `sous_specialite` (
  `id_sous_specialite` int(10) NOT NULL AUTO_INCREMENT,
  `nom_sous_specialite` varchar(50) NOT NULL,
  `specialite_parent` int(10) NOT NULL,
  PRIMARY KEY (`id_sous_specialite`),
  FOREIGN KEY (`specialite_parent`) REFERENCES `specialite`(`id_specialite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Badges
CREATE TABLE IF NOT EXISTS `badges` (
    `id_badge` int(10) NOT NULL AUTO_INCREMENT,
    `nom_badge` varchar(50) NOT NULL,
    PRIMARY KEY (`id_badge`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Badge_docteur (relation many-to-many)
CREATE TABLE IF NOT EXISTS `badge_docteur` (
    `id_badge` int(10) NOT NULL,
    `id_doc` int(10) NOT NULL,
    PRIMARY KEY (`id_badge`,`id_doc`),
    FOREIGN KEY (`id_badge`) REFERENCES `badges`(`id_badge`),
    FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Patient
CREATE TABLE IF NOT EXISTS `patient` (
  `id_patient` int(10) NOT NULL AUTO_INCREMENT,
  `nom` varchar(50) DEFAULT NULL,
  `prenom` varchar(50) DEFAULT NULL,
  `adresse` varchar(250) DEFAULT NULL,
  `numero_telephone` VARCHAR(10)  NOT NULL,
  `wilaya` varchar(25) DEFAULT NULL,
  `commune` varchar(20) DEFAULT NULL,
  `parent_nom` varchar(20) DEFAULT NULL,
  `parent_num` int(20) DEFAULT NULL,
  `adresse_email` varchar(50) DEFAULT NULL,
  `mot_de_passe` varchar(255) DEFAULT NULL,
  `groupe_sanguin` varchar(20) DEFAULT NULL,
  `sexe` varchar(10) DEFAULT NULL,
  `date_naissance` date NOT NULL,
  `photo_profil` VARCHAR(255) DEFAULT NULL,
  `latitude` DECIMAL(9, 6) NOT NULL,
  `longitude` DECIMAL(9, 6) NOT NULL,
  PRIMARY KEY (`id_patient`),
  KEY `adresse_email` (`adresse_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Docteur_specialite (relation many-to-many)
CREATE TABLE IF NOT EXISTS `docteur_specialite` (
  `id_doc` int(10) NOT NULL,
  `id_specialite` int(10) NOT NULL,
  PRIMARY KEY (`id_doc`, `id_specialite`),
  FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`),
  FOREIGN KEY (`id_specialite`) REFERENCES `specialite`(`id_specialite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table Docteur_sous_specialite (relation many-to-many)
CREATE TABLE IF NOT EXISTS `docteur_sous_specialite` (
  `id_doc` int(10) NOT NULL,
  `id_sous_specialite` int(10) NOT NULL,
  PRIMARY KEY (`id_doc`, `id_sous_specialite`),
  FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`),
  FOREIGN KEY (`id_sous_specialite`) REFERENCES `sous_specialite`(`id_sous_specialite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for general service types
CREATE TABLE IF NOT EXISTS `service_types` (
  `id_service_type` int(10) NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) NOT NULL,
  `has_fixed_price` BOOLEAN NOT NULL DEFAULT TRUE,
  `fixed_price` DECIMAL(10, 2),
  `picture_url` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id_service_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for doctor-specific services
CREATE TABLE IF NOT EXISTS `doctor_services` (
  `id_doctor_service` int(10) NOT NULL AUTO_INCREMENT,
  `id_doc` int(10) NOT NULL,
  `id_service_type` int(10) NOT NULL,
  `custom_price` DECIMAL(10, 2),
  PRIMARY KEY (`id_doctor_service`),
  FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`),
  FOREIGN KEY (`id_service_type`) REFERENCES `service_types`(`id_service_type`),
  UNIQUE KEY `unique_doctor_service` (`id_doc`, `id_service_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Updated Rendez-vous table
CREATE TABLE IF NOT EXISTS `rendez_vous` (
  `id_rendez_vous` int(10) NOT NULL AUTO_INCREMENT,
  `id_doc` int(10) NOT NULL,
  `id_patient` int(10) NOT NULL,
  `id_doctor_service` int(10) NOT NULL,
  `date_heure_rendez_vous` DATETIME NOT NULL,
  `motif_consultation` TEXT,
  `statut` ENUM( 'accepte', 'annule', 'attente_completion','complete') NOT NULL DEFAULT 'accepte',
  `cree_le` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `mis_a_jour_le` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_rendez_vous`),
  FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`),
  FOREIGN KEY (`id_patient`) REFERENCES `patient`(`id_patient`),
  FOREIGN KEY (`id_doctor_service`) REFERENCES `doctor_services`(`id_doctor_service`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table Paiements
CREATE TABLE IF NOT EXISTS `paiements` (
  `id_paiement` int(10) NOT NULL AUTO_INCREMENT,
  `id_rendez_vous` int(10) NOT NULL,
  `montant` DECIMAL(10, 2) NOT NULL,
  `statut_paiement` ENUM('en_attente', 'complete', 'echoue') NOT NULL DEFAULT 'en_attente',
  `methode_paiement` VARCHAR(50),
  `date_paiement` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_paiement`),
  FOREIGN KEY (`id_rendez_vous`) REFERENCES `rendez_vous`(`id_rendez_vous`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `assistance_requests` (
  `id_request` int(10) NOT NULL AUTO_INCREMENT,
  `numero_telephone` varchar(15) NOT NULL,
  `description` TEXT,
  `status` ENUM('pending', 'assigned') DEFAULT 'pending',
  `cree_le` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `mis_a_jour_le` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_request`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



CREATE TABLE IF NOT EXISTS `garde_malade_requests` (
  `id_request` int(10) NOT NULL AUTO_INCREMENT,
  `id_patient` int(10) NOT NULL,
  `description` TEXT,
  `patient_latitude` DECIMAL(9, 6) NOT NULL,
  `patient_longitude` DECIMAL(9, 6) NOT NULL,
  `cree_le` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `mis_a_jour_le` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `status` ENUM('pending', 'assigned') DEFAULT 'pending',
  PRIMARY KEY (`id_request`),
  FOREIGN KEY (`id_patient`) REFERENCES `patient`(`id_patient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `doctor_requests` (
  `id_request` int(10) NOT NULL AUTO_INCREMENT,
  `id_patient` int(10) NOT NULL,
  `patient_latitude` DECIMAL(9, 6) NOT NULL,
  `patient_longitude` DECIMAL(9, 6) NOT NULL,
  `requested_time` DATETIME NOT NULL,
  `status` ENUM('pending', 'assigned') DEFAULT 'pending',

  PRIMARY KEY (`id_request`),
  FOREIGN KEY (`id_patient`) REFERENCES `patient`(`id_patient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `nurse_assistance_requests` (
  `id_request` int(10) NOT NULL AUTO_INCREMENT,
  `id_patient` int(10) NOT NULL,
  `patient_latitude` DECIMAL(9, 6) NOT NULL,
  `patient_longitude` DECIMAL(9, 6) NOT NULL,
  `requested_time` DATETIME NOT NULL,
  `id_service_type` INT(10) NOT NULL,
  `status` ENUM('pending', 'assigned') DEFAULT 'pending',

  FOREIGN KEY (`id_service_type`) REFERENCES `service_types`(`id_service_type`),
  PRIMARY KEY (`id_request`),
  FOREIGN KEY (`id_patient`) REFERENCES `patient`(`id_patient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- Table for Assistant Assignment
CREATE TABLE IF NOT EXISTS `assistant_assignment` (
    `id_assignment` INT AUTO_INCREMENT PRIMARY KEY,
    `id_request` INT NOT NULL,
    `id_assistant` INT NOT NULL,
    `assignment_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`id_assistant`) REFERENCES `docteur`(`id_doc`),
    FOREIGN KEY (`id_request`) REFERENCES `assistance_requests`(`id_request`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for Doctor Assignment
CREATE TABLE IF NOT EXISTS `doctor_assignment` (
    `id_assignment` INT AUTO_INCREMENT PRIMARY KEY,
    `id_request` INT NOT NULL,
    `id_doc` INT NOT NULL,
    `assignment_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`id_doc`) REFERENCES `docteur`(`id_doc`),
    FOREIGN KEY (`id_request`) REFERENCES `doctor_requests`(`id_request`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for Nurse Assignment
CREATE TABLE IF NOT EXISTS `nurse_assignment` (
    `id_assignment` INT AUTO_INCREMENT PRIMARY KEY,
    `id_request` INT NOT NULL,
    `id_nurse` INT NOT NULL,
    `assignment_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`id_nurse`) REFERENCES `docteur`(`id_doc`),
    FOREIGN KEY (`id_request`) REFERENCES `nurse_assistance_requests`(`id_request`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for Garde Malade Assignment
CREATE TABLE IF NOT EXISTS `garde_malade_assignment` (
    `id_assignment` INT AUTO_INCREMENT PRIMARY KEY,
    `id_request` INT NOT NULL,
    `id_gm` INT NOT NULL,
    `assignment_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`id_gm`) REFERENCES `docteur`(`id_doc`),
    FOREIGN KEY (`id_request`) REFERENCES `garde_malade_requests`(`id_request`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
