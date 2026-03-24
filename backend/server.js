const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');
const db = require('./db');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Detect if running locally (SQLite) or in cloud (PostgreSQL)
const isProduction = !!process.env.DATABASE_URL;

// Helper: converts SQLite '?' placeholders to PostgreSQL '$1,$2...' style
function toQuery(sql, params) {
    if (!isProduction) return { sql, params }; // SQLite uses ? as-is
    let i = 0;
    const pgSql = sql.replace(/\?/g, () => `$${++i}`);
    return { sql: pgSql, params };
}

// Health check / root endpoint
app.get('/', (req, res) => {
    res.json({ status: 'FindBack backend is running!', timestamp: new Date().toISOString() });
});

// POST /register
app.post('/register', (req, res) => {
    const { name, phone, email } = req.body;
    const studentId = req.body.studentId;

    if (!name || !phone || !email || !studentId) {
        return res.status(400).json({ error: 'Student ID, Name, Phone, and Email are required.' });
    }

    const rawSql = `INSERT INTO students ("studentId", name, phone, email, "scanCount") VALUES (?, ?, ?, ?, ?)`;
    const { sql, params } = toQuery(rawSql, [studentId, name, phone, email, 0]);

    db.run(sql, params, function(err) {
        if (err) {
            // If student already exists, update their info instead
            const updateRaw = `UPDATE students SET name=?, phone=?, email=? WHERE "studentId"=?`;
            const { sql: upSql, params: upParams } = toQuery(updateRaw, [name, phone, email, studentId]);
            db.run(upSql, upParams, function(err2) {
                if (err2) return res.status(500).json({ error: 'Failed to register student.' });
                res.status(200).json({ message: 'Student profile updated', studentId });
            });
        } else {
            res.status(201).json({ message: 'Student registered successfully', studentId });
        }
    });
});

// GET /student/:id
app.get('/student/:id', (req, res) => {
    const studentId = req.params.id;
    const rawSql = `SELECT * FROM students WHERE "studentId" = ?`;
    const { sql, params } = toQuery(rawSql, [studentId]);

    db.get(sql, params, (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        if (!row) return res.status(404).json({ error: 'Student not found.' });

        // Normalize column names (PostgreSQL returns lowercase)
        const phone = row.phone || '';
        let maskedPhone = phone;
        if (phone.length > 6) {
            const firstPart = phone.substring(0, 4);
            const lastPart = phone.slice(-2);
            const middle = '*'.repeat(phone.length - 6);
            maskedPhone = `${firstPart}${middle}${lastPart}`;
        }

        const safeData = {
            studentId: row.studentId || row.studentid,
            name: row.name,
            phone: maskedPhone,
            rawPhone: phone,
            email: row.email
        };

        res.json({ student: safeData });
    });
});

// POST /scan
app.post('/scan', (req, res) => {
    const { studentId } = req.body;
    if (!studentId) return res.status(400).json({ error: 'Student ID required.' });

    const rawSql = `UPDATE students SET "scanCount" = "scanCount" + 1 WHERE "studentId" = ?`;
    const { sql, params } = toQuery(rawSql, [studentId]);

    db.run(sql, params, function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Scan recorded successfully' });
    });
});

// GET /admin/data (Admin endpoint to view all registered data)
app.get('/admin/data', (req, res) => {
    const studentsSql = isProduction ? `SELECT * FROM students ORDER BY "scanCount" DESC` : `SELECT * FROM students ORDER BY scanCount DESC`;
    const reportsSql = isProduction ? `SELECT r.*, s.name as studentName FROM reports r LEFT JOIN students s ON r."studentId" = s."studentId" ORDER BY r.timestamp DESC` : `SELECT r.*, s.name as studentName FROM reports r LEFT JOIN students s ON r.studentId = s.studentId ORDER BY r.timestamp DESC`;

    db.all(studentsSql, [], (err, students) => {
        if (err) return res.status(500).json({ error: err.message });
        
        db.all(reportsSql, [], (err2, reports) => {
            if (err2) return res.status(500).json({ error: err2.message });
            
            res.json({
                userCount: students.length,
                reportCount: reports.length,
                totalScans: students.reduce((sum, s) => sum + (s.scanCount || s.scancount || 0), 0),
                students: students,
                reports: reports
            });
        });
    });
});

app.post('/report', (req, res) => {
    const { finderName, location, message, studentId } = req.body;
    if (!finderName || !location || !message || !studentId) {
        return res.status(400).json({ error: 'Missing required fields.' });
    }

    const rawSql = `INSERT INTO reports ("finderName", location, message, "studentId") VALUES (?, ?, ?, ?)`;
    const { sql, params } = toQuery(rawSql, [finderName, location, message, studentId]);

    db.run(sql, params, function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ message: 'Report submitted successfully' });
    });
});

const os = require('os');
const PORT = process.env.PORT || 3000;

function getLocalIp() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) return iface.address;
        }
    }
    return '127.0.0.1';
}

app.listen(PORT, '0.0.0.0', () => {
    const localIp = getLocalIp();
    console.log(`✅ FindBack server is running on port ${PORT}`);
    console.log(`   Local dev URL: http://${localIp}:${PORT}`);
    if (isProduction) console.log('   Mode: PRODUCTION (PostgreSQL)');
    else console.log('   Mode: LOCAL DEV (SQLite)');
});
