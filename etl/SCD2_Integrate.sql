USE DavaX;
GO

-- start_date = starting date of validity of a version of a row
-- end_date =  ending date of validity of a version of a row
-- is_current = flag that shows if a row is the current one
ALTER TABLE reporting.dim_employee
ADD 
    start_date DATE DEFAULT GETDATE(),
    end_date DATE DEFAULT '9999-12-31',
    is_current BIT DEFAULT 1;
GO

IF OBJECT_ID('reporting.trg_scd2_dim_employee', 'TR') IS NOT NULL
    DROP TRIGGER reporting.trg_scd2_dim_employee;
GO

-- create a trigger so that when someone inserts data into dim_employee we check:
-- if there is already a row with that email and is_current = 1, if so, then we compare the field and we insert the new version if we find differences
-- if there is no such row, we insert the new value
CREATE TRIGGER trg_scd2_dim_employee
ON reporting.dim_employee
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- mark existent rows as invalid if they are different
    UPDATE reporting.dim_employee
    SET 
        is_current = 0,
        end_date = GETDATE()
    FROM reporting.dim_employee de
    JOIN inserted i ON i.email = de.email
    WHERE de.is_current = 1
      AND (
            ISNULL(de.full_name, '')     <> ISNULL(i.full_name, '') OR
            ISNULL(de.department, '')    <> ISNULL(i.department, '') OR
            ISNULL(de.grade, '')         <> ISNULL(i.grade, '') OR
            ISNULL(de.manager, '')       <> ISNULL(i.manager, '') OR
            ISNULL(de.discipline, '')    <> ISNULL(i.discipline, '')
          );

    --insert new row (only if it does not already exist or its data has changed)
    INSERT INTO reporting.dim_employee (
        full_name,
        email,
        department,
        grade,
        manager,
        discipline,
        start_date,
        end_date,
        is_current
    )
    SELECT 
        i.full_name,
        i.email,
        i.department,
        i.grade,
        i.manager,
        i.discipline,
        GETDATE(),
        '9999-12-31',
        1
    FROM inserted i
    LEFT JOIN reporting.dim_employee de
        ON i.email = de.email AND de.is_current = 1
    WHERE de.employee_id IS NULL
       OR (
            ISNULL(de.full_name, '')     <> ISNULL(i.full_name, '') OR
            ISNULL(de.department, '')    <> ISNULL(i.department, '') OR
            ISNULL(de.grade, '')         <> ISNULL(i.grade, '') OR
            ISNULL(de.manager, '')       <> ISNULL(i.manager, '') OR
            ISNULL(de.discipline, '')    <> ISNULL(i.discipline, '')
       );
END;
GO


-- trigger for update
CREATE TRIGGER reporting.trg_scd2_dim_employee_update
ON reporting.dim_employee
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE de
    SET 
        is_current = 0,
        end_date = GETDATE()
    FROM reporting.dim_employee de
    JOIN inserted i ON i.employee_id = de.employee_id
    JOIN deleted d ON d.employee_id = de.employee_id
    WHERE de.is_current = 1
      AND (
            ISNULL(d.full_name, '')     <> ISNULL(i.full_name, '') OR
            ISNULL(d.email, '')         <> ISNULL(i.email, '') OR
            ISNULL(d.department, '')    <> ISNULL(i.department, '') OR
            ISNULL(d.grade, '')         <> ISNULL(i.grade, '') OR
            ISNULL(d.manager, '')       <> ISNULL(i.manager, '') OR
            ISNULL(d.discipline, '')    <> ISNULL(i.discipline, '')
          );

    INSERT INTO reporting.dim_employee (
        full_name,
        email,
        department,
        grade,
        manager,
        discipline,
        start_date,
        end_date,
        is_current
    )
    SELECT 
        i.full_name,
        i.email,
        i.department,
        i.grade,
        i.manager,
        i.discipline,
        GETDATE(),        -- start_date
        '9999-12-31',     -- end_date
        1                 -- is_current
    FROM inserted i
    JOIN deleted d ON i.employee_id = d.employee_id
    WHERE
        ISNULL(d.full_name, '')     <> ISNULL(i.full_name, '') OR
        ISNULL(d.email, '')         <> ISNULL(i.email, '') OR
        ISNULL(d.department, '')    <> ISNULL(i.department, '') OR
        ISNULL(d.grade, '')         <> ISNULL(i.grade, '') OR
        ISNULL(d.manager, '')       <> ISNULL(i.manager, '') OR
        ISNULL(d.discipline, '')    <> ISNULL(i.discipline, '');
END;
GO
