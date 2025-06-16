import random
import pandas as pd
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore

# אתחול firebase
cred = credentials.Certificate('serviceAccountKey.json')  # ודא שהקובץ נמצא ליד הסקריפט
firebase_admin.initialize_app(cred)
db = firestore.client()

# אפשרויות רנדומליות
event_types = ["Classroom/Workshop", "Family/Social Event", "Conference/Professional Event"]
locations = ["Tel Aviv", "Jerusalem", "Haifa", "Ashdod", "Netanya"]
event_names = ["Tech Meetup", "Birthday Party", "Family Gathering", "Conference Day", "Workshop Session"]

def create_random_events(num_events=30):
    events = []
    for i in range(num_events):
        event_id = f"event_{random.randint(100000,999999)}"
        event = {
            "event_id": event_id,
            "name": random.choice(event_names) + f" #{i+1}",
            "type": random.choice(event_types),
            "datetime": (datetime.now() + timedelta(days=random.randint(1,60))).strftime('%Y-%m-%d %H:%M'),
            "location": random.choice(locations),
            "participants_csv": f"participants_{event_id}.csv"
        }
        events.append(event)
    return events

# יצירת 30 אירועים
events = create_random_events(30)

# שמירת הנתונים לקובץ CSV (אופציונלי)
df = pd.DataFrame(events)
df.to_csv("random_events.csv", index=False)
print("30 אירועים נוצרו ונשמרו בקובץ random_events.csv")

# הכנסת האירועים ל-Firestore
for event in events:
    doc_ref = db.collection('events').document(event['event_id'])
    doc_ref.set({
        'eventName': event['name'],
        'eventType': event['type'],
        'dateTime': event['datetime'],
        'location': event['location'],
        'createdAt': firestore.SERVER_TIMESTAMP,
        # תוכל להוסיף כאן עוד שדות רלוונטיים
    })
print("כל האירועים נוצרו גם ב-Firestore!")
