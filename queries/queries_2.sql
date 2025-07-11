-- 1. Monthly Department Attendance Summary
-- Description: For each department and each month between Jan-Jun 2025, shows total present and absent hours.
WITH months AS (
    SELECT DISTINCT
            YEAR(full_date)   AS [year],
            MONTH(full_date)  AS [month],
            DATENAME(MONTH, full_date) AS month_name
    FROM reporting.dim_date
    WHERE full_date BETWEEN '2025-01-01' AND '2025-06-30'
),
departments AS (
    SELECT DISTINCT department
    FROM reporting.dim_employee
),
agg AS (
    SELECT
            dd.[year],
            dd.[month],
            de.department,
            SUM(fa.present_hours) AS total_present_hours,
            SUM(fa.absent_hours)  AS total_absent_hours
    FROM reporting.fact_employee_activity AS fa
    JOIN reporting.dim_date     AS dd ON fa.date_id     = dd.date_id
    JOIN reporting.dim_employee AS de ON fa.employee_id = de.employee_id
    WHERE dd.full_date BETWEEN '2025-01-01' AND '2025-06-30'
    GROUP BY
            dd.[year],
            dd.[month],
            de.department
)
SELECT
        m.[year],
        m.[month],
        m.month_name,
        d.department,
        COALESCE(a.total_present_hours, 0) AS total_present_hours,
        COALESCE(a.total_absent_hours,  0) AS total_absent_hours
FROM months      AS m
CROSS JOIN departments AS d
LEFT JOIN agg     AS a
    ON a.[year]       = m.[year]
 AND a.[month]      = m.[month]
 AND a.department   = d.department
ORDER BY
        m.[year],
        m.[month],
        d.department;


-- 2. Running Total of Present Hours per Employee
-- Description: For each employee and date, shows present hours and running total of present hours up to that date.
SELECT
        de.employee_id,
        de.full_name,
        dd.full_date,
        fa.present_hours,
        SUM(fa.present_hours) 
            OVER (
                PARTITION BY de.employee_id
                ORDER BY dd.full_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS running_present_hours
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_employee       AS de
    ON fa.employee_id = de.employee_id
JOIN reporting.dim_date           AS dd
    ON fa.date_id     = dd.date_id
-- optionally restrict to a date window:
-- WHERE dd.full_date BETWEEN '2025-01-01' AND '2025-06-30'
ORDER BY
        de.employee_id,
        dd.full_date;


-- 3. Projects Worked on by Employee for a Specific Date
-- Description: Lists all projects an employee worked on for a given date, with present and absent hours.
DECLARE 
        @EmployeeID INT = 68,           -- Employee ID to filter (Check fact_employee_activity for valid IDs)
        @WorkDate   DATE = '2025-04-06'; -- Date to filter (Check fact_employee_activity for date_id)

SELECT
        de.employee_id,
        de.full_name,
        dd.full_date,
        -- dp.project_code,
        fa.present_hours,
        fa.absent_hours
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_employee       AS de
    ON fa.employee_id = de.employee_id
JOIN reporting.dim_date           AS dd
    ON fa.date_id     = dd.date_id
-- JOIN reporting.dim_project        AS dp
--     ON fa.project_id  = dp.project_id
WHERE 
        de.employee_id = @EmployeeID
        AND dd.full_date = @WorkDate
        -- AND fa.activity_type = 'Project'  -- filter by activity type
ORDER BY
        fa.present_hours DESC;


-- 4. Weekly Course Attendance Summary
-- Description: For each course and week, shows total present and absent hours for course activities.
SELECT
        dd.[year]                       AS An,
        dd.week_number                  AS Saptamana,
        dc.course_name                  AS Curs,
        SUM(fa.present_hours)           AS TotalOrePrezente,
        SUM(fa.absent_hours)            AS TotalOreAbsente
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_date           AS dd
    ON fa.date_id     = dd.date_id
JOIN reporting.dim_course         AS dc
    ON fa.course_id   = dc.course_id
WHERE fa.activity_type = 'Course'
GROUP BY
        dd.[year],
        dd.week_number,
        dc.course_name
ORDER BY
        dd.[year],
        dd.week_number,
        dc.course_name;

-- 5. Monthly Course Attendance Summary
SELECT
    dd.[year]                       AS An,
    dd.[month]                      AS Luna,
    dd.month_name                   AS NumeLuna,
    dc.course_name                  AS Curs,
    SUM(fa.present_hours)           AS TotalOrePrezente,
    SUM(fa.absent_hours)            AS TotalOreAbsente
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_date           AS dd
  ON fa.date_id   = dd.date_id
JOIN reporting.dim_course         AS dc
  ON fa.course_id = dc.course_id
WHERE fa.activity_type = 'Course'
GROUP BY
    dd.[year],
    dd.[month],
    dd.month_name,
    dc.course_name
ORDER BY
    dd.[year],
    dd.[month],
    dc.course_name;

-- 6. Weekly Course Attendance Summary
SELECT
    dd.[year]                       AS An,
    dd.week_number                  AS Saptamana,
    dc.course_name                  AS Curs,
    SUM(fa.present_hours)           AS TotalOrePrezente,
    SUM(fa.absent_hours)            AS TotalOreAbsente
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_date           AS dd
  ON fa.date_id   = dd.date_id
JOIN reporting.dim_course         AS dc
  ON fa.course_id = dc.course_id
WHERE fa.activity_type = 'Course'
GROUP BY
    dd.[year],
    dd.week_number,
    dc.course_name
ORDER BY
    dd.[year],
    dd.week_number,
    dc.course_name;

-- 7. Running Total of Present Hours per Employee
SELECT
    fa.employee_id,
    de.full_name,
    dd.full_date,
    fa.present_hours,
    SUM(fa.present_hours) 
      OVER (
        PARTITION BY fa.employee_id
        ORDER BY dd.full_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_total_present_hours
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_employee       AS de
  ON fa.employee_id = de.employee_id
JOIN reporting.dim_date           AS dd
  ON fa.date_id     = dd.date_id
ORDER BY
    fa.employee_id,
    dd.full_date;

-- 8. Missing Dates for Employees
DECLARE 
    @startDate DATE = '2025-01-01',  -- adjust as needed
    @endDate   DATE = '2025-06-30';  -- adjust as needed

SELECT
    de.employee_id,
    de.full_name,
    dd.full_date           AS missing_date
FROM reporting.dim_employee AS de
CROSS JOIN (
    SELECT date_id, full_date
    FROM reporting.dim_date
    WHERE full_date BETWEEN @startDate AND @endDate
) AS dd
LEFT JOIN reporting.fact_employee_activity AS fa
  ON fa.employee_id = de.employee_id
 AND fa.date_id     = dd.date_id
WHERE fa.employee_id IS NULL
ORDER BY
    de.employee_id,
    dd.full_date;


-- 9. Courses‐taken counts per department
SELECT
    de.department,
    COUNT(*)                     AS total_course_enrollments,
    COUNT(DISTINCT fa.course_id) AS distinct_courses_offered,
    COUNT(DISTINCT fa.employee_id) AS employees_participated
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_employee       AS de
  ON fa.employee_id = de.employee_id
WHERE fa.activity_type = 'Course'
GROUP BY
    de.department
ORDER BY
    de.department;

-- 10. Median Present Hours per Day
SELECT DISTINCT
    dd.full_date,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY fa.present_hours) 
      OVER (PARTITION BY dd.full_date) AS median_present_hours
FROM reporting.fact_employee_activity AS fa
JOIN reporting.dim_date               AS dd
  ON fa.date_id = dd.date_id
ORDER BY
    dd.full_date;






