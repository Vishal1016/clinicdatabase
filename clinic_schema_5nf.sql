-- ============================================================
-- CLINIC APPOINTMENT MANAGEMENT SYSTEM
-- MySQL Database Schema (Normalized to 5NF)
-- ============================================================

DROP DATABASE IF EXISTS clinic_db;
CREATE DATABASE clinic_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE clinic_db;

-- Disable foreign key checks during schema recreation to prevent drop ordering issues
SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS prescription_items;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medicines;
DROP TABLE IF EXISTS medical_records;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS doctor_availability;
DROP TABLE IF EXISTS doctor_contacts;
DROP TABLE IF EXISTS patient_emergency_contacts;
DROP TABLE IF EXISTS patient_contacts;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctor_qualifications;
DROP TABLE IF EXISTS department_specializations;
DROP TABLE IF EXISTS doctor_specializations;
DROP TABLE IF EXISTS doctor_departments;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS qualifications;
DROP TABLE IF EXISTS specializations;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

-- Drop existing views if they exist
DROP VIEW IF EXISTS vw_doctor_directory;
DROP VIEW IF EXISTS vw_patient_profiles;
DROP VIEW IF EXISTS vw_appointments_calendar;
DROP VIEW IF EXISTS vw_patient_medical_histories;
DROP VIEW IF EXISTS vw_financial_ledger;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. ROLES (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE roles (
    role_id      INT AUTO_INCREMENT PRIMARY KEY,
    role_name    VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ============================================================
-- 2. USERS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    role_id       INT NOT NULL,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active     TINYINT(1) DEFAULT 1,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 3. DEPARTMENTS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    description      TEXT
) ENGINE=InnoDB;

-- ============================================================
-- 4. SPECIALIZATIONS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE specializations (
    specialization_id   INT AUTO_INCREMENT PRIMARY KEY,
    specialization_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ============================================================
-- 5. QUALIFICATIONS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE qualifications (
    qualification_id   INT AUTO_INCREMENT PRIMARY KEY,
    qualification_name VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ============================================================
-- 6. DOCTORS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE doctors (
    doctor_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id           INT NOT NULL UNIQUE,
    first_name        VARCHAR(50) NOT NULL,
    last_name         VARCHAR(50) NOT NULL,
    license_number    VARCHAR(50) NOT NULL UNIQUE,
    consultation_fee  DECIMAL(10,2) DEFAULT 0.00,
    years_experience  INT DEFAULT 0,
    is_available      TINYINT(1) DEFAULT 1,
    created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 7. DOCTOR DEPARTMENTS - Junction Table (5NF Decomposition)
-- ============================================================
CREATE TABLE doctor_departments (
    doctor_id     INT NOT NULL,
    department_id INT NOT NULL,
    PRIMARY KEY (doctor_id, department_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 8. DOCTOR SPECIALIZATIONS - Junction Table (5NF Decomposition)
-- ============================================================
CREATE TABLE doctor_specializations (
    doctor_id         INT NOT NULL,
    specialization_id INT NOT NULL,
    PRIMARY KEY (doctor_id, specialization_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 9. DEPARTMENT SPECIALIZATIONS - Junction Table (5NF Decomposition)
-- ============================================================
CREATE TABLE department_specializations (
    department_id     INT NOT NULL,
    specialization_id INT NOT NULL,
    PRIMARY KEY (department_id, specialization_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 10. DOCTOR QUALIFICATIONS - Junction Table (5NF Decomposition)
-- ============================================================
CREATE TABLE doctor_qualifications (
    doctor_id        INT NOT NULL,
    qualification_id INT NOT NULL,
    institution      VARCHAR(150) NOT NULL,
    year_obtained    INT NOT NULL,
    PRIMARY KEY (doctor_id, qualification_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (qualification_id) REFERENCES qualifications(qualification_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 11. PATIENTS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE patients (
    patient_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id            INT UNIQUE, -- Nullable for walk-in patients without online portal login
    first_name         VARCHAR(50) NOT NULL,
    last_name          VARCHAR(50) NOT NULL,
    date_of_birth      DATE NOT NULL,
    gender             ENUM('Male','Female','Other') NOT NULL,
    blood_group        VARCHAR(5),
    registered_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 12. PATIENT CONTACTS (4NF Decomposition for Patients)
-- ============================================================
CREATE TABLE patient_contacts (
    patient_id   INT NOT NULL,
    phone        VARCHAR(20) NOT NULL UNIQUE,
    email        VARCHAR(100) UNIQUE,
    address      VARCHAR(255) NOT NULL,
    PRIMARY KEY (patient_id, phone),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 13. PATIENT EMERGENCY CONTACTS (4NF Decomposition)
-- ============================================================
CREATE TABLE patient_emergency_contacts (
    patient_emergency_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id           INT NOT NULL,
    contact_name         VARCHAR(100) NOT NULL,
    contact_phone        VARCHAR(20) NOT NULL,
    relationship         VARCHAR(50) NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 14. DOCTOR CONTACTS (4NF Decomposition for Doctors)
-- ============================================================
CREATE TABLE doctor_contacts (
    doctor_id   INT NOT NULL,
    phone       VARCHAR(20) NOT NULL UNIQUE,
    email       VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (doctor_id, phone),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 15. DOCTOR AVAILABILITY (Weekly recurring schedule slots)
-- ============================================================
CREATE TABLE doctor_availability (
    availability_id  INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id         INT NOT NULL,
    department_id     INT NOT NULL,
    day_of_week       ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
    start_time        TIME NOT NULL,
    end_time          TIME NOT NULL,
    slot_duration_min INT DEFAULT 15,
    is_active         TINYINT(1) DEFAULT 1,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    -- Composite foreign key constraint to ensure availability aligns with doctor's actual department assignment
    FOREIGN KEY (doctor_id, department_id) REFERENCES doctor_departments(doctor_id, department_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 16. APPOINTMENTS (1NF, 2NF, 3NF, BCNF, 4NF, 5NF)
-- ============================================================
CREATE TABLE appointments (
    appointment_id     INT AUTO_INCREMENT PRIMARY KEY,
    patient_id          INT NOT NULL,
    doctor_id           INT NOT NULL,
    department_id       INT NOT NULL,
    appointment_date    DATE NOT NULL,
    start_time          TIME NOT NULL,
    end_time            TIME NOT NULL,
    status              ENUM('Scheduled','Confirmed','Completed','Cancelled','No-Show') DEFAULT 'Scheduled',
    reason              VARCHAR(255),
    booked_by_user_id   INT,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    -- Composite FK ensures appointments can only be booked for a doctor in a department they are assigned to
    FOREIGN KEY (doctor_id, department_id) REFERENCES doctor_departments(doctor_id, department_id) ON DELETE RESTRICT,
    FOREIGN KEY (booked_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    UNIQUE KEY unique_doctor_slot (doctor_id, appointment_date, start_time)
) ENGINE=InnoDB;

-- ============================================================
-- 17. MEDICAL RECORDS (No transitive patient_id/doctor_id - 3NF)
-- ============================================================
CREATE TABLE medical_records (
    record_id          INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id       INT NOT NULL UNIQUE,
    diagnosis             TEXT,
    symptoms               TEXT,
    treatment_notes        TEXT,
    follow_up_date          DATE,
    created_at             DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 18. MEDICINES
-- ============================================================
CREATE TABLE medicines (
    medicine_id     INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name    VARCHAR(150) NOT NULL,
    generic_name      VARCHAR(150),
    manufacturer       VARCHAR(150),
    unit_price          DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock_quantity       INT DEFAULT 0,
    expiry_date            DATE
) ENGINE=InnoDB;

-- ============================================================
-- 19. PRESCRIPTIONS (No transitive patient_id/doctor_id - 3NF)
-- ============================================================
CREATE TABLE prescriptions (
    prescription_id    INT AUTO_INCREMENT PRIMARY KEY,
    record_id            INT NOT NULL UNIQUE,
    prescribed_date          DATE NOT NULL,
    notes                       TEXT,
    FOREIGN KEY (record_id) REFERENCES medical_records(record_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 20. PRESCRIPTION_ITEMS (Junction details)
-- ============================================================
CREATE TABLE prescription_items (
    prescription_item_id  INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id         INT NOT NULL,
    medicine_id               INT NOT NULL,
    dosage                       VARCHAR(50),
    frequency                     VARCHAR(50), -- e.g. "Once a day", "Twice a day", "Three times a day"
    duration_days                   INT,
    instructions                      VARCHAR(255),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 21. INVOICES (No transitive patient_id - 3NF)
-- ============================================================
CREATE TABLE invoices (
    invoice_id        INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id      INT NOT NULL UNIQUE,
    consultation_fee        DECIMAL(10,2) DEFAULT 0.00,
    medicine_charges          DECIMAL(10,2) DEFAULT 0.00,
    other_charges                DECIMAL(10,2) DEFAULT 0.00,
    discount                       DECIMAL(10,2) DEFAULT 0.00,
    tax_amount                       DECIMAL(10,2) DEFAULT 0.00,
    total_amount                       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    payment_status                       ENUM('Pending','Paid','Partially Paid','Refunded') DEFAULT 'Pending',
    invoice_date                            DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 22. PAYMENTS
-- ============================================================
CREATE TABLE payments (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id        INT NOT NULL,
    amount_paid          DECIMAL(10,2) NOT NULL,
    payment_method          ENUM('Cash','Card','UPI','Bank Transfer','Insurance') NOT NULL,
    transaction_ref            VARCHAR(100),
    paid_at                       DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 23. NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    notification_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id              INT NOT NULL,
    title                  VARCHAR(150) NOT NULL,
    message                  TEXT,
    is_read                    TINYINT(1) DEFAULT 0,
    created_at                    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- ============================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_doctor_availability_lookup ON doctor_availability(doctor_id, day_of_week);
CREATE INDEX idx_patient_contacts_phone ON patient_contacts(phone);
CREATE INDEX idx_invoices_status ON invoices(payment_status);
CREATE INDEX idx_prescription_items_prescription ON prescription_items(prescription_id);


-- ============================================================
-- DATABASE VIEWS (Smooth abstraction layer for 5NF relationships)
-- ============================================================

-- A comprehensive doctor details view aggregating their user, contact details, departments, specializations, and qualifications
CREATE OR REPLACE VIEW vw_doctor_directory AS
SELECT 
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS full_name,
    u.username,
    u.email AS user_email,
    d.license_number,
    d.consultation_fee,
    d.years_experience,
    d.is_available,
    dc.phone AS doctor_phone,
    dc.email AS contact_email,
    (SELECT GROUP_CONCAT(dept.department_name ORDER BY dept.department_name SEPARATOR ', ')
     FROM doctor_departments dd
     JOIN departments dept ON dd.department_id = dept.department_id
     WHERE dd.doctor_id = d.doctor_id) AS departments,
    (SELECT GROUP_CONCAT(spec.specialization_name ORDER BY spec.specialization_name SEPARATOR ', ')
     FROM doctor_specializations ds
     JOIN specializations spec ON ds.specialization_id = spec.specialization_id
     WHERE ds.doctor_id = d.doctor_id) AS specializations,
    (SELECT GROUP_CONCAT(CONCAT(qual.qualification_name, ' (', dq.institution, ' - ', dq.year_obtained, ')') ORDER BY dq.year_obtained DESC SEPARATOR '; ')
     FROM doctor_qualifications dq
     JOIN qualifications qual ON dq.qualification_id = qual.qualification_id
     WHERE dq.doctor_id = d.doctor_id) AS qualifications
FROM doctors d
JOIN users u ON d.user_id = u.user_id
LEFT JOIN doctor_contacts dc ON d.doctor_id = dc.doctor_id;

-- A complete patient details view merging personal info, contacts, and emergency contacts
CREATE OR REPLACE VIEW vw_patient_profiles AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    p.date_of_birth,
    p.gender,
    p.blood_group,
    p.registered_at,
    pc.phone AS patient_phone,
    pc.email AS patient_email,
    pc.address AS patient_address,
    (SELECT GROUP_CONCAT(CONCAT(pec.contact_name, ' [', pec.relationship, ']: ', pec.contact_phone) SEPARATOR ' | ')
     FROM patient_emergency_contacts pec
     WHERE pec.patient_id = p.patient_id) AS emergency_contacts
FROM patients p
LEFT JOIN patient_contacts pc ON p.patient_id = pc.patient_id;

-- An appointment scheduling calendar view resolving all relationships
CREATE OR REPLACE VIEW vw_appointments_calendar AS
SELECT 
    a.appointment_id,
    a.appointment_date,
    a.start_time,
    a.end_time,
    a.status,
    a.reason,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    pc.phone AS patient_phone,
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    dept.department_id,
    dept.department_name,
    a.created_at
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
LEFT JOIN patient_contacts pc ON p.patient_id = pc.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN departments dept ON a.department_id = dept.department_id;

-- A medical record and clinical history history view resolving all relationships
CREATE OR REPLACE VIEW vw_patient_medical_histories AS
SELECT 
    mr.record_id,
    a.appointment_id,
    a.appointment_date,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    dept.department_name,
    mr.symptoms,
    mr.diagnosis,
    mr.treatment_notes,
    mr.follow_up_date,
    pr.prescription_id,
    (SELECT GROUP_CONCAT(CONCAT(m.medicine_name, ' (', pi.dosage, ', ', pi.frequency, ' x ', pi.duration_days, ' days) - ', pi.instructions) SEPARATOR '; ')
     FROM prescription_items pi
     JOIN medicines m ON pi.medicine_id = m.medicine_id
     WHERE pi.prescription_id = pr.prescription_id) AS prescribed_medicines
FROM medical_records mr
JOIN appointments a ON mr.appointment_id = a.appointment_id
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN departments dept ON a.department_id = dept.department_id
LEFT JOIN prescriptions pr ON pr.record_id = mr.record_id;

-- A financial view aggregating billing charges, paid amounts, outstanding balances and payment statuses
CREATE OR REPLACE VIEW vw_financial_ledger AS
SELECT 
    i.invoice_id,
    i.appointment_id,
    a.appointment_date,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    i.consultation_fee,
    i.medicine_charges,
    i.other_charges,
    i.discount,
    i.tax_amount,
    i.total_amount,
    COALESCE((SELECT SUM(pay.amount_paid) FROM payments pay WHERE pay.invoice_id = i.invoice_id), 0.00) AS total_paid,
    (i.total_amount - COALESCE((SELECT SUM(pay.amount_paid) FROM payments pay WHERE pay.invoice_id = i.invoice_id), 0.00)) AS balance_due,
    i.payment_status,
    i.invoice_date
FROM invoices i
JOIN appointments a ON i.appointment_id = a.appointment_id
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id;


-- ============================================================
-- STORED PROCEDURES (Smooth transactional operations)
-- ============================================================

DELIMITER //

-- 1. SP to register a patient, contact details, and emergency contacts atomically
CREATE PROCEDURE sp_register_patient(
    IN p_user_id INT,
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_dob DATE,
    IN p_gender ENUM('Male','Female','Other'),
    IN p_blood_group VARCHAR(5),
    IN p_phone VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_address VARCHAR(255),
    IN p_emergency_name VARCHAR(100),
    IN p_emergency_phone VARCHAR(20),
    IN p_emergency_relation VARCHAR(50),
    OUT o_patient_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Insert core patient profile
    INSERT INTO patients (user_id, first_name, last_name, date_of_birth, gender, blood_group)
    VALUES (p_user_id, p_first_name, p_last_name, p_dob, p_gender, p_blood_group);
    
    SET o_patient_id = LAST_INSERT_ID();
    
    -- Insert patient contact details
    INSERT INTO patient_contacts (patient_id, phone, email, address)
    VALUES (o_patient_id, p_phone, p_email, p_address);
    
    -- Insert emergency contact if details are provided
    IF p_emergency_name IS NOT NULL AND p_emergency_phone IS NOT NULL THEN
        INSERT INTO patient_emergency_contacts (patient_id, contact_name, contact_phone, relationship)
        VALUES (o_patient_id, p_emergency_name, p_emergency_phone, p_emergency_relation);
    END IF;
    
    COMMIT;
END //

-- 2. SP to safely book an appointment validating dependencies and schedules
CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_department_id INT,
    IN p_date DATE,
    IN p_start_time TIME,
    IN p_end_time TIME,
    IN p_reason VARCHAR(255),
    IN p_booked_by INT,
    OUT o_appointment_id INT
)
BEGIN
    DECLARE v_is_assigned INT DEFAULT 0;
    DECLARE v_is_available_status INT DEFAULT 0;
    DECLARE v_has_availability INT DEFAULT 0;
    DECLARE v_overlap_count INT DEFAULT 0;
    DECLARE v_day_name VARCHAR(15);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- A. Validate Doctor-Department relationship (5NF integrity check)
    SELECT COUNT(*) INTO v_is_assigned
    FROM doctor_departments
    WHERE doctor_id = p_doctor_id AND department_id = p_department_id;

    IF v_is_assigned = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Integrity Error: The doctor is not assigned to the specified department.';
    END IF;

    -- B. Validate Doctor is actively available for service
    SELECT is_available INTO v_is_available_status
    FROM doctors
    WHERE doctor_id = p_doctor_id;

    IF v_is_available_status = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Schedule Error: The doctor is currently set as unavailable.';
    END IF;

    -- C. Validate scheduling rules against Weekly availability entries
    SET v_day_name = DAYNAME(p_date);
    
    SELECT COUNT(*) INTO v_has_availability
    FROM doctor_availability
    WHERE doctor_id = p_doctor_id 
      AND department_id = p_department_id
      AND day_of_week = v_day_name
      AND p_start_time >= start_time 
      AND p_end_time <= end_time
      AND is_active = 1;

    IF v_has_availability = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Schedule Error: Requested time slot is outside of the doctor availability schedule.';
    END IF;

    -- D. Check for overlapping appointment timeslots for the doctor
    SELECT COUNT(*) INTO v_overlap_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND status NOT IN ('Cancelled')
      AND (
          (p_start_time >= start_time AND p_start_time < end_time) OR
          (p_end_time > start_time AND p_end_time <= end_time) OR
          (p_start_time <= start_time AND p_end_time >= end_time)
      );

    IF v_overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Conflict Error: The doctor is already booked for an overlapping time slot.';
    END IF;

    -- E. Book appointment
    INSERT INTO appointments (patient_id, doctor_id, department_id, appointment_date, start_time, end_time, status, reason, booked_by_user_id)
    VALUES (p_patient_id, p_doctor_id, p_department_id, p_date, p_start_time, p_end_time, 'Scheduled', p_reason, p_booked_by);

    SET o_appointment_id = LAST_INSERT_ID();
    
    COMMIT;
END //

-- 3. SP to insert medical records and update appointment status to Completed
CREATE PROCEDURE sp_add_medical_record(
    IN p_appointment_id INT,
    IN p_diagnosis TEXT,
    IN p_symptoms TEXT,
    IN p_treatment TEXT,
    IN p_follow_up DATE,
    OUT o_record_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    
    -- Insert medical record
    INSERT INTO medical_records (appointment_id, diagnosis, symptoms, treatment_notes, follow_up_date)
    VALUES (p_appointment_id, p_diagnosis, p_symptoms, p_treatment, p_follow_up);
    
    SET o_record_id = LAST_INSERT_ID();
    
    -- Update appointment status to Completed
    UPDATE appointments
    SET status = 'Completed'
    WHERE appointment_id = p_appointment_id;
    
    COMMIT;
END //

-- 4. SP to automatically generate an invoice calculations on Consultation fees & Prescribed medicines
CREATE PROCEDURE sp_generate_invoice(
    IN p_appointment_id INT,
    IN p_other_charges DECIMAL(10,2),
    IN p_discount DECIMAL(10,2),
    OUT o_invoice_id INT
)
BEGIN
    DECLARE v_consultation_fee DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_medicine_charges DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_tax DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_subtotal DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_record_id INT DEFAULT NULL;
    DECLARE v_prescription_id INT DEFAULT NULL;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Fetch Doctor's Consultation Fee
    SELECT d.consultation_fee INTO v_consultation_fee
    FROM appointments a
    JOIN doctors d ON a.doctor_id = d.doctor_id
    WHERE a.appointment_id = p_appointment_id;

    -- Fetch Medical Record associated with Appointment
    SELECT record_id INTO v_record_id
    FROM medical_records
    WHERE appointment_id = p_appointment_id;

    -- Fetch Prescription and compute aggregate medicine charges (if any)
    IF v_record_id IS NOT NULL THEN
        SELECT prescription_id INTO v_prescription_id
        FROM prescriptions
        WHERE record_id = v_record_id;
        
        IF v_prescription_id IS NOT NULL THEN
            SELECT SUM(m.unit_price * pi.duration_days * 
                CASE pi.frequency
                    WHEN 'Once a day' THEN 1
                    WHEN 'Twice a day' THEN 2
                    WHEN 'Three times a day' THEN 3
                    WHEN 'Four times a day' THEN 4
                    ELSE 1
                END
            ) INTO v_medicine_charges
            FROM prescription_items pi
            JOIN medicines m ON pi.medicine_id = m.medicine_id
            WHERE pi.prescription_id = v_prescription_id;
        END IF;
    END IF;

    SET v_medicine_charges = COALESCE(v_medicine_charges, 0.00);
    
    -- Subtotal and Tax Calculations (10% flat tax)
    SET v_subtotal = v_consultation_fee + v_medicine_charges + p_other_charges - p_discount;
    IF v_subtotal < 0 THEN
        SET v_subtotal = 0.00;
    END IF;
    
    SET v_tax = ROUND(v_subtotal * 0.10, 2);
    SET v_total = v_subtotal + v_tax;

    -- Insert Invoice details
    INSERT INTO invoices (appointment_id, consultation_fee, medicine_charges, other_charges, discount, tax_amount, total_amount, payment_status)
    VALUES (p_appointment_id, v_consultation_fee, v_medicine_charges, p_other_charges, p_discount, v_tax, v_total, 'Pending');

    SET o_invoice_id = LAST_INSERT_ID();
    
    COMMIT;
END //

-- 5. SP to process payments, update ledger, and change invoice status
CREATE PROCEDURE sp_process_payment(
    IN p_invoice_id INT,
    IN p_amount_paid DECIMAL(10,2),
    IN p_payment_method ENUM('Cash','Card','UPI','Bank Transfer','Insurance'),
    IN p_transaction_ref VARCHAR(100),
    OUT o_payment_id INT
)
BEGIN
    DECLARE v_total_bill DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Record the payment
    INSERT INTO payments (invoice_id, amount_paid, payment_method, transaction_ref)
    VALUES (p_invoice_id, p_amount_paid, p_payment_method, p_transaction_ref);
    
    SET o_payment_id = LAST_INSERT_ID();

    -- Fetch invoice total
    SELECT total_amount INTO v_total_bill
    FROM invoices
    WHERE invoice_id = p_invoice_id;

    -- Aggregate paid amounts for the invoice
    SELECT SUM(amount_paid) INTO v_total_paid
    FROM payments
    WHERE invoice_id = p_invoice_id;

    -- Conditionally update payment status
    IF v_total_paid >= v_total_bill THEN
        UPDATE invoices SET payment_status = 'Paid' WHERE invoice_id = p_invoice_id;
    ELSEIF v_total_paid > 0 THEN
        UPDATE invoices SET payment_status = 'Partially Paid' WHERE invoice_id = p_invoice_id;
    ELSE
        UPDATE invoices SET payment_status = 'Pending' WHERE invoice_id = p_invoice_id;
    END IF;

    COMMIT;
END //

DELIMITER ;


-- ============================================================
-- DATABASE TRIGGERS (Automated updates & constraints checks)
-- ============================================================

DELIMITER //

-- 1. Trigger to validate inventory before setting a prescription
CREATE TRIGGER trg_check_stock_before_prescription
BEFORE INSERT ON prescription_items
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;
    DECLARE v_qty_needed INT;
    
    SET v_qty_needed = NEW.duration_days * 
        CASE NEW.frequency
            WHEN 'Once a day' THEN 1
            WHEN 'Twice a day' THEN 2
            WHEN 'Three times a day' THEN 3
            WHEN 'Four times a day' THEN 4
            ELSE 1
        END;
        
    SELECT stock_quantity INTO v_stock
    FROM medicines
    WHERE medicine_id = NEW.medicine_id;
    
    IF v_stock < v_qty_needed THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory Error: Insufficient stock for the requested medicine dosage duration.';
    END IF;
END //

-- 2. Trigger to reduce medicine stock upon prescription write success
CREATE TRIGGER trg_reduce_stock_after_prescription
AFTER INSERT ON prescription_items
FOR EACH ROW
BEGIN
    DECLARE v_qty_needed INT;
    
    SET v_qty_needed = NEW.duration_days * 
        CASE NEW.frequency
            WHEN 'Once a day' THEN 1
            WHEN 'Twice a day' THEN 2
            WHEN 'Three times a day' THEN 3
            WHEN 'Four times a day' THEN 4
            ELSE 1
        END;

    UPDATE medicines
    SET stock_quantity = stock_quantity - v_qty_needed
    WHERE medicine_id = NEW.medicine_id;
END //

-- 3. Trigger to return stock if prescription item is deleted
CREATE TRIGGER trg_return_stock_on_prescription_delete
AFTER DELETE ON prescription_items
FOR EACH ROW
BEGIN
    DECLARE v_qty_returned INT;
    
    SET v_qty_returned = OLD.duration_days * 
        CASE OLD.frequency
            WHEN 'Once a day' THEN 1
            WHEN 'Twice a day' THEN 2
            WHEN 'Three times a day' THEN 3
            WHEN 'Four times a day' THEN 4
            ELSE 1
        END;

    UPDATE medicines
    SET stock_quantity = stock_quantity + v_qty_returned
    WHERE medicine_id = OLD.medicine_id;
END //

DELIMITER ;


-- ============================================================
-- SEED DATA (Comprehensive validation payload)
-- ============================================================

-- A. Insert Roles
INSERT INTO roles (role_id, role_name) VALUES 
(1, 'Admin'), 
(2, 'Doctor'), 
(3, 'Receptionist'), 
(4, 'Patient');

-- B. Insert Users (logins for staff and patients)
INSERT INTO users (user_id, role_id, username, email, password_hash, is_active) VALUES
(1, 1, 'admin_sys', 'admin@clinic.com', '$2b$12$K1d848H39Kldsf834jksd83', 1),
(2, 2, 'dr_smith', 'j.smith@clinic.com', '$2b$12$K1d848H39Kldsf834jksd84', 1),
(3, 2, 'dr_davis', 'a.davis@clinic.com', '$2b$12$K1d848H39Kldsf834jksd85', 1),
(4, 3, 'recept_mary', 'mary.k@clinic.com', '$2b$12$K1d848H39Kldsf834jksd86', 1),
(5, 4, 'patient_alice', 'alice.green@gmail.com', '$2b$12$K1d848H39Kldsf834jksd87', 1),
(6, 4, 'patient_bob', 'bob.brown@yahoo.com', '$2b$12$K1d848H39Kldsf834jksd88', 1);

-- C. Insert Departments
INSERT INTO departments (department_id, department_name, description) VALUES
(1, 'General Medicine', 'Primary care, physical exams, and health advice.'),
(2, 'Cardiology', 'Heart health and treatment of cardiovascular diseases.'),
(3, 'Dermatology', 'Skin, hair, and nail healthcare.'),
(4, 'Pediatrics', 'Comprehensive healthcare for infants, children, and adolescents.');

-- D. Insert Specializations
INSERT INTO specializations (specialization_id, specialization_name) VALUES
(1, 'Family Practice'),
(2, 'Cardiovascular Disease'),
(3, 'Pediatric Cardiology'),
(4, 'Clinical Dermatology');

-- E. Insert Qualifications
INSERT INTO qualifications (qualification_id, qualification_name) VALUES
(1, 'Doctor of Medicine (MD)'),
(2, 'Bachelor of Medicine, Bachelor of Surgery (MBBS)'),
(3, 'Fellowship of the American College of Cardiology (FACC)'),
(4, 'Board Certification in Dermatology');

-- F. Insert Doctors
INSERT INTO doctors (doctor_id, user_id, first_name, last_name, license_number, consultation_fee, years_experience, is_available) VALUES
(1, 2, 'John', 'Smith', 'LIC-MD-99238', 120.00, 15, 1),
(2, 3, 'Alice', 'Davis', 'LIC-MBBS-88347', 150.00, 10, 1);

-- G. Associate Doctors with Departments (5NF Doctor-Department mapping)
-- Dr. Smith belongs to General Medicine and Cardiology
-- Dr. Davis belongs to Cardiology and Pediatrics
INSERT INTO doctor_departments (doctor_id, department_id) VALUES
(1, 1),
(1, 2),
(2, 2),
(2, 4);

-- H. Associate Doctors with Specializations (5NF Doctor-Specialization mapping)
INSERT INTO doctor_specializations (doctor_id, specialization_id) VALUES
(1, 1),
(1, 2),
(2, 2),
(2, 3);

-- I. Associate Departments with Specializations (5NF Department-Specialization mapping)
INSERT INTO department_specializations (department_id, specialization_id) VALUES
(1, 1),
(2, 2),
(2, 3),
(3, 4),
(4, 3);

-- J. Doctor Qualifications
INSERT INTO doctor_qualifications (doctor_id, qualification_id, institution, year_obtained) VALUES
(1, 1, 'Harvard Medical School', 2008),
(1, 3, 'American College of Cardiology', 2012),
(2, 2, 'Oxford University', 2014),
(2, 3, 'Royal College of Physicians', 2018);

-- K. Doctor Contacts
INSERT INTO doctor_contacts (doctor_id, phone, email) VALUES
(1, '+1-555-0199', 'dr.smith@clinic.com'),
(2, '+1-555-0188', 'dr.davis@clinic.com');

-- L. Doctor Availability Schedules
INSERT INTO doctor_availability (doctor_id, department_id, day_of_week, start_time, end_time, slot_duration_min, is_active) VALUES
(1, 1, 'Monday', '09:00:00', '13:00:00', 15, 1),
(1, 2, 'Wednesday', '14:00:00', '18:00:00', 20, 1),
(2, 2, 'Monday', '10:00:00', '14:00:00', 20, 1),
(2, 4, 'Thursday', '09:00:00', '15:00:00', 15, 1);

-- M. Patients
INSERT INTO patients (patient_id, user_id, first_name, last_name, date_of_birth, gender, blood_group) VALUES
(1, 5, 'Alice', 'Green', '1990-05-15', 'Female', 'A+'),
(2, 6, 'Robert', 'Brown', '1982-11-22', 'Male', 'O-'),
(3, NULL, 'Walkin', 'Charlie', '1975-04-03', 'Other', 'B+'); -- Walk-in patient (no user login)

-- N. Patient Contacts
INSERT INTO patient_contacts (patient_id, phone, email, address) VALUES
(1, '+1-555-0201', 'alice.green@gmail.com', '123 Pine St, Seattle, WA'),
(2, '+1-555-0202', 'bob.brown@yahoo.com', '456 Oak Ave, Tacoma, WA'),
(3, '+1-555-0203', NULL, '789 Maple Rd, Bellevue, WA');

-- O. Patient Emergency Contacts
INSERT INTO patient_emergency_contacts (patient_id, contact_name, contact_phone, relationship) VALUES
(1, 'David Green', '+1-555-0301', 'Spouse'),
(2, 'Sarah Brown', '+1-555-0302', 'Sibling');

-- P. Medicines Catalog
INSERT INTO medicines (medicine_id, medicine_name, generic_name, manufacturer, unit_price, stock_quantity, expiry_date) VALUES
(1, 'Amoxicillin 500mg', 'Amoxicillin', 'PharmaCorp', 0.50, 1000, '2028-12-31'),
(2, 'Atorvastatin 20mg', 'Atorvastatin', 'Pfizer', 1.20, 500, '2027-06-30'),
(3, 'Lisinopril 10mg', 'Lisinopril', 'Sandoz', 0.80, 800, '2027-09-30'),
(4, 'Ibuprofen 400mg', 'Ibuprofen', 'GenericMeds', 0.15, 2000, '2029-01-31');

-- Q. Core workflow entries (Appointments, Medical Records, Prescriptions, Prescription Items, Invoices, Payments)

-- 1. Book an appointment for Alice Green with Dr. Smith in General Medicine on a Monday
INSERT INTO appointments (appointment_id, patient_id, doctor_id, department_id, appointment_date, start_time, end_time, status, reason, booked_by_user_id) VALUES
(1, 1, 1, 1, '2026-06-22', '09:30:00', '09:45:00', 'Scheduled', 'Annual health checkup', 5);

-- 2. Add medical record for the appointment (which updates status to Completed)
-- We will write it directly to simulate the stored procedure behavior
INSERT INTO medical_records (record_id, appointment_id, diagnosis, symptoms, treatment_notes, follow_up_date) VALUES
(1, 1, 'Mild hypertension, advise sodium reduction.', 'Slight headaches and fatigue', 'Prescribed Lisinopril, return in 3 months.', '2026-09-22');

UPDATE appointments SET status = 'Completed' WHERE appointment_id = 1;

-- 3. Write Prescription for Alice Green's checkup
INSERT INTO prescriptions (prescription_id, record_id, prescribed_date, notes) VALUES
(1, 1, '2026-06-22', 'Take once daily in the morning with water.');

-- 4. Prescription items (Trigger will fire here and subtract stock_quantity: 30 tablets * 1 daily = 30 tablets)
INSERT INTO prescription_items (prescription_id, medicine_id, dosage, frequency, duration_days, instructions) VALUES
(1, 3, '10mg', 'Once a day', 30, 'Take in morning');

-- 5. Invoice for Alice Green's appointment
-- Consultation Fee = 120.00
-- Medicine Fee = 0.80 * 30 * 1 = 24.00
-- Subtotal = 144.00
-- Tax (10%) = 14.40
-- Total = 158.40
INSERT INTO invoices (invoice_id, appointment_id, consultation_fee, medicine_charges, other_charges, discount, tax_amount, total_amount, payment_status) VALUES
(1, 1, 120.00, 24.00, 0.00, 0.00, 14.40, 158.40, 'Pending');

-- 6. Alice processes a payment of 100.00 (partial payment)
INSERT INTO payments (payment_id, invoice_id, amount_paid, payment_method, transaction_ref) VALUES
(1, 1, 100.00, 'Card', 'TXN-CARD-002938');

UPDATE invoices SET payment_status = 'Partially Paid' WHERE invoice_id = 1;

-- 7. Alice pays the remaining 58.40
INSERT INTO payments (payment_id, invoice_id, amount_paid, payment_method, transaction_ref) VALUES
(2, 1, 58.40, 'UPI', 'TXN-UPI-9843928');

UPDATE invoices SET payment_status = 'Paid' WHERE invoice_id = 1;


-- ============================================================
-- NOTIFICATION SEED
-- ============================================================
INSERT INTO notifications (user_id, title, message) VALUES
(5, 'Appointment Confirmed', 'Your appointment with Dr. John Smith on 2026-06-22 has been scheduled.'),
(5, 'Invoice Ready', 'Your invoice for appointment on 2026-06-22 is ready for payment.');
