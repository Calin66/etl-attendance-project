import logging
import os
from etl.extract import extract_attendance_data_to_db
from etl.download_ics import download_ics_file
from etl.extract_calendar import extract_calendar_events
from etl.import_absence_to_sql import import_absence_to_sql

logging.basicConfig(level=logging.INFO)

print("[SCHEDULER] ETL started")

if __name__ == "__main__":
    extract_attendance_data_to_db()
    download_ics_file()
    extract_calendar_events()
    import_absence_to_sql()