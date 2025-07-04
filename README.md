
# ETL Attendance Project

An ETL pipeline for extracting, cleaning, and loading attendance and absence employee data from exported meeting CSV files (e.g. Zoom, Teams) and data bases into a SQL Server database (`DavaX`).

## 📦 Project Structure

```
etl-attendance-project/
├── data/                    # Base directory for raw data files
├── etl/                     # Core ETL logic (extract, transform, load)
│   ├── extract.py
│   ├── scheduler.py
│   └── ...
├── scheduler.py          # Main entry point for running the ETL
├── requirements.txt
├── Dockerfile
├── .env
└── README.md
```

## ⚙️ Setup

### Environment Variables

Create a `.env` file in the root:

```
DB_URL=mssql+pyodbc://sa:YourStrong!Passw0rd@host.docker.internal/DavaX?driver=ODBC+Driver+17+for+SQL+Server
```

## 🐳 Running with Docker

### Build the container:

```
docker build -t etl-attendance-project .
```

### Run the pipeline:

```
docker run --rm -v "$(pwd)/data/attendance:/app/attendance" --env-file .env etl-attendance-project
```

---

## 🧠 What It Does

- Loads `.csv` files from `/data/attendance`
- Extracts full name, email, join/leave time, duration, etc.
- Parses session title and source dataset
- Converts data to a clean format
- Inserts into SQL Server: `sources.attendance`

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


### SQL Database

Make sure to have SSMS opened and connected to your database.
Also, this is the DDL SQL for the SQL Database.

-- Create the database and set it as active, then create the schema

    create database DavaX;
    go

    use DavaX;
    go

    create schema sources;
    go

-- Employees table (minimal complexity)

    create table sources.angajati (
        angajat_id int identity primary key,
        nume varchar(100) not null,
        email varchar(100) unique,
        department varchar(100),
        grade varchar(100),
        manager_id int
    );

-- Timesheets table (minimal complexity)

    create table sources.timesheets (
        pontaj_id int identity primary key,
        angajat_id int,
        date_day date,
        duration_hours int not null check (duration_hours < 20),
        location_work varchar(10) check (location_work in ('office', 'remote')) default 'remote',
        foreign key (angajat_id) references sources.angajati(angajat_id)
    );

-- Table where attendance from CSVs will be loaded

    create table sources.attendance (
        attendance_id int identity primary key,
        full_name varchar(255),
        email varchar(255),
        date_day date,
        start_time datetime,
        end_time datetime,
        duration_minutes int,
        source_dataset varchar(255),
        course varchar(255),
        load_timestamp datetime default getdate()
    );


-- Table for absences (the third data source for the ETL)

    create table sources.absences (
        absence_id int identity primary key,
        angajat_id int,
        date_day date,
        reason varchar(100),
        foreign key (angajat_id) references sources.angajati(angajat_id)
    );


-- 
-- Queries will be implemented differently in the target schema (it will be a star schema).
-- This part is only checking if there's enough data in the source for those future queries.
--

-- 1. Course absence detection:
--    Group by course or source_dataset (source_dataset will help you if you want the attendance at a specific meet as opposed to the entire course series),
--    and count how many employees are missing from the attendance table.

-- 2. What did employee X do on day Y:
--    First check the absences table — if present, that's your answer.
--    If not, check the attendance table. If not found there either, mark as "missing".
--    Ideally, you'd track if the person was supposed to attend, but for now just flag it.

-- SCD Type 2 (Slowly Changing Dimensions):
-- You will track historical changes for:
-- - grade
-- - manager_id
-- - department

For DML we use real data, so I'm not going to share that here, but you can populate the tables and the csv files however you like.
