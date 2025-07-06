import os
import re
import pandas as pd
import numpy as np
from datetime import datetime

# Script for parsing our ICS calendar file.
# Core idea:
# 0. The ICS exporter inserts some newlines here and there; first clean them up.
# 1. Then parse ICS file line-by-line until "BEGIN:VEVENT" is found.
# 2. Look for "DTSTART" and "DTEND" lines to get the start and end times. (In YYYYMMDDTHHMMSS format)
# 3. Look for "SUMMARY" line to get the event title.
# 4. Look for "CATEGORIES" line to get the event category (Events - 'other' / Leave - 'leaves' / UniTask - 'UniTask').
# 5. Look for "DESCRIPTION" line to get the event description (optional).
# 6. Look for "ATENDEE" lines - fetch person name from "CN=" and email from "mailto:".
#   (If no attendees are found, grab the "ORGANIZER" line for details instead.)
# 7. Once "END:VEVENT" is found, declare event complete and add to list.

def parse_ics(file_path):
    with open(file_path, 'r', encoding='utf-8') as ics_file:
        # This might be a bit big, but we should be
        # able to load it all into memory.
        # (If not, we can try a chunked approach.)
        content = ics_file.read()

        # Split content into event chunks between BEGIN:VEVENT and END:VEVENT
        event_chunks = re.findall(r'BEGIN:VEVENT(.*?)END:VEVENT', content, re.DOTALL)

        events = []
        for chunk in event_chunks:
            # The exporter seems to split some lines into multiples, primarily
            # ATTENDEE and ORGANIZER lines. There isn't a very consistent pattern
            # of *where* it cuts, but it seems to always insert a newline and a space
            # when it does.
            #
            # We clean up by removing those, which should allow one-line
            # parsing of ATTENDEE and ORGANIZER lines without breaking
            # the actual data like names.
            chunk = re.sub(r'\n ', '', chunk)

            current_event = {
                "start": None,
                "end": None,
                "title": None,
                "categories": None,
                "description": None,
                "attendees": [],
                "organizer": None
            }

            # Most things we can parse line-by-line
            for line in chunk.splitlines():
                line = line.strip()

                # Event start/end
                if line.startswith("DTSTART"):
                    current_event["start"] = line.split(":", 1)[1]
                elif line.startswith("DTEND"):
                    current_event["end"] = line.split(":", 1)[1]
                
                # Event details
                elif line.startswith("SUMMARY"):
                    current_event["title"] = line.split(":", 1)[1]
                elif line.startswith("CATEGORIES"):
                    current_event["categories"] = line.split(":", 1)[1]
                elif line.startswith("DESCRIPTION"):
                    current_event["description"] = line.split(":", 1)[1]
                
                # Attendees/Organizer
                elif line.startswith("ATTENDEE;"):
                    parts = line.split(";")
                    name = parts[2].split("CN=")[-1]  # Name is third part, after CN=
                    email = parts[3].split("mailto:")[-1]  # Email is in fourth part, after mailto:
                    current_event["attendees"].append({"name": name, "email": email})
                elif line.startswith("ORGANIZER;"):
                    parts = line.split(";")
                    name = parts[2].split("CN=")[-1]  # Name is third part, after CN=
                    email = parts[3].split("mailto:")[-1]  # Email is in fourth part, after mailto:
                    current_event["organizer"] = {"name": name, "email": email}

            events.append(current_event)
        
        return events

def print_event(event):
    print(f"Event: {event['title']}")
    print(f"Start: {event['start']}")
    print(f"End: {event['end']}")
    print(f"Categories: {event['categories']}")
    print(f"Description: {event['description']}")
    print("Attendees:")
    for attendee in event['attendees']:
        print(f"  - {attendee['name']} <{attendee['email']}>")
    if event['organizer']:
        print(f"Organizer: {event['organizer']['name']} <{event['organizer']['email']}>")
    print("-" * 40)

def generate_absence_matrix(csv_path):
    df = pd.read_csv(csv_path)
    df['attendees'] = df['attendees'].astype(str)
    df = df[df['attendees'] != '']

    # Extrage data din 'start'
    df['date'] = df['start'].apply(lambda x: x.split('T')[0] if 'T' in str(x) else str(x)[:8])
    # Convertește la tip datetime
    df['date'] = pd.to_datetime(df['date'], format='%Y%m%d')

    def calc_hours(row):
        start = str(row['start'])
        end = str(row['end'])
        if 'T' in start and 'T' in end:
            try:
                start_time = datetime.strptime(start, "%Y%m%dT%H%M%S")
                end_time = datetime.strptime(end, "%Y%m%dT%H%M%S")
                hours = (end_time - start_time).total_seconds() / 3600
                return round(hours, 2)
            except Exception:
                return 8
        else:
            return 8

    df['absent_hours'] = df.apply(calc_hours, axis=1)
    df['attendees'] = df['attendees'].str.split(', ')
    df = df.explode('attendees')

    # Pivot table: index=attendees, columns=date (datetime), values=absent_hours
    matrix = df.pivot_table(index='attendees', columns='date', values='absent_hours', aggfunc='sum', fill_value=0)
    matrix = matrix.sort_index(axis=1)  # sortează coloanele după dată

    # Salvează matricea
    matrix.to_csv("./data/exam_absence/absence_matrix.csv")
    print("Absence matrix saved to ./data/exam_absence/absence_matrix.csv")
    return matrix

def extract_calendar_events():
    print("ICS Calendar Parser demo")

    # Înlocuiește selectarea grafică cu o cale directă către fișierul .ics
    file_path = "./data/exam_absence/cld_data.ics"
    # Sau folosește input de la tastatură:
    # file_path = input("Introdu calea către fișierul .ics: ")

    if not file_path:
        print("No file selected.")
        exit()

    # Parse the ICS file
    results = parse_ics(file_path)

    # Display
    if not results:
        print("No events found in the selected ICS file.")
    else:
        all_good = True
        for event in results:
            # Check if any event has incomplete data
            if not event['start'] or not event['end']:
                print('Event with incomplete times!')
                print_event(event)
                all_good = False
            if not event['title']:
                print('Event with no title!')
                print_event(event)
                all_good = False
            if not event['categories']:
                print('Event with no category!')
                print_event(event)
                all_good = False
            if not event['attendees'] and not event['organizer']:
                print('Event with no participants!')
                print_event(event)
                all_good = False

        if all_good:
            print("All events parsed successfully and with no missing data!")
            for event in results:
                print_event(event)
    
     # Transform the list of events into a DataFrame
    df = pd.DataFrame(results)

    # Normalize columns for attendees and organizer (optional: only names)
    df['attendees'] = df['attendees'].apply(lambda lst: ', '.join([a['name'] for a in lst]) if lst else '')
    df['organizer'] = df['organizer'].apply(lambda o: o['name'] if o else '')

    # Save to CSV
    df.to_csv("./data/exam_absence/calendar_events.csv", index=False)
    print("Events have been saved to calendar_events.csv")

    generate_absence_matrix("./data/exam_absence/calendar_events.csv")

    # Save the list (long format) directly as a separate CSV
    matrix = pd.read_csv("./data/exam_absence/absence_matrix.csv", index_col=0)
    long_df = matrix.reset_index().melt(id_vars='attendees', var_name='date', value_name='absent_hours')
    long_df.to_csv("./data/exam_absence/absence_list.csv", index=False)
    print("Absence list saved to ./data/exam_absence/absence_list.csv")
