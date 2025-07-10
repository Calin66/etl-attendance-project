USE DavaX;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'reporting')
    EXEC('CREATE SCHEMA reporting');
GO

-- Dimension: dim_date
CREATE TABLE reporting.dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE UNIQUE,
    year INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    weekday_name VARCHAR(20),
    is_weekend BIT,
    week_number INT
);
GO

-- Dimension: dim_employee
CREATE TABLE reporting.dim_employee (
    employee_id INT IDENTITY PRIMARY KEY,
    full_name NVARCHAR(255),
    email NVARCHAR(255),
    department NVARCHAR(100),
    grade NVARCHAR(100),
    manager NVARCHAR(255),
    discipline NVARCHAR(255)
);
GO

-- Dimension: dim_course
CREATE TABLE reporting.dim_course (
    course_id INT IDENTITY PRIMARY KEY,
    course_name NVARCHAR(255)
);
GO

-- Dimension: dim_project
CREATE TABLE reporting.dim_project (
    project_id INT IDENTITY PRIMARY KEY,
    project_code NVARCHAR(50)
);
GO

-- Fact Table: fact_employee_activity
CREATE TABLE reporting.fact_employee_activity (
    activity_id INT IDENTITY PRIMARY KEY,
    employee_id INT NOT NULL,
    date_id INT NOT NULL,
    course_id INT NULL,
    project_id INT NULL,
    activity_type NVARCHAR(50),
    absent_hours FLOAT,
    present_hours FLOAT,
    source_system NVARCHAR(50),
    validated BIT DEFAULT 0,
    last_update DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (employee_id) REFERENCES reporting.dim_employee(employee_id),
    FOREIGN KEY (date_id) REFERENCES reporting.dim_date(date_id),
    FOREIGN KEY (course_id) REFERENCES reporting.dim_course(course_id),
    FOREIGN KEY (project_id) REFERENCES reporting.dim_project(project_id)
);
GO