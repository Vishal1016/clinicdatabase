# Clinic Appointment Management System (MySQL 5NF Schema)

This repository contains a highly optimized, fully normalized **Fifth Normal Form (5NF)** MySQL database schema designed for a Clinic Appointment Management System. 

To abstract database complexity and ensure **smooth application operations**, the design includes database views, transactional stored procedures, and automated database triggers.

---

## 5NF Normalization Strategy

We normalized the clinic database up to the Fifth Normal Form (5NF) to eliminate data redundancy, transitive dependencies, and update/delete anomalies.

### 1. 5NF Joint Decomposition (Doctor-Department-Specialization)
In real-world settings, a doctor can practice a specialization in a department if and only if:
1. The doctor belongs to that department.
2. The doctor has that specialization.
3. The department offers that specialization.

Storing this as a single ternary relationship `(doctor_id, department_id, specialization_id)` would violate 5NF due to join dependency. We decomposed it into three binary mapping tables:
- **`doctor_departments`**: Matches doctors with their assigned departments.
- **`doctor_specializations`**: Matches doctors with their specializations.
- **`department_specializations`**: Matches departments with specializations they offer.

### 2. 4NF Contact Decomposition (Multivalued Dependencies)
Fields like patient phone numbers, email addresses, and emergency contacts are multi-valued and independent. Storing them directly in the core tables violates 4NF. We separated them into:
- **`patient_contacts`**: Supports multiple contacts per patient.
- **`patient_emergency_contacts`**: Captures emergency names, phones, and relationships.
- **`doctor_contacts`**: Separates doctor contact channels.

### 3. 3NF/BCNF Transitive Dependency Cleansing
Transitive functional dependencies introduce update anomalies. We removed redundant columns where a key determines another non-key attribute transitively:
- **`medical_records`**: Removed `patient_id` and `doctor_id` (resolved via `appointment_id`).
- **`prescriptions`**: Removed `patient_id` and `doctor_id` (resolved via `record_id -> medical_records -> appointments`).
- **`invoices`**: Removed `patient_id` (resolved via `appointment_id -> appointments`).

---

## Database Components & Optimization

### 1. Database Views (Read Layer)
* **`vw_doctor_directory`**: Combines doctor profiles, license numbers, consultation fees, and group-concatenated departments, specializations, and qualifications.
* **`vw_patient_profiles`**: Aggregates patient personal info, addresses, and lists of emergency contacts.
* **`vw_appointments_calendar`**: Merges patient name, contact details, doctor name, and department names with the appointment date and status.
* **`vw_patient_medical_histories`**: Resolves patient clinical history, mapping diagnoses, symptoms, and lists of prescribed medicines with dosages.
* **`vw_financial_ledger`**: Provides invoices, aggregate payment amounts, outstanding balances, and payment status details.

### 2. Stored Procedures (Write/Transaction Layer)
* **`sp_register_patient`**: Registers patient details, contact numbers, and emergency details atomically inside a single transaction block.
* **`sp_book_appointment`**: Validates doctor-department assignment, checks weekly availability schedules, ensures no time-slot overlaps, and books the appointment.
* **`sp_add_medical_record`**: Automatically inserts a medical record and updates the corresponding appointment status to `'Completed'`.
* **`sp_generate_invoice`**: Automatically aggregates doctor consultation fees, sums medicine charges from prescriptions (duration days × daily frequency count × unit price), calculates a 10% tax, applies discounts, and inserts the invoice.
* **`sp_process_payment`**: Logs a payment (supports partial payments) and dynamically updates the invoice status to `Paid` or `Partially Paid` depending on the outstanding balance.

### 3. Database Triggers (Automated Actions)
* **`trg_check_stock_before_prescription`**: Validates medicine stock availability in the pharmacy catalog before allowing a prescription to be added.
* **`trg_reduce_stock_after_prescription`**: Decrements the medicine stock quantity automatically upon a successful prescription write.
* **`trg_return_stock_on_prescription_delete`**: Automatically restores the medicine inventory count if a prescription item is deleted.

---

## File Structure

```
├── .gitignore               # Config to exclude node_modules from git commits
├── clinic_schema_5nf.sql    # Complete SQL database schema and seeds
├── package.json             # NPM package configurations
├── README.md                # Documentation (this file)
└── verify_clinic_db.js      # Automated Node.js integration testing script
```

---

## Setup & Verification Tests

You can set up and run the automated verification test suite on your local MySQL server.

### Prerequisites
- Node.js (v18+)
- MySQL Server (running on port 3306)

### Running the Test Suite
1. Clone or navigate to the repository directory:
   ```bash
   cd clinicdatabase
   ```
2. Install the MySQL driver package:
   ```bash
   npm install
   ```
3. Execute the verification script, passing your local MySQL `root` password as an argument:
   ```bash
   node verify_clinic_db.js <your_mysql_password>
   ```

### What the Test Script Verifies:
- **Clean Reset**: Drops `clinic_db` database if exists, recreates it, and runs the entire schema.
- **View Resolution**: Queries and prints formatted tables of doctor directories, patient profiles, and appointment calendars.
- **Transactions**: Registers a patient, books a slot, blocks conflicting duplicate timeslots, creates medical logs, and computes aggregate invoices.
- **Inventory Triggers**: Simulates pharmacy prescription processing and validates that medicine stock values decrement correctly.
- **Payments & Ledgers**: Simulates partial and full invoice payments and asserts that outstanding balances update to `$0.00`.
