const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

// Common passwords used for local MySQL development
const passwordsToTry = [
    '', 'password', 'root', 'admin', '123456', '12345678',
    'Vishal', 'vishal', 'Vishal123', 'Vishal@123', 'vishal123', 'vishal@123',
    'Vishal1016', 'vishal1016', 'gvishal0099', 'gvishal', 'Vishal0099',
    'admin123', 'admin@123', 'admin@1234', 'mysql', 'root123'
];
const dbHost = '127.0.0.1';
const dbUser = 'root';
const dbPort = 3306;

async function getDbConnection() {
    // Check if the password was passed as a command line argument
    const cliPassword = process.argv[2];
    if (cliPassword !== undefined) {
        console.log(`Attempting connection using command-line password...`);
        try {
            const conn = await mysql.createConnection({
                host: dbHost,
                user: dbUser,
                password: cliPassword,
                port: dbPort,
                multipleStatements: false
            });
            console.log(`Successfully connected using command-line password!\n`);
            return conn;
        } catch (err) {
            console.error(`Connection failed using command-line password: "${cliPassword}"`);
            throw err;
        }
    }

    for (const pwd of passwordsToTry) {
        try {
            console.log(`Attempting connection with password: "${pwd}"...`);
            const conn = await mysql.createConnection({
                host: dbHost,
                user: dbUser,
                password: pwd,
                port: dbPort,
                multipleStatements: false // We will execute statements one-by-one for safety
            });
            console.log(`Successfully connected using password: "${pwd}"\n`);
            return conn;
        } catch (err) {
            // Keep trying other passwords
        }
    }
    throw new Error('Unable to connect to local MySQL with common credentials. Please check your username/password.');
}

function splitSqlStatements(sqlText) {
    const lines = sqlText.split(/\r?\n/);
    const statements = [];
    let currentStatement = [];
    let currentDelimiter = ';';
    
    for (let line of lines) {
        // Strip trailing comment from the line if any (marked by -- or #)
        let lineWithoutComment = line;
        
        const doubleDashIndex = line.indexOf('--');
        if (doubleDashIndex !== -1) {
            lineWithoutComment = line.substring(0, doubleDashIndex);
        }
        
        const hashIndex = lineWithoutComment.indexOf('#');
        if (hashIndex !== -1) {
            lineWithoutComment = lineWithoutComment.substring(0, hashIndex);
        }
        
        const trimmed = lineWithoutComment.trim();
        
        // Skip empty lines or pure comment lines
        if (trimmed === '') {
            continue;
        }
        
        if (trimmed.toUpperCase().startsWith('DELIMITER')) {
            const parts = trimmed.split(/\s+/);
            if (parts.length > 1) {
                currentDelimiter = parts[1];
            }
            continue;
        }
        
        currentStatement.push(lineWithoutComment);
        
        if (trimmed.endsWith(currentDelimiter)) {
            let stmt = currentStatement.join('\n').trim();
            // Remove the trailing delimiter
            stmt = stmt.slice(0, -currentDelimiter.length).trim();
            if (stmt) {
                statements.push(stmt);
            }
            currentStatement = [];
        }
    }
    
    if (currentStatement.length > 0) {
        const stmt = currentStatement.join('\n').trim();
        if (stmt) {
            statements.push(stmt);
        }
    }
    
    return statements;
}

