import firebase_admin
from firebase_admin import credentials, firestore
import random
from datetime import datetime
import sys
import math

# 1. Initialize Firebase
try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    print("Please ensure 'serviceAccountKey.json' is present.")
    exit(1)

db = firestore.client()

# 2. Configuration & Metadata
FUNCTIONAL_ROOMS = {
    "DK1": {
        "lat": 3.1285, "lng": 101.6508, "building": "FCSIT Block A",
        "description": "Large lecture hall, central AC. Gets overcrowded during peak hours.",
        "temps": {"Normal": 20, "Heatwave": 24, "Monsoon": 24},
        "image_url": "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80"
    },
    "24h Study": {
        "lat": 3.1213, "lng": 101.6570, "building": "Library Cluster",
        "description": "24-hour open study space. High student turnover, frequently packed during exam season.",
        "temps": {"Normal": 22, "Heatwave": 22, "Monsoon": 18},
        "image_url": "https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=800"
    },
    "Lounge": {
        "lat": 3.1282, "lng": 101.6507, "building": "FCSIT Block B",
        "description": "Student lounge and social space. Often left with AC running after hours.",
        "ac_units": 4,
        "temps": {"Normal": 19, "Heatwave": 28, "Monsoon": 23},
        "image_url": "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800&q=80"
    },
    "Examination Hall": {
        "lat": 3.1112, "lng": 101.6565, "building": "Exam Complex",
        "description": "Large examination hall with 12 AC units. Requires strict temperature control for exam conditions.",
        "ac_units": 12,
        "temps": {"Normal": 18, "Heatwave": 20, "Monsoon": 16},
        "image_url": "https://images.unsplash.com/photo-1519452575417-564c1401ecc0?q=80&w=800"
    },
    "Faculty of Engineering": {
        "lat": 3.1172, "lng": 101.6624, "building": "FK Tower",
        "description": "High-density lab space with heavy computing equipment generating significant heat load.",
        "ac_units": 6,
        "temps": {"Normal": 24, "Heatwave": 26, "Monsoon": 22},
        "image_url": "https://images.unsplash.com/photo-1581094794329-c8112a89af12?q=80&w=800"
    },
    "Science Lecture Hall": {
        "lat": 3.1235, "lng": 101.6552, "building": "FS Block C",
        "description": "South-facing glass facade with direct noon sun exposure. AC units struggle to compensate during peak heat. Room is not broken, just underpowered for extreme heat conditions.",
        "ac_units": 3,
        "temps": {"Normal": 22, "Heatwave": 24, "Monsoon": 20},
        "image_url": "https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=800"
    }
}

NPC_ROOMS = [
    {"id": "um_one_stop_centre", "location": "One Stop Centre", "lat": 3.1216, "lng": 101.6566, "image_url": "https://images.unsplash.com/photo-1606761568499-6d2451b23c66?q=80&w=800"},
    {"id": "um_library", "location": "UM Central Library", "lat": 3.1211, "lng": 101.6572, "image_url": "https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=800"},
    {"id": "um_gym", "location": "UM Gymnasium", "lat": 3.1272, "lng": 101.6558, "image_url": "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=800"},
    {"id": "fcsit_dk2", "location": "FCSIT Block A - DK2", "lat": 3.1286, "lng": 101.6510, "image_url": "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80"},
    {"id": "dtc_um", "location": "Dewan Tunku Canselor", "lat": 3.1212, "lng": 101.6591, "image_url": "https://upload.wikimedia.org/wikipedia/commons/4/4b/Dewan_Tunku_Canselor_UM_2021_04.jpg"},
    {"id": "rimba_ilmu", "location": "Rimba Ilmu", "lat": 3.1292, "lng": 101.6582, "image_url": "https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?q=80&w=800"},
    {"id": "perdanasiswa", "location": "Perdanasiswa (KPS)", "lat": 3.1221, "lng": 101.6578, "image_url": "https://images.unsplash.com/photo-1519452575417-564c1401ecc0?q=80&w=800"},
    {"id": "varsity_lake", "location": "UM Varsity Lake", "lat": 3.1215, "lng": 101.6555, "image_url": "https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=800"}
]

