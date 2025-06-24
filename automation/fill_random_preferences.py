import firebase_admin
from firebase_admin import credentials, firestore
import random
from datetime import datetime

SERVICE_ACCOUNT_PATH = 'serviceAccount.json'
MANAGER_ID = "DktfbiurbVuF1KKcMVQbRzGcyf2"
EVENT_PREFIX = "evt_auto_"  # לשנות אם צריך

FEATURES_BY_TYPE = {
    'Classroom/Workshop': ['Board', 'Air Conditioner', 'Window', 'Entrance'],
    'Family/Social Event': ['Dance Floor', 'Speakers', 'Exit'],
    'Conference/Professional Event': [
        'Stage', 'Writing Table', 'Screen', 'Charging Point'
    ]
}

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

events = db.collection('events').stream()
auto_events = []
for event_doc in events:
    if event_doc.id.startswith(EVENT_PREFIX):
        auto_events.append(event_doc)

print(f"נמצאו {len(auto_events)} אירועי אוטומציה.")

for event_doc in auto_events:
    event_data = event_doc.to_dict()
    event_id = event_doc.id
    event_type = event_data['eventType']
    event_name = event_data.get('eventName', 'אירוע')
    options_list = FEATURES_BY_TYPE[event_type]

    # שלוף את כל המשתתפים של האירוע
    participants_query = db.collection('events').document(event_id).collection('participants').stream()
    participants = [p.to_dict() for p in participants_query]
    all_names = [p['name'] for p in participants]

    for p in participants:
        phone = p['phone']
        name = p['name']

        # העדפות רנדומליות
        options = {opt: random.choice([True, False]) for opt in options_list}

        others = [n for n in all_names if n != name]
        preferToList = random.sample(others, k=random.randint(0, min(2, len(others))))
        preferNotToList = [n for n in others if n not in preferToList]
        preferNotToList = random.sample(preferNotToList, k=random.randint(0, min(2, len(preferNotToList))))
        showInLists = True  # כאן תמיד True

        now = datetime.utcnow().isoformat()

        pref_data = {
            "eventId": event_id,
            "eventName": event_name,
            "eventType": event_type,
            "options": options,
            "preferToList": preferToList,
            "preferNotToList": preferNotToList,
            "showInLists": showInLists,
            "createdAt": now,
            "updatedAt": now
        }

        db.collection('users').document(phone).collection('preferences').document(event_id).set(pref_data)
        print(f'Updated preferences for {name} ({phone}) in event {event_id}')

print("העדפות נוצרו עם showInLists=True אצל כל המשתתפים באירועי האוטומציה.")
