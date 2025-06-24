import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import os
import math

SERVICE_ACCOUNT_PATH = "serviceAccount.json"
cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
try:
    firebase_admin.get_app()
except ValueError:
    firebase_admin.initialize_app(cred)
db = firestore.client()

NEIGHBOR_RADIUS = 165

def are_neighbors(c1, c2):
    dx = c1['x'] - c2['x']
    dy = c1['y'] - c2['y']
    dist = math.sqrt(dx * dx + dy * dy)
    return 0 < dist <= NEIGHBOR_RADIUS

def analyze_event(event_id):
    # --- שלב 1: נתוני האירוע ---
    event_doc = db.collection("events").document(event_id).get().to_dict()
    if not event_doc:
        print(f"לא נמצא אירוע: {event_id}")
        return []

    allowed = event_doc.get('allowedParticipants', [])
    elements_ref = db.collection("events").document(event_id).collection("elements")
    chairs = []
    chair_by_phone = {}
    for doc in elements_ref.where('type', '==', 'chair').stream():
        d = doc.to_dict()
        chairs.append(d)
        occupant = d.get('occupiedBy')
        if occupant:
            chair_by_phone[occupant] = d

    # מיפוי שם ↔ טלפון
    participants_ref = db.collection("events").document(event_id).collection("participants")
    name_to_phone = {}
    phone_to_name = {}
    for doc in participants_ref.stream():
        d = doc.to_dict()
        name = d.get('name')
        phone = d.get('phone')
        if name and phone:
            name_to_phone[name] = phone
            phone_to_name[phone] = name

    results = []

    for phone in allowed:
        pref_doc = db.collection("users").document(phone).collection("preferences").document(event_id).get()
        if not pref_doc.exists:
            continue
        pref = pref_doc.to_dict()
        prefer_to_names = set(pref.get('preferToList', []))
        avoid_to_names = set(pref.get('preferNotToList', []))
        prefer_to_phones = set(name_to_phone.get(name) for name in prefer_to_names if name_to_phone.get(name))
        avoid_to_phones = set(name_to_phone.get(name) for name in avoid_to_names if name_to_phone.get(name))
        options = pref.get('options', {})

        my_chair = chair_by_phone.get(phone)
        if not my_chair:
            continue

        my_neighbors = set()
        for c in chairs:
            if c is my_chair:
                continue
            occupant = c.get('occupiedBy')
            if occupant and are_neighbors(my_chair, c):
                my_neighbors.add(occupant)

        got_wanted_neighbor = True if not prefer_to_phones else bool(prefer_to_phones & my_neighbors)
        avoided_unwanted = True if not avoid_to_phones else not (avoid_to_phones & my_neighbors)
        requested_features = set(k for k, v in options.items() if v)
        actual_features = set(my_chair.get('features', []))
        features_matched = bool(requested_features & actual_features) if requested_features else None

        results.append({
            "event_id": event_id,
            "name": phone_to_name.get(phone, ""),
            "phone": phone,
            "prefer_to_names": list(prefer_to_names),
            "prefer_to_phones": list(prefer_to_phones),
            "got_wanted_neighbor": got_wanted_neighbor,
            "avoid_to_names": list(avoid_to_names),
            "avoid_to_phones": list(avoid_to_phones),
            "avoided_unwanted": avoided_unwanted,
            "requested_features": list(requested_features),
            "actual_features": list(actual_features),
            "features_matched": features_matched,
            "neighbor_names": [phone_to_name.get(p, p) for p in my_neighbors],
            "neighbor_phones": list(my_neighbors)
        })
    return results

# --- אוסף את כל האירועים שנוצרו ע"י הסקריפט (לפי שם) ---
all_events = []
for doc in db.collection("events").stream():
    if doc.id.startswith("evt_auto_"):
        all_events.append(doc.id)

all_rows = []
for event_id in all_events:
    print(f"Analyzing {event_id} ...")
    all_rows.extend(analyze_event(event_id))

df = pd.DataFrame(all_rows)
output_path = "seating_analysis_all_auto_events.csv"
df.to_csv(output_path, index=False, encoding='utf-8-sig')
os.startfile(output_path)
print(f"הקובץ נוצר: {output_path}")
