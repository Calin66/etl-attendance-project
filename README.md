# ETL Attendance Project

An ETL pipeline for extracting, cleaning, and loading attendance and absence employee data from exported meeting CSV files (e.g. Zoom, Teams), relational databases and other sources into one SQL Server database (`DavaX`).

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

### Environment Variables

Create a `.env` file in the root with YOUR PASSWORD for the database, this is mine (it's local):

```
DB_URL=mssql+pyodbc://sa:YourStrong!Passw0rd@host.docker.internal/DavaX?driver=ODBC+Driver+17+for+SQL+Server
```
---

### 📂 Input Files & Folder Structure

- **Create the folder structure before running the pipeline:**  
  Make sure the `data/attendance` folder exists on your host machine before running Docker.  
  Place the required `.csv` files (attendance/absence exports) inside `data/attendance`.

- **Environment variable for ICS calendar:**  
  In your `.env` file, add the direct link to your ICS calendar as `ICS_URL`.
  This URL should be accessible without authentication, or you must adapt the pipeline for your authentication method.

---

If you want to create a new database / image and have the same SSMS setup as me, run: 

```
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong!Passw0rd" -p 1433:1433 --name sqlserver -d mcr.microsoft.com/mssql/server:latest
```

Make sure you have ODBC Driver for SQL Server from Microsoft installed. Version 17.


## 🐳 Running with Docker

### Build the container:

```
docker build -t etl-attendance-project .
```

### Run the pipeline:

```
docker run --rm -v "${PWD}/data:/app/data" -v "${PWD}/logs:/app/logs" --env-file .env etl-attendance-project
```

---

### Order in which to run SQL scripts

1. Source_Create.sql (and your DML)
2. Star_Schema_Create
3. SCD2_Integrate
4. Star_Schema_Populate

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

Use this SQL to confirm connection:

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

## 🔄 Data Flow Overview

1. **Raw Data Ingestion:**  
   - All raw files (CSV, Excel, ICS) are placed in the `/data` directory structure.
   - The pipeline expects specific file names and formats for each data source.

2. **ETL Execution:**  
   - The scheduler orchestrates the ETL steps: downloading, parsing, transforming, and loading data into SQL.
   - Each ETL step is modular and can be extended for new sources.

3. **SQL Database Population:**  
   - The SQL script (`Source_Create.sql`) creates all necessary tables and schemas.
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
SELECT course, MONTH(activity_date) as month, SUM(present_hours) as total_present, SUM(absent_hours) as total_absent
FROM employee_activity
GROUP BY course, MONTH(activity_date);
```

**Flag validated data:**
```sql
UPDATE employee_activity
SET validated = 1
WHERE ... -- your validation logic here
```

---

## 📚 Further Documentation

- **`etl/` directory:**  
  Contains all ETL scripts for each data source.
- **`scheduler.py`:**  
  Main orchestrator for the ETL pipeline.
- **`README.md`:**  
  This documentation file—update it with every major change or new data source.

The format of the .csv files in data/attendance.

```
1. Summary,,,,,,
Meeting title,Dava.X Academy - ETL Theory training sessions,,,,,
Attended participants,328,,,,,
Start time,"6/24/25, 1:47:45 PM",,,,,
End time,"6/24/25, 3:46:52 PM",,,,,
Meeting duration,1h 59m 6s,,,,,
Average attendance time,1h 30m 52s,,,,,
,,,,,,
2. Participants,,,,,,
Name,First Join,Last Leave,In-Meeting Duration,Email,Participant ID (UPN),Role
```