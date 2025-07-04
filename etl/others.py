
# # ========================================
# # Confluence Exam & Absence Schedule CLD
# # ========================================

# TIMESHEET_DIR = DATA_DIR / "timesheets"
# ICS_URL = os.getenv("ICS_URL")

# def download_calendar():
#     try:
#         logging.info("[EXTRACT] Downloading calendar...")
#         response = requests.get(ICS_URL)
#         response.raise_for_status()

#         calendar = Calendar(response.text)
#         events = []

#         for e in calendar.events:
#             try:
#                 name_parts = e.name.split(':', 1)
#                 nume = name_parts[0].strip()
#                 eveniment = name_parts[1].strip() if len(name_parts) > 1 else ''
#                 events.append({
#                     'nume': nume,
#                     'eveniment': eveniment,
#                     'summary': e.name.strip(),
#                     'start': e.begin.datetime,
#                     'end': e.end.datetime,
#                     'duration': (e.end - e.begin).total_seconds() / 60,
#                     'description': e.description or ''
#                 })
#             except Exception as event_error:
#                 logging.warning(f"[EXTRACT] Could not parse event: {e.name}. Error: {event_error}")
#                 continue

#         df = pd.DataFrame(events)
#         today = datetime.now().date()
#         output_path = DATA_DIR / f"calendar_raw_{today}.csv"
#         df.to_csv(output_path, index=False)
#         logging.info(f"[EXTRACT] Exported calendar to {output_path}")
#         return df

#     except Exception as e:
#         logging.error(f"[EXTRACT] Failed to download or parse calendar: {e}")
#         return pd.DataFrame()

# # ==========
# # Timesheets
# # ==========

# def extract_timesheet_data():
#     try:
#         engine = create_engine(DB_URL)
#         query = """
#         SELECT 
#             p.pontaj_id,
#             a.angajat_id,
#             a.nume AS angajat,
#             pj.nume AS proiect,
#             t.nume AS task,
#             p.ziua,
#             p.ore,
#             p.locatie,
#             p.pontaj_status,
#             p.comentarii
#         FROM pontaje p
#         JOIN angajati a ON p.angajat_id = a.angajat_id
#         JOIN taskuri t ON p.task_id = t.task_id
#         JOIN proiecte pj ON t.proiect_id = pj.proiect_id
#         """
#         df = pd.read_sql(query, con=engine)
#         TIMESHEET_DIR.mkdir(parents=True, exist_ok=True)
#         df.to_csv(TIMESHEET_DIR / "from_rdbms.csv", index=False)
#         logging.info(f"[EXTRACT] Timesheets exportate cu {len(df)} rânduri.")
#         return df

#     except Exception as e:
#         logging.error(f"[EXTRACT] Failed to extract timesheet data: {e}")
#         return pd.DataFrame()
