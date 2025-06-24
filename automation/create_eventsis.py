import firebase_admin
from firebase_admin import credentials, firestore
import random
from datetime import datetime, timedelta
from copy import deepcopy
import json

SERVICE_ACCOUNT_PATH = 'serviceAccount.json'  # שנה לשם הקובץ שלך
NUM_EVENTS = 30
MANAGER_ID = "DtNrcOw7HFb24UhSsBNdVhoFogb2"
FEATURES_BY_TYPE = {
    'Classroom/Workshop': ['Board', 'Air Conditioner', 'Window', 'Entrance'],
    'Family/Social Event': ['Dance Floor', 'Speakers', 'Exit'],
    'Conference/Professional Event': [
        'Stage', 'Writing Table', 'Screen', 'Charging Point'
    ]
}
EVENT_TYPES = list(FEATURES_BY_TYPE.keys())
LOCATIONS = ["אשדוד", "תל אביב", "חיפה", "ירושלים", "באר שבע"]

# טען תבנית אירוע
with open("template_event.json", "r", encoding="utf-8") as f:
    TEMPLATE = json.load(f)

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

def random_features(event_type):
    possible = FEATURES_BY_TYPE[event_type]
    n = random.randint(0, len(possible))
    return random.sample(possible, n)

def make_event(idx):
    event = deepcopy(TEMPLATE)
    event_id = f"evt_auto_{idx+1:03d}"
    event_type = random.choice(EVENT_TYPES)
    event["eventType"] = event_type
    event["managerId"] = MANAGER_ID
    event["eventName"] = f"אירוע בדיקה {idx+1}"
    event["location"] = random.choice(LOCATIONS)
    base_dt = datetime.now() + timedelta(days=idx)
    event["date"] = base_dt.strftime("%Y-%m-%d")
    event["time"] = base_dt.strftime("%H:%M")
    event["preferenceDeadline"] = (base_dt - timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:00.000")
    event["createdAt"] = base_dt.isoformat()
    event["_id"] = event_id

    # משתתפים (קופי מלא)
    event["participants"] = deepcopy(TEMPLATE["participants"])
    event["allowedParticipants"] = deepcopy(TEMPLATE["allowedParticipants"])

    # elements – רק features משתנה
    elements = []
    for elem in TEMPLATE["elements"]:
        new_elem = deepcopy(elem)
        if new_elem["type"] == "chair":
            new_elem["features"] = random_features(event_type)
        elements.append(new_elem)
    event["elements"] = elements

    return event_id, event

for i in range(NUM_EVENTS):
    event_id, event = make_event(i)
    doc_ref = db.collection("events").document(event_id)

    # --- יצירת מסמך האירוע הראשי ---
    event_doc = dict(event)
    event_doc.pop("participants", None)
    event_doc.pop("elements", None)
    doc_ref.set(event_doc)

    # --- תת-קולקציה participants ---
    for p in event["participants"]:
        p_doc_id = p.get("_id", None) or db.collection("events").document(event_id).collection("participants").document().id
        pdata = dict(p)
        pdata.pop("_id", None)
        doc_ref.collection("participants").document(p_doc_id).set(pdata)

    # --- תת-קולקציה elements ---
    for e in event["elements"]:
        e_doc_id = e.get("id") or db.collection("events").document(event_id).collection("elements").document().id
        edata = dict(e)
        edata.pop("_id", None)
        doc_ref.collection("elements").document(e_doc_id).set(edata)

    # --- הוספת האירוע ל-managers/{managerId}/events/{eventId} ---
    manager_event_doc = {
        "ref": event_id,
        "eventName": event["eventName"],
        "eventType": event["eventType"],
        "location": event["location"],
        "date": event["date"],
        "time": event["time"],
        "createdAt": event["createdAt"],
    }
    db.collection("managers").document(MANAGER_ID).collection("events").document(event_id).set(manager_event_doc)

    print(f"נוצר אירוע: {event_id} (כולל managers)")

print("כל האירועים נוצרו בהצלחה ב-Firestore! (כולל managers)")
