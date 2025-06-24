import firebase_admin
from firebase_admin import credentials, firestore
import json

# שם קובץ הסקריפט: export_event_with_subcollections.py

cred = credentials.Certificate("serviceAccount.json")  # השם של הקובץ שהורדת מה-Firebase
firebase_admin.initialize_app(cred)
db = firestore.client()

def get_subcollection_docs(doc_ref, subcol_name):
    col_ref = doc_ref.collection(subcol_name)
    docs = col_ref.stream()
    return [doc.to_dict() | {"_id": doc.id} for doc in docs]

def export_event(event_id):
    # שלב 1: שליפת האירוע הראשי
    doc_ref = db.collection("events").document(event_id)
    doc = doc_ref.get()
    if not doc.exists:
        print(f"Event {event_id} not found")
        return

    event_data = doc.to_dict()
    event_data["_id"] = doc.id

    # שלב 2: שליפת תתי-קולקשן נפוצים
    for subcol in ["participants", "elements"]:
        event_data[subcol] = get_subcollection_docs(doc_ref, subcol)

    # (אם יש לך תתי-קולקשן נוספים, תוסיף לרשימה למעלה)

    # שלב 3: שמירה לקובץ JSON
    with open(f"{event_id}_export.json", "w", encoding="utf-8") as f:
        json.dump(event_data, f, ensure_ascii=False, indent=2)
    print(f"Exported {event_id}_export.json")

# הרץ את הפונקציה כאן
if __name__ == "__main__":
    # שנה כאן ל-ID של אירוע שתרצה לייצא
    EVENT_ID = "kjTEh0VxZqKj21j72s6F"
    export_event(EVENT_ID)
