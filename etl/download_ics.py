import os
import requests
from dotenv import load_dotenv
from getpass import getpass

load_dotenv()

def download_ics_file():
    ICS_URL = os.getenv("ICS_URL")
    if not ICS_URL:
        print("ICS_URL is missing from .env!")
        return False

    response = requests.get(ICS_URL)
    if response.status_code != 200:
        print(f"Download error: {response.status_code} - {response.reason}")
        return False

    os.makedirs("./data/exam_absence", exist_ok=True)
    with open("./data/exam_absence/cld_data.ics", "w", encoding="utf-8") as f:
        f.write(response.text)
    print("The .ics file was downloaded successfully.")
    return True