WEATHER_WINDOWS = [
    {"label": "Normal", "temp": 29, "humidity": 65, "time_of_day": "Morning (09:00)"},
    {"label": "Heatwave", "temp": 35, "humidity": 40, "time_of_day": "Noon (13:00)"},
    {"label": "Monsoon", "temp": 24, "humidity": 90, "time_of_day": "Evening (18:00)"}
]

SCENARIO_PATTERNS = [
    {"room": "DK1", "window": "Normal", "pattern": {"TOO_COLD": 15, "TOO_HOT": 0}},
    {"room": "24h Study", "window": "Normal", "pattern": {"TOO_COLD": 1, "TOO_HOT": 1}},
    {"room": "Lounge", "window": "Normal", "pattern": {}},
    {"room": "Examination Hall", "window": "Normal", "pattern": {}},
    {"room": "Faculty of Engineering", "window": "Normal", "pattern": {"TOO_HOT": 1}},
    {"room": "Science Lecture Hall", "window": "Normal", "pattern": {}},
    
    # Heatwave: Multiple rooms light up. Science Hall is the focal RED room for the demo.
    # Faculty of Engineering also RED (heavy lab heat load).
    # DK1, 24h Study, Lounge go PURPLE (5-7 range) — creates the "campus chaos" map effect.
    {"room": "DK1", "window": "Heatwave", "pattern": {"TOO_HOT": 6}},
    {"room": "24h Study", "window": "Heatwave", "pattern": {"TOO_HOT": 7}},
    {"room": "Lounge", "window": "Heatwave", "pattern": {"TOO_HOT": 5}},
    {"room": "Examination Hall", "window": "Heatwave", "pattern": {}},
    {"room": "Faculty of Engineering", "window": "Heatwave", "pattern": {"TOO_HOT": 55}},
    {"room": "Science Lecture Hall", "window": "Heatwave", "pattern": {"TOO_HOT": 13}},
    
    {"room": "DK1", "window": "Monsoon", "pattern": {"TOO_COLD": 2}},
    {"room": "24h Study", "window": "Monsoon", "pattern": {"TOO_COLD": 3}},
    {"room": "Lounge", "window": "Monsoon", "pattern": {"TOO_COLD": 7}},
    {"room": "Examination Hall", "window": "Monsoon", "pattern": {"TOO_COLD": 80}},
    {"room": "Faculty of Engineering", "window": "Monsoon", "pattern": {}},
    {"room": "Science Lecture Hall", "window": "Monsoon", "pattern": {"TOO_COLD": 1}}
]

KWH_RATE = 0.509 # RM per kWh (commercial rate)
AC_POWER_KW = 2.5 # Estimated kW drawn per AC unit
AC_UNITS_PER_ROOM = 2

