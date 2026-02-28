import firebase_admin
from firebase_admin import credentials, firestore

# 1. Initialize Firebase
try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    exit(1)

db = firestore.client()

# 2. Mock Users Data
# We create users at different 'tiers' to show off the progress bars in the Wallet
MOCK_USERS = [
    {
        "id": "student_elite",
        "name": "Sustainability Pro",
        "total_eco_points": 9250, # Almost at Tier 3 (Hostel Rebate)
        "major": "Environmental Science"
    },
    {
        "id": "student_active",
        "name": "Frequent Reporter",
        "total_eco_points": 4800, # Almost at Tier 2 (Certificate)
        "major": "Engineering"
    },
    {
        "id": "student_newbie",
        "name": "Eco Learner",
        "total_eco_points": 850, # Almost at Tier 1 (Cafe Voucher)
        "major": "Computer Science"
    },
    {
        "id": "alex_rivera", # The default ID used in our snippets
        "name": "Alex Rivera",
        "total_eco_points": 6250, # Diamond Tier
        "major": "FCSIT"
    }
]

def seed_users():
    print("Seeding mock users into Firestore...")
    for user in MOCK_USERS:
        user_id = user["id"]
        db.collection("users").document(user_id).set(user)
        print(f"Created user: {user_id} with {user['total_eco_points']} points.")
    
    print("\nSeeding Complete! The Wallet tab will now show populated progress bars.")

if __name__ == "__main__":
    seed_users()
