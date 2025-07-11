USE DavaX;
GO

-- how many absences and presences were made for each course in a week
SELECT 
    c.course_name,
    d.year,
    d.week_number,
    SUM(fa.present_hours) AS total_present_hours,
    SUM(fa.absent_hours) AS total_absent_hours
FROM reporting.fact_employee_activity fa
JOIN reporting.dim_course c ON fa.course_id = c.course_id
JOIN reporting.dim_date d ON fa.date_id = d.date_id
GROUP BY 
    c.course_name, d.year, d.week_number
ORDER BY 
    c.course_name, d.year, d.week_number;

-- average absent hours for each employee per month
SELECT 
    e.full_name,
    d.year,
    d.month,
    AVG(fa.absent_hours) AS avg_absent_hours
FROM reporting.fact_employee_activity fa
JOIN reporting.dim_employee e ON fa.employee_id = e.employee_id
JOIN reporting.dim_date d ON fa.date_id = d.date_id
GROUP BY 
    e.full_name, d.year, d.month
ORDER BY 
    e.full_name, d.year, d.month;

-- top 5 employees with the most absences in a month
SELECT TOP 5
    e.full_name,
    d.year,
    d.month,
    SUM(fa.absent_hours) AS total_absent_hours
FROM reporting.fact_employee_activity fa
JOIN reporting.dim_employee e ON fa.employee_id = e.employee_id
JOIN reporting.dim_date d ON fa.date_id = d.date_id
GROUP BY 
    e.full_name, d.year, d.month
ORDER BY 
    total_absent_hours DESC;

-- name of employees who has absences in a specific week
SELECT DISTINCT
    e.full_name,
    d.year,
    d.week_number
FROM reporting.fact_employee_activity fa
JOIN reporting.dim_employee e ON fa.employee_id = e.employee_id
JOIN reporting.dim_date d ON fa.date_id = d.date_id
WHERE fa.absent_hours > 0
  AND d.year = 2025
  AND d.week_number = 27;

-- -- on what project did a specific person work on a specific day. 
-- -- we chose not to implement project functionality to avoid unnecessary complexity on this project
-- SELECT 
--     e.full_name,
--     d.full_date,
--     p.project_code,
--     fa.present_hours
-- FROM reporting.fact_employee_activity fa
-- JOIN reporting.dim_employee e ON fa.employee_id = e.employee_id
-- JOIN reporting.dim_date d ON fa.date_id = d.date_id
-- JOIN reporting.dim_project p ON fa.project_id = p.project_id
-- WHERE e.full_name = 'Daria Alexia Irimie'
--   AND d.full_date = '2025-07-09'
--   AND fa.present_hours > 0;

-- how many leave days an employee took in a specific month
SELECT
    a.angajat_id,
    an.nume,
    DATENAME(MONTH, a.date_day) AS luna,
    YEAR(a.date_day) AS an,
    COUNT(*) AS zile_leave
FROM sources.absences a
JOIN sources.angajati an ON a.angajat_id = an.angajat_id
WHERE a.reason = 'Leave'
  AND MONTH(a.date_day) = 6 
  AND YEAR(a.date_day) = 2025
GROUP BY a.angajat_id, an.nume, DATENAME(MONTH, a.date_day), YEAR(a.date_day)
ORDER BY zile_leave DESC;