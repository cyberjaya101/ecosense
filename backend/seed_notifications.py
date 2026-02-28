import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# 1. Initialize Firebase
try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    exit(1)

db = firestore.client()

# 2. Mock Notifications Data
# Types: POINTS, REWARD, ACHIEVEMENT, INFO
NOTIFICATIONS = [
    {
        "type": "POINTS",
        "title": "Eco-Points Awarded!",
        "message": "Admin verified your Ghost Room report for DK1. +150 points added.",
        "timestamp": datetime.now(),
        "isRead": False
    },
    {
        "type": "ACHIEVEMENT",
        "title": "New Level: Amethyst!",
        "message": "You've crossed 5,000 total points. New rewards unlocked in the wallet.",
        "timestamp": datetime.now(),
        "isRead": False
    },
    {
        "type": "REWARD",
        "title": "Reward Redeemed",
        "message": "Your 10% Hostel Rebate application is being processed.",
        "timestamp": datetime.now(),
        "isRead": False
    },
    {
        "type": "POINTS",
        "title": "Points Pending",
        "message": "Your 'Too Cold' report for Library Zone B has been received.",
        "timestamp": datetime.now(),
        "isRead": False
    }
]

def seed_notifications():
    student_id = "alex_rivera"
    print(f"Seeding notifications for {student_id}...")
    
    notif_ref = db.collection("users").document(student_id).collection("notifications")
    
    # Optional: Clear existing notifications for a clean demo
    # docs = notif_ref.stream()
    # for doc in docs:
    #     doc.reference.delete()

    for n in NOTIFICATIONS:
        notif_ref.add(n)
        print(f"Created: {n['title']}")
    
    print("\nSeeding Complete! Click the Notification Bell in the app to see them.")

if __name__ == "__main__":
    seed_notifications()
