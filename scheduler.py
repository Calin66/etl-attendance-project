import logging
from etl.extract import extract_attendance_data_to_db

logging.basicConfig(level=logging.INFO)

print("[SCHEDULER] ETL started")

if __name__ == "__main__":
    extract_attendance_data_to_db()