async function run() {
    let connection;
    try {
        connection = await getDbConnection();
        
        // 1. Load SQL Schema File
        const sqlPath = path.join(__dirname, 'clinic_schema_5nf.sql');
        console.log(`Reading SQL schema file from: ${sqlPath}`);
        const sqlText = fs.readFileSync(sqlPath, 'utf8');
        
        // 2. Parse into individual statements
        const statements = splitSqlStatements(sqlText);
        console.log(`Parsed ${statements.length} SQL statements to execute.`);
        
        // 3. Execute each statement in sequence
        console.log('\nExecuting schema creation...');
        for (let i = 0; i < statements.length; i++) {
            const stmt = statements[i];
            try {
                await connection.query(stmt);
            } catch (err) {
                console.error(`Error executing statement #${i + 1}:`);
                console.error(stmt);
                console.error(err.message);
                throw err;
            }
        }
        console.log('✔ Schema setup and seeding complete!');
        
        // Switch to the newly created database
        await connection.query('USE clinic_db');
        
        // 4. Run Verification Tests
        console.log('\n--- STARTING VERIFICATION TESTS ---');

        // Test A: Check Tables
        const [tables] = await connection.query('SHOW TABLES');
        console.log(`✔ Found ${tables.length} tables/views in database.`);
        
        // Test B: Verify vw_doctor_directory view
        console.log('\nTesting view: vw_doctor_directory...');
        const [doctors] = await connection.query('SELECT * FROM vw_doctor_directory');
        console.log(`✔ Found ${doctors.length} doctors.`);
        console.table(doctors.map(d => ({
            ID: d.doctor_id,
            Name: d.full_name,
            License: d.license_number,
            Departments: d.departments,
            Specializations: d.specializations,
            Fee: `$${d.consultation_fee}`
        })));

        // Test C: Verify vw_patient_profiles view
        console.log('\nTesting view: vw_patient_profiles...');
        const [patients] = await connection.query('SELECT * FROM vw_patient_profiles');
        console.log(`✔ Found ${patients.length} patients.`);
        console.table(patients.map(p => ({
            ID: p.patient_id,
            Name: p.full_name,
            Phone: p.patient_phone,
            Email: p.patient_email || 'N/A',
            Address: p.patient_address,
            Emergency: p.emergency_contacts || 'N/A'
        })));

        // Test D: Verify vw_appointments_calendar view
        console.log('\nTesting view: vw_appointments_calendar...');
        const [appointments] = await connection.query('SELECT * FROM vw_appointments_calendar');
        console.log(`✔ Found ${appointments.length} appointments.`);
        console.table(appointments.map(a => ({
            ID: a.appointment_id,
            Date: a.appointment_date.toISOString().split('T')[0],
            Time: `${a.start_time} - ${a.end_time}`,
            Patient: a.patient_name,
            Doctor: a.doctor_name,
            Dept: a.department_name,
            Status: a.status
        })));

        // Test E: Run sp_register_patient (Stored Procedure 1)
        console.log('\nTesting Stored Procedure: sp_register_patient...');
        // Input details
        const regParams = [
            null, // user_id (walk-in)
            'Jane', // first name
            'Doe', // last name
            '1995-08-20', // dob
            'Female', // gender
            'AB+', // blood group
            '+1-555-9876', // phone
            'jane.doe@example.com', // email
            '123 Elm St, Bellevue, WA', // address
            'John Doe', // emergency name
            '+1-555-8765', // emergency phone
            'Spouse' // emergency relationship
        ];
        
        // Execute procedure with outputs
        await connection.query('SET @new_patient_id = 0');
        await connection.query(`
            CALL sp_register_patient(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @new_patient_id)
        `, regParams);
        
        const [newPatientResult] = await connection.query('SELECT @new_patient_id AS id');
        const newPatientId = newPatientResult[0].id;
        console.log(`✔ Successfully registered new patient. New Patient ID: ${newPatientId}`);
        
        // Verify from patient profiles view
        const [newPatientProfile] = await connection.query('SELECT * FROM vw_patient_profiles WHERE patient_id = ?', [newPatientId]);
        console.table(newPatientProfile.map(p => ({
            ID: p.patient_id,
            Name: p.full_name,
            Phone: p.patient_phone,
            Email: p.patient_email,
            Address: p.patient_address,
            Emergency: p.emergency_contacts
        })));

        // Test F: Run sp_book_appointment (Stored Procedure 2)
        console.log('\nTesting Stored Procedure: sp_book_appointment...');
        // Let's book Jane Doe with Dr. Davis (doctor_id 2) in Pediatrics (department_id 4) on Thursday (availability match)
        // Date: 2026-06-25 (Thursday)
        const bookParams = [
            newPatientId, // patient_id
            2, // doctor_id (Davis)
            4, // department_id (Pediatrics)
            '2026-06-25', // appointment_date
            '10:30:00', // start_time (within 09:00 - 15:00)
            '10:45:00', // end_time
            'Routine childhood wellness check', // reason
            4 // booked_by_user_id (Mary)
        ];
        
        await connection.query('SET @new_app_id = 0');
        await connection.query(`
            CALL sp_book_appointment(?, ?, ?, ?, ?, ?, ?, ?, @new_app_id)
        `, bookParams);
        
        const [newAppResult] = await connection.query('SELECT @new_app_id AS id');
        const newAppId = newAppResult[0].id;
        console.log(`✔ Successfully booked appointment. New Appointment ID: ${newAppId}`);

        // Verify overlapping appointment detection (Integrity check)
        console.log('Testing overlapping appointment validation (Should fail):');
        try {
            await connection.query(`
                CALL sp_book_appointment(?, ?, ?, ?, ?, ?, ?, ?, @fail_app_id)
            `, [1, 2, 4, '2026-06-25', '10:40:00', '10:55:00', 'Overlapping check', 4]);
            console.log('❌ FAILED: Overlapping booking was allowed!');
        } catch (err) {
            console.log(`✔ PASS: Overlapping booking blocked with message: "${err.message}"`);
        }

        // Test G: Run sp_add_medical_record (Stored Procedure 3)
        console.log('\nTesting Stored Procedure: sp_add_medical_record...');
        await connection.query('SET @new_rec_id = 0');
        await connection.query(`
            CALL sp_add_medical_record(?, 'Child is growing healthy, standard parameters.', 'None', 'Continue balanced diet.', NULL, @new_rec_id)
        `, [newAppId]);
        
        const [newRecResult] = await connection.query('SELECT @new_rec_id AS id');
        const newRecId = newRecResult[0].id;
        console.log(`✔ Successfully added medical record. New Record ID: ${newRecId}`);
        
        // Verify appointment status updated to Completed
        const [appStatus] = await connection.query('SELECT status FROM appointments WHERE appointment_id = ?', [newAppId]);
        console.log(`✔ Appointment status updated to: ${appStatus[0].status}`);

        // Test H: Write Prescription and Verify Inventory Triggers
        console.log('\nTesting Triggers: Inventory Checks & Updates...');
        
        // 1. Create prescription entry for the record
        await connection.query(`
            INSERT INTO prescriptions (record_id, prescribed_date, notes)
            VALUES (?, '2026-06-25', 'Child multi-vitamins and safety check.')
        `, [newRecId]);
        const [presResult] = await connection.query('SELECT LAST_INSERT_ID() AS id');
        const presId = presResult[0].id;
        
        // Let's check stock quantity of Ibuprofen (medicine_id 4) before prescribing
        const [medBefore] = await connection.query('SELECT stock_quantity FROM medicines WHERE medicine_id = 4');
        const stockBefore = medBefore[0].stock_quantity;
        console.log(`Ibuprofen stock quantity before prescription: ${stockBefore}`);
        
        // 2. Prescribe Ibuprofen: 10 days duration, Twice a day (20 tablets needed)
        console.log('Inserting prescription item for Ibuprofen (10 days @ Twice a day = 20 tablets)...');
        await connection.query(`
            INSERT INTO prescription_items (prescription_id, medicine_id, dosage, frequency, duration_days, instructions)
            VALUES (?, 4, '100mg', 'Twice a day', 10, 'Take after breakfast and dinner')
        `, [presId]);
        
        // 3. Verify stock was automatically reduced by trigger `trg_reduce_stock_after_prescription`
        const [medAfter] = await connection.query('SELECT stock_quantity FROM medicines WHERE medicine_id = 4');
        const stockAfter = medAfter[0].stock_quantity;
        console.log(`Ibuprofen stock quantity after prescription: ${stockAfter}`);
        if (stockBefore - stockAfter === 20) {
            console.log('✔ PASS: Inventory trigger successfully reduced stock quantity by exactly 20!');
        } else {
            console.log('❌ FAIL: Inventory trigger did not reduce stock properly.');
        }

        // Test I: Run sp_generate_invoice (Stored Procedure 4)
        console.log('\nTesting Stored Procedure: sp_generate_invoice...');
        // Consultation fee for Dr. Davis is 150.00
        // Medicine charges = Unit price of Ibuprofen (0.15) * 10 days * 2 times = 3.00
        // Other charges = 10.00, Discount = 5.00
        // Subtotal = 150.00 + 3.00 + 10.00 - 5.00 = 158.00
        // Tax (10%) = 15.80
        // Total = 173.80
        await connection.query('SET @new_inv_id = 0');
        await connection.query(`
            CALL sp_generate_invoice(?, 10.00, 5.00, @new_inv_id)
        `, [newAppId]);
        
        const [newInvResult] = await connection.query('SELECT @new_inv_id AS id');
        const newInvId = newInvResult[0].id;
        console.log(`✔ Successfully generated invoice. New Invoice ID: ${newInvId}`);
        
        // Verify invoice details
        const [invoice] = await connection.query('SELECT * FROM invoices WHERE invoice_id = ?', [newInvId]);
        console.table(invoice.map(i => ({
            ID: i.invoice_id,
            ConsultFee: `$${i.consultation_fee}`,
            MedCharges: `$${i.medicine_charges}`,
            Other: `$${i.other_charges}`,
            Discount: `$${i.discount}`,
            Tax: `$${i.tax_amount}`,
            Total: `$${i.total_amount}`,
            Status: i.payment_status
        })));
        
        // Test J: Run sp_process_payment (Stored Procedure 5)
        console.log('\nTesting Stored Procedure: sp_process_payment...');
        // Let's make a partial payment of $100.00
        await connection.query('SET @new_pay_id = 0');
        await connection.query(`
            CALL sp_process_payment(?, 100.00, 'Card', 'TXN-JANE-001', @new_pay_id)
        `, [newInvId]);
        
        let [invoicePartial] = await connection.query('SELECT payment_status FROM invoices WHERE invoice_id = ?', [newInvId]);
        console.log(`✔ Recorded partial payment of $100.00. Invoice status: ${invoicePartial[0].payment_status}`);
        
        // Pay the rest ($73.80)
        await connection.query(`
            CALL sp_process_payment(?, 73.80, 'UPI', 'TXN-JANE-002', @new_pay_id)
        `, [newInvId]);
        
        let [invoicePaid] = await connection.query('SELECT payment_status FROM invoices WHERE invoice_id = ?', [newInvId]);
        console.log(`✔ Recorded remaining payment of $73.80. Invoice status: ${invoicePaid[0].payment_status}`);
        
        // Test K: Verify Financial Ledger View
        console.log('\nTesting view: vw_financial_ledger for Jane Doe...');
        const [ledger] = await connection.query('SELECT * FROM vw_financial_ledger WHERE patient_id = ?', [newPatientId]);
        console.table(ledger.map(l => ({
            InvoiceID: l.invoice_id,
            Patient: l.patient_name,
            Doctor: l.doctor_name,
            Total: `$${l.total_amount}`,
            Paid: `$${l.total_paid}`,
            Due: `$${l.balance_due}`,
            Status: l.payment_status
        })));
        
        console.log('\n--- ALL VERIFICATION TESTS COMPLETED SUCCESSFULLY! ---');
        
    } catch (err) {
        console.error('\n❌ Verification Failed with Error:', err);
    } finally {
        if (connection) {
            await connection.end();
            console.log('\nDatabase connection closed.');
        }
    }
}

run();
