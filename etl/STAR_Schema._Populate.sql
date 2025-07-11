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

-- -- ========================
-- -- Populate dim_project
-- -- ========================
-- INSERT INTO reporting.dim_project (project_code)
-- SELECT DISTINCT project_code
-- FROM employee_activity
-- WHERE project_code IS NOT NULL;
-- GO

-- ========================
-- Populate fact_employee_activity 
-- ========================
INSERT INTO reporting.fact_employee_activity (
    employee_id, date_id, course_id,
    -- project_id,
    activity_type, absent_hours, present_hours,
    source_system, validated
)
SELECT 
    emp.employee_id,
    CAST(FORMAT(ea.activity_date, 'yyyyMMdd') AS INT),
    crs.course_id,
    -- prj.project_id,
    ea.activity_type,
    ea.absent_hours,
    ea.present_hours,
    ea.source,
    ea.validated
FROM employee_activity ea
JOIN reporting.dim_employee emp 
    ON TRIM(LOWER(emp.full_name)) = TRIM(LOWER(ea.employee_name))
LEFT JOIN reporting.dim_course crs ON crs.course_name = ea.course;
-- LEFT JOIN reporting.dim_project prj ON prj.project_code = ea.project_code;
