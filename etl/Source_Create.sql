-- Create the database and set it as active, then create the schema

CREATE DATABASE DavaX;
GO

USE DavaX;
GO

CREATE SCHEMA sources;
GO

-- Employees table (minimal complexity)
CREATE TABLE sources.angajati (
    angajat_id INT IDENTITY PRIMARY KEY,
    nume VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department VARCHAR(100),
    grade VARCHAR(100),
    manager_id INT
);

-- Timesheets table (minimal complexity)
CREATE TABLE sources.timesheets (
    pontaj_id INT IDENTITY PRIMARY KEY,
    angajat_id INT,
    date_day DATE,
    duration_hours INT NOT NULL CHECK (duration_hours < 20),
    location_work VARCHAR(10) CHECK (location_work IN ('office', 'remote')) DEFAULT 'remote',
    FOREIGN KEY (angajat_id) REFERENCES sources.angajati(angajat_id)
);

-- Table where attendance from CSVs will be loaded
CREATE TABLE sources.attendance (
    attendance_id INT IDENTITY PRIMARY KEY,
    full_name VARCHAR(255),
    email VARCHAR(255),
    date_day DATE,
    start_time DATETIME,
    end_time DATETIME,
    duration_minutes INT,
    source_dataset VARCHAR(255),
    course VARCHAR(255),
    load_timestamp DATETIME DEFAULT GETDATE()
);

-- Table for absences (the third data source for the ETL)
CREATE TABLE sources.absences (
    absence_id INT IDENTITY PRIMARY KEY,
    angajat_id INT,
    date_day DATE,
    reason VARCHAR(100),
    FOREIGN KEY (angajat_id) REFERENCES sources.angajati(angajat_id)
);

-- Main reporting table
CREATE TABLE employee_activity (
    id INT IDENTITY PRIMARY KEY,
    employee_name NVARCHAR(255),
    activity_date DATE,
    activity_type NVARCHAR(50),      -- ex: 'work', 'absence', 'training', 'holiday', 'medical_leave'
    -- project_code NVARCHAR(50),
    course NVARCHAR(255),
    absent_hours FLOAT,
    present_hours FLOAT,
    source NVARCHAR(50),             -- ex: 'confluence', 'csv', 'manual'
    validated BIT DEFAULT 0,         -- flag for validation
    discipline NVARCHAR(255),        -- for discipline changes
    manager NVARCHAR(255),           -- for manager changes
    last_update DATETIME DEFAULT GETDATE()
);

-- TRUNCATE TABLE sources.attendance; mai intai, daca deja ai tabela
CREATE UNIQUE INDEX uq_attendance ON sources.attendance(email, date_day, course);
