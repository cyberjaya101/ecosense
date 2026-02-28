# 🧠 AI Brain & Dataset Documentation — EcoSense

This document explains the technical architecture and logic flow between our synthetic dataset, the Gemini AI engine, and the live application.

---

## 📊 1. The Dataset (`generate_dataset.py`)

Our dataset is a real-time synthetic engine that simulates a campus IoT environment.

### Core Features:
- **Dynamic Acts:** Allows switching between **Normal**, **Heatwave**, and **Monsoon** scenarios. This triggers cascading changes in temperature, humidity, and student report frequency across the campus.
- **Financial Waste Engine:** Calculates energy waste in **Ringgit (RM)** in real-time. It uses commercial kWh rates and estimated AC power draw to quantify the cost of unresolved issues.
- **NPC Noise:** Populates non-essential rooms with random "Stable" data to provide a realistic map density for the Admin Dashboard.
- **Injection Tools:** Includes CLI commands to force specific scenarios:
    - `ghost [room]` : Simulates an empty room with maximum AC usage.
    - `feedback [room] [type] [comment]`: Simulates a specific "Human-in-the-Loop" report.

---

## 🧠 2. The AI Brain (`ai_brain.js`)

The AI Brain is a Node.js service that acts as the "Intelligent Intermediary" using **Gemini 1.5/2.5 Flash**.

### The Real-Time Loop:
1.  **Monitor:** Listens to the `room_summaries` collection for any document marked as `status: "pending"`.
2.  **Contextual Analysis:** When a report arrives, it gathers:
    - IoT Sensor Data (External/Internal Temp)
    - Cumulative Waste (RM)
    - Qualitative Student Feedback (Comments)
3.  **Gemini Reasoning:** Sends a structured prompt to Gemini to evaluate the "Risk Score" and "Suggested Temperature."
4.  **Actionable Insights:** Updates Firestore with a `pending_action` object containing Gemini's exact reasoning (e.g., *"Student reported cold while external temp is 24°C; AC is over-cooling. RM 2.50 wasted.*").

---

## 🤝 3. Integration & "Closing the Loop"

The AI Brain handles the critical **Reward Handshake**:

- **Detection:** It watches for an Admin to click **"Resolve"** (`status: "resolved"`).
- **Point Awarding:** It identifies every `reporter_id` associated with that specific room incident.
- **Transactional Update:** It awards the specified `points_to_award` (10, 50, or 150) to each student's user profile in a single atomic transaction.
- **Reset:** After 5 seconds, it automatically resets the room to `stable` so the demo can be repeated.

---

## 🛠️ Deployment & Testing
- **Backend:** Run `node ai_brain.js` (Requires `.env` with Gemini Keys).
- **Simulation:** Run `python generate_dataset.py [ActName]` to push new data to the apps.
