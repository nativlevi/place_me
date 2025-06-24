import firebase_admin
from firebase_admin import credentials, firestore
import json
from google.cloud.firestore_v1.base_document import DocumentSnapshot
from google.protobuf.timestamp_pb2 import Timestamp

cred = credentials.Certificate("serviceAccount.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def clean_firestore_types(data):
    """הופך Timestamp ודומיו ל־string באופן רקורסיבי"""
    if isinstance(data, dict):
        return {k: clean_firestore_types(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [clean_firestore_types(i) for i in data]
    elif hasattr(data, 'isoformat'):
        # DatetimeWithNanoseconds
        return data.isoformat()
    return data

def get_subcollection_docs(doc_ref, subcol_name):
    col_ref = doc_ref.collection(subcol_name)
    docs = col_ref.stream()
    return [clean_firestore_types(doc.to_dict() | {"_id": doc.id}) for doc in docs]

def export_event(event_id):
    doc_ref = db.collection("events").document(event_id)
    doc = doc_ref.get()
    if not doc.exists:
        print(f"Event {event_id} not found")
        return

    event_data = clean_firestore_types(doc.to_dict())
    event_data["_id"] = doc.id

    for subcol in ["participants", "elements"]:
        event_data[subcol] = get_subcollection_docs(doc_ref, subcol)

    with open(f"{event_id}_export.json", "w", encoding="utf-8") as f:
        json.dump(event_data, f, ensure_ascii=False, indent=2)
    print(f"Exported {event_id}_export.json")

if __name__ == "__main__":
    EVENT_ID = "M9PFzp7LeuGHfHX86ymO"
    export_event(EVENT_ID)
