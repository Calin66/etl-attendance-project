USE DavaX;
GO

-- ========================
-- Populate dim_date
-- ========================
;WITH Dates AS (
    SELECT CAST('2024-01-01' AS DATE) AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM Dates
    WHERE full_date < '2026-12-31'
)
INSERT INTO reporting.dim_date (date_id, full_date, year, month, month_name, day, weekday_name, is_weekend, week_number)
SELECT 
    CAST(FORMAT(full_date, 'yyyyMMdd') AS INT),
    full_date,
    YEAR(full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    DAY(full_date),
    DATENAME(WEEKDAY, full_date),
    CASE WHEN DATENAME(WEEKDAY, full_date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END,
    DATEPART(WEEK, full_date)
FROM Dates
OPTION (MAXRECURSION 10000);
GO

-- ========================
-- Populate dim_employee
-- ========================
INSERT INTO reporting.dim_employee (full_name, email, department, grade)
SELECT DISTINCT nume, email, department, grade
FROM sources.angajati
WHERE email IS NOT NULL;
GO

-- ========================
-- Populate dim_course
-- ========================
INSERT INTO reporting.dim_course (course_name)
SELECT DISTINCT course
FROM employee_activity
WHERE course IS NOT NULL;
GO

-- ========================
-- Populate dim_project
-- ========================
INSERT INTO reporting.dim_project (project_code)
SELECT DISTINCT project_code
FROM employee_activity
WHERE project_code IS NOT NULL;
GO

-- ========================
-- Populate fact_employee_activity 
-- ========================
INSERT INTO reporting.fact_employee_activity (
    employee_id, date_id, course_id, project_id,
    activity_type, absent_hours, present_hours,
    source_system, validated
)
SELECT 
    emp.employee_id,
    CAST(FORMAT(ea.activity_date, 'yyyyMMdd') AS INT),
    crs.course_id,
    prj.project_id,
    ea.activity_type,
    ea.absent_hours,
    ea.present_hours,
    ea.source,
    ea.validated
FROM employee_activity ea
JOIN reporting.dim_employee emp 
    ON TRIM(LOWER(emp.full_name)) = TRIM(LOWER(ea.employee_name))
LEFT JOIN reporting.dim_course crs ON crs.course_name = ea.course
LEFT JOIN reporting.dim_project prj ON prj.project_code = ea.project_code;


--testing SCD2

-- dummy test with some hardcoded data
-- we insert some dummy data that was not in the table before, you should notice that 'is_current' field is 1
INSERT INTO reporting.dim_employee (full_name, email, department, grade, manager, discipline)
VALUES ('Ana Ionescu', 'ana@endava.com', 'IT', 'M2', 'ion.pop@endava.com', 'Data');

-- test for insert: we move the emplyee in another department, the previous row now has is_current = 0, so its no longer valid, and
-- the new inserted one has is_current=1 with the new department.
INSERT INTO reporting.dim_employee (full_name, email, department, grade, manager, discipline)
VALUES ('Ana Ionescu', 'ana@endava.com', 'HR', 'M2', 'ion.pop@endava.com', 'Data');

INSERT INTO reporting.dim_employee (full_name, email, department, grade, manager, discipline)
VALUES ('Mihai Dumitrescu', 'mihai@endava.com', 'Finance', 'M2', 'alex.ionescu@endava.com', 'Ops');

--test for update
UPDATE reporting.dim_employee
SET department = 'IT'
WHERE email = 'mihai@endava.com' AND is_current = 1;

--Verify the table creation and data population 
SELECT 'dim_employee' AS table_name, COUNT(*) AS row_count FROM reporting.dim_employee
UNION ALL
SELECT 'dim_date', COUNT(*) FROM reporting.dim_date
UNION ALL
SELECT 'dim_course', COUNT(*) FROM reporting.dim_course
UNION ALL
SELECT 'dim_project', COUNT(*) FROM reporting.dim_project
UNION ALL
SELECT 'fact_employee_activity', COUNT(*) FROM reporting.fact_employee_activity;
