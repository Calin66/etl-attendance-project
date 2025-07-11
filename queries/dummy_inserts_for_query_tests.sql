USE DavaX;
GO
-- Dummy inserts for testing queries since we do not have courses or projects in the source data.
 
-- ================================================
-- 1) Fill reporting.dim_date for a date range
-- ================================================
DECLARE
    @startDate DATE = '2020-01-01',
    @endDate   DATE = '2025-12-31';
 
;WITH calendar AS (
    SELECT @startDate AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
      FROM calendar
     WHERE full_date < @endDate
)
INSERT INTO reporting.dim_date
    (date_id, full_date, year, month, month_name, day, weekday_name, is_weekend, week_number)
SELECT
    CONVERT(INT, FORMAT(full_date, 'yyyyMMdd')) AS date_id,
    full_date,
    YEAR(full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    DAY(full_date),
    DATENAME(WEEKDAY, full_date),
    CASE WHEN DATENAME(WEEKDAY, full_date) IN ('Saturday','Sunday') THEN 1 ELSE 0 END,
    DATEPART(WEEK, full_date)
FROM calendar
OPTION (MAXRECURSION 0);
GO
 
 
-- ================================================
-- 2) Generate N random employees
-- ================================================
DECLARE @NumEmployees INT = 100;  -- adjust as needed
 
;WITH nums AS (
    SELECT TOP (@NumEmployees)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO reporting.dim_employee
    (full_name, email, department, grade, manager, discipline)
SELECT
    'Employee ' + RIGHT('000' + CAST(n AS VARCHAR), 3)                     AS full_name,
    LOWER('employee' + CAST(n AS VARCHAR) + '@endava.com')                AS email,
    CASE n % 5
        WHEN 0 THEN 'IT'
        WHEN 1 THEN 'HR'
        WHEN 2 THEN 'Finance'
        WHEN 3 THEN 'Marketing'
        ELSE 'Operations'
    END                                                                    AS department,
    CASE n % 4
        WHEN 0 THEN 'Junior'
        WHEN 1 THEN 'Mid'
        WHEN 2 THEN 'Senior'
        ELSE 'Lead'
    END                                                                    AS grade,
    'Manager ' + CAST((n % 10) + 1 AS VARCHAR)                             AS manager,
    CASE n % 6
        WHEN 0 THEN 'Engineering'
        WHEN 1 THEN 'Data'
        WHEN 2 THEN 'QA'
        WHEN 3 THEN 'Design'
        WHEN 4 THEN 'Support'
        ELSE 'Product'
    END                                                                    AS discipline
FROM nums;
GO
  
-- ================================================
-- 3) Seed some courses
-- ================================================
INSERT INTO reporting.dim_course (course_name)
VALUES
    ('SQL Basics'),
    ('Data Warehousing'),
    ('ETL Development'),
    ('Power BI Fundamentals'),
    ('Data Modeling'),
    ('Azure Data Factory'),
    ('Python for Data Engineering');
GO

-- -- ================================================
-- -- 4) Seed some projects. (we chose not to pursue projects)
-- -- ================================================
-- INSERT INTO reporting.dim_project (project_code)
-- VALUES
--     ('PRJ001'),
--     ('PRJ002'),
--     ('PRJ003'),
--     ('PRJ004'),
--     ('PRJ005'),
--     ('PRJ006'),
--     ('PRJ007');
-- GO
 
 

-- ================================================
-- 5) Populate fact_employee_activity with random Course-only activity
-- ================================================
DECLARE @NumFacts INT = 1000;   -- adjust as needed

;WITH
    E AS (SELECT employee_id FROM reporting.dim_employee),
    D AS (SELECT date_id
          FROM reporting.dim_date
          WHERE full_date BETWEEN '2025-01-01' AND '2025-06-30'),  -- narrow the date slice
    C AS (SELECT course_id FROM reporting.dim_course),
    N AS (SELECT TOP (@NumFacts)
                 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
          FROM sys.all_objects)
INSERT INTO reporting.fact_employee_activity
    (employee_id, date_id, course_id, activity_type,
     absent_hours, present_hours, source_system, validated)
SELECT
    e.employee_id,
    d.date_id,
    c.course_id,
    'Course' AS activity_type,
    CAST(RAND(CHECKSUM(NEWID())) * 2 AS DECIMAL(5,2)) AS absent_hours,
    CAST(RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(5,2)) AS present_hours,
    'LMS' AS source_system,
    CASE WHEN RAND(CHECKSUM(NEWID())) > 0.7 THEN 1 ELSE 0 END AS validated
FROM N
CROSS APPLY (SELECT TOP 1 * FROM E ORDER BY NEWID()) AS e
CROSS APPLY (SELECT TOP 1 * FROM D ORDER BY NEWID()) AS d
CROSS APPLY (SELECT TOP 1 * FROM C ORDER BY NEWID()) AS c;
GO


-- -- ================================================
-- -- 5) Populate fact_employee_activity with random picks. Removed projects functionality for now.
-- -- ================================================
-- DECLARE @NumFacts INT = 1000;   -- adjust as needed
 
-- ;WITH
--     E AS (SELECT employee_id FROM reporting.dim_employee),
--     D AS (SELECT date_id
--             FROM reporting.dim_date
--            WHERE full_date BETWEEN '2025-01-01' AND '2025-06-30'),  -- narrow the date slice
--     C AS (SELECT course_id FROM reporting.dim_course),
--     P AS (SELECT project_id FROM reporting.dim_project),
--     N AS (SELECT TOP (@NumFacts)
--                  ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
--           FROM sys.all_objects)
-- INSERT INTO reporting.fact_employee_activity
--     (employee_id, date_id, course_id, project_id, activity_type,
--      absent_hours, present_hours, source_system, validated)
-- SELECT
--     e.employee_id,
--     d.date_id,
--     CASE WHEN rndType = 1 THEN c.course_id ELSE NULL END,
--     CASE WHEN rndType = 2 THEN p.project_id ELSE NULL END,
--     CASE WHEN rndType = 1 THEN 'Course' ELSE 'Project' END,
--     CAST(RAND(CHECKSUM(NEWID())) * 2 AS DECIMAL(5,2)) AS absent_hours,
--     CAST(RAND(CHECKSUM(NEWID())) * 8 AS DECIMAL(5,2)) AS present_hours,
--     CASE WHEN rndType = 1 THEN 'LMS' ELSE 'PM' END           AS source_system,
--     CASE WHEN RAND(CHECKSUM(NEWID())) > 0.7 THEN 1 ELSE 0 END AS validated
-- FROM (
--     SELECT
--         n,
--         -- randomly choose 1 = course-based, 2 = project-based
--         ABS(CAST(CHECKSUM(NEWID()) AS INT)) % 2 + 1 AS rndType
--     FROM N
-- ) AS t
-- CROSS APPLY (SELECT TOP 1 * FROM E ORDER BY NEWID()) AS e
-- CROSS APPLY (SELECT TOP 1 * FROM D ORDER BY NEWID()) AS d
-- CROSS APPLY (SELECT TOP 1 * FROM C ORDER BY NEWID()) AS c
-- CROSS APPLY (SELECT TOP 1 * FROM P ORDER BY NEWID()) AS p;
-- GO