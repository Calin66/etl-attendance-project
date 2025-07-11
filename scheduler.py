import os
import logging

# ------------------------------
# STEP 1: Configure logging first
# ------------------------------
def configure_logger():
    os.makedirs("logs", exist_ok=True)

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # Clear any existing handlers that may have been added by earlier imports
    if logger.hasHandlers():
        logger.handlers.clear()

    file_handler = logging.FileHandler("logs/etl.log", mode="a", encoding="utf-8")
    file_handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(file_handler)

    # Optional: test line
    logging.info("✅ Logging setup complete from scheduler.py")

configure_logger()

# ------------------------------
# STEP 2: Import other modules
# ------------------------------
from etl.extract import extract_attendance_data_to_db
from etl.download_ics import download_ics_file
from etl.extract_calendar import extract_calendar_events
from etl.import_absence_to_sql import import_absence_to_sql

print("[SCHEDULER] ETL started")

# ------------------------------
# STEP 3: Run the ETL pipeline
# ------------------------------
if __name__ == "__main__":
    extract_attendance_data_to_db()
    download_ics_file()
    extract_calendar_events()
    import_absence_to_sql()
