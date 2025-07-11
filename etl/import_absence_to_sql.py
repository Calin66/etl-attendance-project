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
    df['course'] = None
    df['present_hours'] = 0
    df['source'] = 'confluence'
    df['validated'] = 0
    df['discipline'] = None
    df['manager'] = None

    df.rename(columns={
        'attendees': 'employee_name',
        'date': 'activity_date'
    }, inplace=True)

    df.to_sql('employee_activity', engine, if_exists='append', index=False)
    print("Absence data imported into SQL table employee_activity.")