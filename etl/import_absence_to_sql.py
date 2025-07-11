def import_absence_to_sql():
    import pandas as pd
    import os
    from sqlalchemy import create_engine
    from dotenv import load_dotenv

    load_dotenv()
    db_url = os.getenv("DB_URL")
    engine = create_engine(db_url)

    df = pd.read_csv("./data/exam_absence/absence_list.csv")
    df['activity_type'] = 'absence'
    df['source'] = 'confluence'
    df['validated'] = 0

    df.rename(columns={
        'attendees': 'employee_name',
        'date': 'activity_date'
    }, inplace=True)

    # Normalize for join
    df['employee_name'] = df['employee_name'].str.strip().str.upper()
    df['activity_date'] = pd.to_datetime(df['activity_date']).dt.date

    # Get course from sources.attendance (by employee_name and activity_date)
    attendance = pd.read_sql(
        "SELECT full_name AS employee_name, date_day AS activity_date, course FROM sources.attendance",
        engine
    )
    attendance['employee_name'] = attendance['employee_name'].str.strip().str.upper()
    attendance['activity_date'] = pd.to_datetime(attendance['activity_date']).dt.date

    df = pd.merge(df, attendance, on=['employee_name', 'activity_date'], how='left')

    # Get discipline and manager from sources.angajati (by employee_name)
    angajati = pd.read_sql(
        "SELECT nume AS employee_name, department AS discipline, manager_id FROM sources.angajati",
        engine
    )
    angajati['employee_name'] = angajati['employee_name'].str.strip().str.upper()
    df = pd.merge(df, angajati, on='employee_name', how='left')
    df['discipline'] = df['discipline']
    df['manager'] = df['manager_id']

    # Ensure absent_hours exists and is numeric
    if 'absent_hours' not in df.columns:
        df['absent_hours'] = 1  # or the correct value from your data

    df['absent_hours'] = pd.to_numeric(df['absent_hours'], errors='coerce').fillna(0)

    # Calculate present_hours as 8 - absent_hours, but not less than 0
    df['present_hours'] = (8 - df['absent_hours']).clip(lower=0)

    columns = [
        'employee_name', 'activity_date', 'activity_type', 'course',
        'absent_hours', 'present_hours', 'source', 'validated', 'discipline', 'manager'
    ]
    df = df[columns]

    df.to_sql('employee_activity', engine, if_exists='append', index=False)
    print("Absence data imported into SQL table employee_activity.")