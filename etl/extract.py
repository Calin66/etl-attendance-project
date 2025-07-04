import requests
from ics import Calendar
import pandas as pd
from datetime import datetime
from pathlib import Path
import logging
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

DB_URL = os.getenv("DB_URL")
DATA_DIR = Path(__file__).resolve().parent.parent / "data"
ATTENDANCE_DIR = DATA_DIR / "attendance"

# ===============
# Attendance CSVs
# ===============
def load_attendance_csv(file: Path) -> pd.DataFrame:
    with open(file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Extract course title from line starting with "Meeting title"
    course = None
    for line in lines:
        if line.strip().startswith("Meeting title"):
            parts = line.strip().split(",", 1)
            if len(parts) > 1:
                course = parts[1].strip()
            break

    # Skip header lines and load participant data
    df = pd.read_csv(file, skiprows=9, encoding="utf-8")
    df.columns = [c.strip() for c in df.columns]
    df = df.rename(columns={
        "Name": "full_name",
        "First Join": "start_time",
        "Last Leave": "end_time",
        "In-Meeting Duration": "duration_str",
        "Email": "email"
    })
    df['email'] = df['email'].str.strip().str.lower()
    df['course'] = course
    return df


def clean_attendance(df: pd.DataFrame, file_name: str) -> pd.DataFrame:
    def duration_to_minutes(s):
        if pd.isna(s):
            return 0
        parts = s.split(' ')
        total = 0
        for part in parts:
            if 'h' in part:
                total += int(part.replace('h', '')) * 60
            elif 'm' in part:
                total += int(part.replace('m', ''))
        return total

    df['duration_minutes'] = df['duration_str'].apply(duration_to_minutes)
    df['source_dataset'] = file_name
    df['load_timestamp'] = pd.Timestamp.now()

    dt_format = "%m/%d/%y, %I:%M:%S %p"

    df['date_day'] = pd.to_datetime(df['start_time'], format=dt_format, errors='coerce').dt.date
    df['start_time'] = pd.to_datetime(df['start_time'], format=dt_format, errors='coerce')
    df['end_time'] = pd.to_datetime(df['end_time'], format=dt_format, errors='coerce')
    return df


def save_attendance_to_db(df: pd.DataFrame, engine):
    final_df = df[[
        'full_name', 'email', 'date_day',
        'start_time', 'end_time', 'duration_minutes',
        'source_dataset', 'course', 'load_timestamp'
    ]]
    final_df.to_sql("attendance", con=engine, schema="sources", if_exists="append", index=False)
    logging.info(f"[SAVE] Inserted {len(final_df)} rows into sources.attendance.")


def extract_attendance_data_to_db():
    try:
        engine = create_engine(DB_URL)
        all_files = list(ATTENDANCE_DIR.glob("*.csv"))
        for file in all_files:
            try:
                df = load_attendance_csv(file)
                df = clean_attendance(df, file.name)
                save_attendance_to_db(df, engine)
            except Exception as e:
                logging.warning(f"[PROCESS] Failed {file.name}: {e}")
    except Exception as e:
        logging.error(f"[EXTRACT] Attendance DB insertion failed: {e}")
