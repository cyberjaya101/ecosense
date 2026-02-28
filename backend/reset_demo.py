import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def reset_demo():
    print("🔄 STARTING FULL SYSTEM RESET...")

    # 1. Reset Room Summaries
    print("📍 Resetting Room Summaries (Waste, Feedback, Status)...")
    rooms_ref = db.collection("room_summaries")
    rooms = rooms_ref.stream()
    
    batch = db.batch()
    for doc in rooms:
        batch.update(doc.reference, {
            "status": "stable",
            "status_color": "GREEN",
            "internal_temp": 24.0,
            "occupancy": 5,
            "accumulated_hours_unresolved": 0,
            "total_estimated_ringgit_waste": 0.0,
            "recent_qualitative_feedback": [],
            "pending_action": firestore.DELETE_FIELD
        })
    batch.commit()

    # 2. Reset Campus State (Predictions)
    print("🔮 Clearing Predictive Scheduler...")
    db.collection("campus_state").doc("daily_prediction").delete()

    # 3. Reset User Profiles (Eco-Points)
    print("🏆 Wiping Student Eco-Points...")
    users_ref = db.collection("users")
    users = users_ref.stream()
    batch = db.batch()
    for doc in users:
        batch.update(doc.reference, {
            "total_eco_points": 0,
            "pending_eco_points": 0
        })
    batch.commit()

    print("\n✅ SYSTEM IS CLEAN. Ready for Demo Act 1.")

if __name__ == "__main__":
    reset_demo()