def trigger_act(label):
    """
    Toggles the campus state to a specific weather act with time-of-day context.
    """
    # 1. Update Global Weather (The AI's Trigger)
    try:
        weather_data = next(w for w in WEATHER_WINDOWS if w['label'] == label)
        db.collection("campus_state").document("current_weather").set({
            **weather_data,
            "last_updated": datetime.now()
        })
        
        # --- NEW: Generate Dynamic Forecast ---
        prediction_summary = "WAITING FOR AI ANALYSIS..."
        actions = []
        if label == "Normal":
            prediction_summary = "CAMPUS STABLE. MINIMAL INTERVENTION REQUIRED."
            efficiency_trend = "+2.4%"
            predicted_status = "Optimal"
            actions = [
                {"type": "Predictive", "title": "Load Balancing", "subtitle": "Shifting HVAC load to high-traffic zones at 9 AM."},
                {"type": "System", "title": "Standby Mode", "subtitle": "Unused lecture halls entering energy-saving state."}
            ]
        elif label == "Heatwave":
            prediction_summary = "EXTREME HEAT DETECTED. PRE-COOLING INITIATED."
            efficiency_trend = "-5.8%"
            predicted_status = "Crit. Anomaly"
            actions = [
                {"type": "Tactical", "title": "Pre-Cooling", "subtitle": "Lowering baseline temp in Engineering Block before peak load."},
                {"type": "Predictive", "title": "Throttle Defense", "subtitle": "Capping max AC output in shaded zones to preserve grid."}
            ]
        elif label == "Monsoon":
            prediction_summary = "HUMIDITY SPIKE RISK. DEHUMIDIFICATION ACTIVE."
            efficiency_trend = "+1.1%"
            predicted_status = "Attention"
            actions = [
                {"type": "System", "title": "Dehumidify", "subtitle": "Running fan-only cycles to clear moisture in Exam Hall."},
                {"type": "Predictive", "title": "Window Defense", "subtitle": "Alerting field agents to secure open louvers in Block C."}
            ]
            
        db.collection("campus_state").document("daily_prediction").set({
            "prediction_summary": prediction_summary,
            "efficiency_trend": efficiency_trend,
            "predicted_status": predicted_status,
            "actions": actions,
            "last_updated": datetime.now()
        })
        
    except StopIteration:
        print(f"Error: Weather label '{label}' not found.")
        return

    # 2. Update Functional Room Summaries
    for room_id, info in FUNCTIONAL_ROOMS.items():
        try:
            pattern = next(p['pattern'] for p in SCENARIO_PATTERNS if p['room'] == room_id and p['window'] == label)
            
            # Fetch previous state to calculate hours unresolved
            doc_ref = db.collection("room_summaries").document(room_id)
            doc_snap = doc_ref.get()
            
            hours_unresolved = 1.0 # Default to 1 hour for first run or simple act switches
            if doc_snap.exists:
                prev_data = doc_snap.to_dict()
                if prev_data.get("status") in ["needs_review", "pending", "critical"]:
                   # In a real app we'd use datetime.now() math, but since acts jump arbitrary 
                   # times (e.g. 09:00 to 13:00), we'll simulate an accumulated time
                   hours_unresolved = prev_data.get("accumulated_hours_unresolved", 0) + 1.5
                else:
                   hours_unresolved = 0 # Reset if it was resolved
                   
            ac_units = info.get("ac_units", AC_UNITS_PER_ROOM)
            waste_per_hour = round(KWH_RATE * AC_POWER_KW * ac_units, 2)
            total_waste = round(waste_per_hour * hours_unresolved, 2)
            
            doc_ref.set({
                "room_name": room_id,
                "building": info["building"],
                "description": info.get("description", ""),
                "lat": info["lat"],
                "lng": info["lng"],
                "internal_temp": info["temps"][label],
                "reports": pattern,
                "type": "functional",
                "time_context": weather_data["time_of_day"],
                "last_updated": datetime.now(),
                "status": "pending",
                "pending_action": None,
                "accumulated_hours_unresolved": hours_unresolved,
                "estimated_ringgit_waste_per_hour": waste_per_hour,
                "total_estimated_ringgit_waste": total_waste,
                "image_url": info.get("image_url")
            })
        except StopIteration:
            print(f"Warning: No pattern found for room '{room_id}' in act '{label}'.")

    # 3. Update NPC Room Summaries
    for npc in NPC_ROOMS:
        noise_pattern = {
            "TOO_COLD": random.randint(0, 3),
            "TOO_HOT": random.randint(0, 3),
            "OPTIMAL": random.randint(5, 15)
        }
        
        db.collection("room_summaries").document(npc["id"]).set({
            "room_name": npc["location"],
            "building": "Campus",
            "lat": npc["lat"],
            "lng": npc["lng"],
            "internal_temp": 24 + random.uniform(-1, 1),
            "reports": noise_pattern,
            "type": "npc",
            "time_context": weather_data["time_of_day"],
            "last_updated": datetime.now(),
            "status": "stable",
            "pending_action": None,
            "image_url": npc["image_url"]
        })

    print(f"Act '{label}' is now LIVE on the dashboard.")
    print(f"Time of Day: {weather_data['time_of_day']}")
    print(f"Global Temp: {weather_data['temp']} degree C")

def inject_user_feedback(room_id, feedback_type, user_comment):
    """
    Simulates a specific user leaving qualitative feedback to satisfy judging criteria.
    """
    doc_ref = db.collection("room_summaries").document(room_id)
    doc = doc_ref.get()
    if doc.exists:
        data = doc.to_dict()
        current_feedback = data.get("recent_qualitative_feedback", [])
        
        new_feedback = {
            "type": feedback_type,
            "comment": user_comment,
            "timestamp": datetime.now()
        }
        current_feedback.append(new_feedback)
        
        # Keep only the last 5 feedback instances and trigger a re-eval
        doc_ref.update({
            "recent_qualitative_feedback": current_feedback[-5:],
            "status": "pending",  # Force AI to re-evaluate
            "last_updated": datetime.now()
        })
        print(f"User feedback injected for {room_id}: '{user_comment}'")
    else:
        print(f"Error: Room '{room_id}' not found.")

