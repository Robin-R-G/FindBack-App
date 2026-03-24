const { Pool } = require('pg');
const path = require('path');

// Support both local SQLite-style setup (for dev) and cloud PostgreSQL (for prod)
// In production (Render), DATABASE_URL env var is set automatically
const isProduction = !!process.env.DATABASE_URL;

let db;

if (isProduction) {
    // ---- CLOUD: PostgreSQL (Render free tier) ----
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false }
    });

    // Create tables if they don't exist
    pool.query(`
        CREATE TABLE IF NOT EXISTS students (
            "studentId" TEXT PRIMARY KEY,
            name TEXT,
            phone TEXT,
            email TEXT,
            "scanCount" INTEGER DEFAULT 0
        )
    `).then(() => console.log('PostgreSQL: students table ready'))
      .catch(err => console.error('Error creating students table:', err.message));

    pool.query(`
        CREATE TABLE IF NOT EXISTS reports (
            id SERIAL PRIMARY KEY,
            "finderName" TEXT,
            location TEXT,
            message TEXT,
            "studentId" TEXT,
            timestamp TIMESTAMPTZ DEFAULT NOW(),
            FOREIGN KEY("studentId") REFERENCES students("studentId")
        )
    `).then(() => console.log('PostgreSQL: reports table ready'))
      .catch(err => console.error('Error creating reports table:', err.message));

    // Wrap pool to match SQLite's .run() / .get() / .all() interface
    db = {
        run: (sql, params, callback) => {
            pool.query(sql, params)
                .then(result => {
                    if (callback) callback.call({ changes: result.rowCount, lastID: result.rows[0]?.id }, null);
                })
                .catch(err => {
                    if (callback) callback(err);
                });
        },
        get: (sql, params, callback) => {
            pool.query(sql, params)
                .then(result => callback(null, result.rows[0]))
                .catch(err => callback(err, null));
        },
        all: (sql, params, callback) => {
            pool.query(sql, params)
                .then(result => callback(null, result.rows))
                .catch(err => callback(err, null));
        }
    };

    console.log('Connected to PostgreSQL (cloud).');

} else {
    // ---- LOCAL DEV: SQLite ----
    const sqlite3 = require('sqlite3').verbose();
    const dbPath = path.resolve(__dirname, 'findback.db');
    const sqlite = new sqlite3.Database(dbPath, (err) => {
        if (err) {
            console.error('Error opening SQLite database', err.message);
        } else {
            console.log('Connected to the local SQLite database.');
            sqlite.run(`CREATE TABLE IF NOT EXISTS students (
                studentId TEXT PRIMARY KEY,
                name TEXT,
                phone TEXT,
                email TEXT,
                scanCount INTEGER DEFAULT 0
            )`);
            sqlite.run(`CREATE TABLE IF NOT EXISTS reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                finderName TEXT,
                location TEXT,
                message TEXT,
                studentId TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(studentId) REFERENCES students(studentId)
            )`);
        }
    });
    db = sqlite;
}

module.exports = db;
