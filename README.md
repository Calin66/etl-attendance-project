# ETL Attendance Project

An ETL pipeline for extracting, cleaning, and loading attendance and absence employee data from exported meeting CSV files (e.g. Zoom, Teams) and other sources into a SQL Server database (`DavaX`).

---

## 📦 Project Structure

```
etl-attendance-project/
├── data/                    # Base directory for raw data files
├── etl/                     # Core ETL logic (extract, transform, load)
│   ├── extract.py
│   ├── scheduler.py
│   └── ...
├── scheduler.py             # Main entry point for running the ETL
├── requirements.txt
├── Dockerfile
├── .env
└── README.md
```

## ⚙️ Setup

I had to install ODBC Driver for SQL Server from Microsoft. Version 17.

### Environment Variables

Create a `.env` file in the root with YOUR PASSWORD for the database, this is mine (it's local):

```
DB_URL=mssql+pyodbc://sa:YourStrong!Passw0rd@host.docker.internal/DavaX?driver=ODBC+Driver+17+for+SQL+Server
```
---

### 📂 Input Files & Folder Structure

- **Create the folder structure before running the pipeline:**  
  Make sure the `data/attendance` folder exists on your host machine before running Docker.  
  Place the required DML `.csv` files (attendance/absence exports) inside `data/attendance`.

- **Environment variable for ICS calendar:**  
  In your `.env` file, add the direct link to your ICS calendar as `ICS_URL`.
  This URL should be accessible without authentication, or you must adapt the pipeline for your authentication method.

---

If you want to create a new database / image and have the same SSMS setup as me, run: 

docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong!Passw0rd" -p 1433:1433 --name sqlserver -d mcr.microsoft.com/mssql/server:latest


## 🐳 Running with Docker

### Build the container:

```
docker build -t etl-attendance-project .
```

### Run the pipeline:

```
docker run --rm -v "${PWD}/data:/app/data" --env-file .env etl-attendance-project
```

---

## 🧠 What It Does

- Loads `.csv` files from `/data/attendance`
- Extracts full name, email, join/leave time, duration, etc.
- Parses session title and source dataset
- Converts data to a clean format
- Inserts into SQL Server: `sources.attendance`
- Downloads and processes Confluence calendar (.ics) for absences
- Generates absence matrix and long-format CSVs
- Imports absences and other sources into the main SQL table (`employee_activity`)
- Generates reports and validates data

---

## 🧪 Test Connection

Use this SQL to confirm success:

```sql
SELECT TOP 10 * FROM sources.attendance ORDER BY load_timestamp DESC;
```

---

## 📌 Notes

- The pipeline supports `.csv` exports in standard Teams/Zoom format
- Duration is converted to minutes using basic time parsing
- Course/session titles are extracted from metadata in the file
- Absence data is processed from Confluence calendar exports (.ics)
- All data is loaded into a unified SQL schema for reporting

---

## 🗃️ SQL Database

Make sure to have SSMS opened and connected to your database.
Below is the DDL SQL for the SQL Database.

```sql
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
    project_code NVARCHAR(50),
    course NVARCHAR(255),
    absent_hours FLOAT,
    present_hours FLOAT,
    source NVARCHAR(50),             -- ex: 'confluence', 'csv', 'manual'
    validated BIT DEFAULT 0,         -- flag for validation
    discipline NVARCHAR(255),        -- for discipline changes
    manager NVARCHAR(255),           -- for manager changes
    last_update DATETIME DEFAULT GETDATE()
);
```

---

## 🔄 Data Flow Overview

1. **Raw Data Ingestion:**  
   - All raw files (CSV, Excel, ICS) are placed in the `/data` directory structure.
   - The pipeline expects specific file names and formats for each data source.

2. **ETL Execution:**  
   - The scheduler orchestrates the ETL steps: downloading, parsing, transforming, and loading data into SQL.
   - Each ETL step is modular and can be extended for new sources.

3. **SQL Database Population:**  
   - The SQL script (`SQL_ETL_Pipeline_Project_July.sql`) creates all necessary tables and schemas.
   - Data is loaded into staging/source tables, then integrated into the main reporting table (`employee_activity`).

4. **Reporting & Validation:**  
   - Pivot tables and long-format reports are generated for analysis.
   - Data validation is performed by cross-checking with the original Confluence matrix and other sources.
   - Validation flags are set in the database or exported Excel files.

---

## 🧩 Adding New Data Sources

- To add a new data source:
  1. Create a new ETL script in the `etl/` directory.
  2. Update the scheduler to include the new import step.
  3. Adjust the SQL schema if new columns or tables are needed.
  4. Document the new source and its integration in this README.

---

## 🗃️ Example SQL Queries

**What did an employee do on a specific day?**
```sql
SELECT * FROM employee_activity
WHERE employee_name = 'John Doe' AND activity_date = '2024-07-01';
```

**Monthly attendance/absence per course:**
```sql
SELECT course, employee_name, MONTH(activity_date) as month, SUM(present_hours) as total_present, SUM(absent_hours) as total_absent
FROM employee_activity
GROUP BY course, employee_name, MONTH(activity_date);
```

**Flag validated data:**
```sql
UPDATE employee_activity
SET validated = 1
WHERE ... -- your validation logic here
```

---

## 📝 Best Practices & Recommendations

- **Version Control:**  
  Keep all ETL scripts, SQL DDL, and documentation under version control (e.g., Git).

- **Testing:**  
  Test each ETL step with sample data before running on production data.

- **Error Handling:**  
  Add error handling and logging in ETL scripts for easier debugging.

- **Extensibility:**  
  Design ETL scripts to be modular so new sources or business rules can be added easily.

---

## 📚 Further Documentation

- **`etl/` directory:**  
  Contains all ETL scripts for each data source.
- **`SQL_ETL_Pipeline_Project_July.sql`:**  
  Full DDL for database and tables.
- **`scheduler.py`:**  
  Main orchestrator for the ETL pipeline.
- **`README.md`:**  
  This documentation file—update it with every major change or new data source.

---

For DML we use real data, so I'm not going to share that here, but you can populate the tables and the csv files however you like.
So, the .env, the CSVs in data/attendance and the DML for your database are not included here.