def trigger_ghost_room(room_id):
    """Simulates a 'Ghost Room' scenario: Empty room, lights/AC at max intensity."""
    print(f"👻 Triggering Ghost Room incident in {room_id}...")
    
    room_ref = db.collection("room_summaries").doc(room_id)
    room_ref.update({
        "status": "pending",
        "internal_temp": 16.0,  # Coldest AC setting
        "occupancy": 0,         # Empty
        "estimated_ringgit_waste_per_hour": 5.40, # High waste for empty room
        "accumulated_hours_unresolved": 1 # Start with 1 hour waste
    })
    print(f"✅ {room_id} is now a Ghost Room. AI Brain should flag this as RED.")

def ai_suggest_action(room_id, suggested_temp, reasoning):
    """
    Simulates the AI (Node.js) suggesting an action.
    This updates the 'pending_action' field for the admin to see in Flutter.
    """
    doc_ref = db.collection("room_summaries").document(room_id)
    doc = doc_ref.get()
    if doc.exists:
        doc_ref.update({
            "pending_action": {
                "suggested_temp": suggested_temp,
                "reasoning": reasoning,
                "timestamp": datetime.now()
            },
            "status": "needs_review"
        })
        print(f"AI Suggestion for {room_id}: Set to {suggested_temp} degree C. Reasoning: {reasoning}")
    else:
        print(f"Error: Room '{room_id}' not found.")

def admin_approve_action(room_id):
    """
    Simulates the Admin (Flutter App) approving the AI's suggestion.
    This applies the suggested_temp to the internal_temp and clears the pending_action.
    """
    doc_ref = db.collection("room_summaries").document(room_id)
    doc = doc_ref.get()
    if doc.exists:
        data = doc.to_dict()
        pending = data.get("pending_action")
        if pending:
            new_temp = pending["suggested_temp"]
            doc_ref.update({
                "internal_temp": new_temp,
                "status": "resolved",
                "last_action": f"Admin approved AI suggestion: Set to {new_temp}°C",
                "pending_action": None,
                "last_updated": datetime.now(),
                "accumulated_hours_unresolved": 0,
                "total_estimated_ringgit_waste": 0
            })
            print(f"Admin Approved for {room_id}: Internal Temp is now {new_temp} degree C.")
        else:
            print(f"No pending action for {room_id}.")
    else:
        print(f"Error: Room '{room_id}' not found.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        # Usage: python3 ecosense_admin_approval_simulation.py suggest [room_id] [temp] [reasoning]
        if command == "suggest" and len(sys.argv) >= 5:
            reasoning = " ".join(sys.argv[4:])
            ai_suggest_action(sys.argv[2], float(sys.argv[3]), reasoning)
        
        # Usage: python3 ecosense_admin_approval_simulation.py approve [room_id]
        elif command == "approve" and len(sys.argv) == 3:
            admin_approve_action(sys.argv[2])
            
        # Usage: python3 ecosense_admin_approval_simulation.py feedback [room_id] [type] [comment]
        elif command == "feedback" and len(sys.argv) >= 5:
            user_comment = " ".join(sys.argv[4:])
            inject_user_feedback(sys.argv[2], sys.argv[3], user_comment)
            
        # Usage: python generate_dataset.py ghost [room_id]
        elif command == "ghost" and len(sys.argv) == 3:
            trigger_ghost_room(sys.argv[2])
            
        else:
            valid_labels = [w['label'] for w in WEATHER_WINDOWS]
            if command in valid_labels:
                trigger_act(command)
            else:
                print(f"Invalid Command or Act.")
    else:
        # Default initialization to "Normal"
        print("Initializing with 'Normal' state...")
        trigger_act("Normal")
        print("\nUsage:")
        print("  - Switch Act: python generate_dataset.py [Normal|Heatwave|Monsoon]")
        print("  - AI Suggest: python generate_dataset.py suggest [room_id] [temp] [reasoning]")
        print("  - Admin Approve: python generate_dataset.py approve [room_id]")
        print("  - User Feedback: python generate_dataset.py feedback [room_id] [feedback_type] [user_comment]")
        print("  - Ghost Room: python generate_dataset.py ghost [room_id]")