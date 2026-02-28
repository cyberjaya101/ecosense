# 🌍 EcoSense: The Waze for Air Conditioning
> **Tagline:** Empowering a Human Sensor Network to eliminate campus energy waste.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Gemini](https://img.shields.io/badge/Gemini_1.5_Flash-8E75B2?style=for-the-badge&logo=googlebard&logoColor=white)](https://deepmind.google/technologies/gemini/)
[![Google Maps](https://img.shields.io/badge/Google_Maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white)](https://cloud.google.com/maps-platform/)

---

## 📖 Table of Contents
1. [The Problem & Our Solution](#-the-problem--our-solution)
2. [Hackathon SDG Alignment](#-sdg--judging-alignment)
3. [System Architecture (A to Z)](#-system-architecture-a-to-z)
4. [The AI Brain (Gemini)](#-the-ai-brain)
5. [Anti-Spam Gamification (Eco-Points)](#-anti-spam-gamification)
6. [Technical Implementation Details](#%EF%B8%8F-technical-implementation-details)
7. [How to Run the App & Pitch Demo](#-how-to-run-the-app--pitch-demo)

---

## 💡 The Problem & Our Solution

### The Blind Spot of Building Management
Malaysian universities spend **millions of ringgit annually** cooling empty rooms or over-cooling occupied spaces. Facility managers lack real-time visibility into building conditions. Installing traditional IoT thermostat sensors across a 500-room campus costs roughly **RM 750,000** and takes months of infrastructure work. Because of this cost barrier, universities simply absorb the financial loss of wasted electricity.

### The EcoSense Solution
**EcoSense** bypasses expensive hardware by empowering the thousands of students already on campus to act as a **Human Sensor Network**. 
Through a 5-second mobile app interaction, students report thermal anomalies ("Too Cold", "Too Hot", or "Ghost Room"). Our Cloud AI Brain (powered by **Gemini 2.5 Flash & Vision**) ingests these reports, cross-references them with live weather data, filters out noise, and delivers actionable, prioritized insights to facility managers via the **Eco-Command Dashboard**.

---

## 🎯 SDG & Judging Alignment

### 1. Societal Impact (60% Weight)
- 🏙️ **SDG 11 (Sustainable Cities and Communities):** Retrofits legacy campus infrastructure to be resilient, energy-efficient, and data-driven without restrictive hardware investments.
- ♻️ **SDG 12 (Responsible Consumption and Production):** Directly targets and reduces HVAC energy waste, which accounts for up to 60% of university electricity bills.
- **Financial Accountability:** The Admin Dashboard features a **Live Ringgit Wasted Counter**. It mathematically calculates exact financial losses per hour (e.g., *4 AC units × 2.5kW × 1.5 hours × RM 0.509/kWh = RM 7.63* per incident), giving administrators an exact ROI on resolving issues.

### 2. Google Technology Stack (20% Weight)
EcoSense is built 100% on the Google ecosystem:
- **Google AI (Gemini 2.5 Flash & Vision):** The core reasoning engine. It processes JSON payloads of crowdsourced reports, analyzes user-submitted photos, and outputs precise HVAC recommendations.
- **Flutter:** A unified UI codebase generating both the Student iOS/Android reporting app and the Admin Web dashboard.
- **Firebase Firestore:** A Real-time NoSQL database providing sub-second reactivity. When an admin resolves an issue, data syncs globally and UI markers turn green instantly.
- **Google Maps Platform:** Powers the live vector-based "Neural Twin" Campus Heatmap.

---

## 🏗️ System Architecture (A to Z)

EcoSense operates as a continuous, closed-loop feedback engine.

### 1. Data Collection (Student App)
Students select their location (via manual dropdown or high-accuracy QR scan) and submit one of three reports: Too Cold, Too Hot, or Ghost Room (empty room with AC/Lights on). For Ghost Rooms, they must use the camera to submit photographic proof.

### 2. The Listener (Node.js AI Backend)
The `ai_brain.js` Node script permanently listens to the Firebase `room_summaries` collection. It aggregates reports over time to prevent single-complaint bias.

### 3. Contextual Analysis (Gemini Integration)
Once a report volume threshold is met, the AI Brain packages the data (Internal/External Temp, Report Volume, Qualitative Comments, Base64 Images) and constructs a dynamic prompt for the Gemini API. Gemini considers the weather (e.g., "Monsoon vs. Heatwave") to determine if a "Too Cold" report is an actual system failure or just subjective preference. 

### 4. Admin Visualization (Flutter Web Dashboard)
Gemini outputs a structured JSON response (`risk_score`, `reasoning`, `status_color`). This immediately updates Firestore. The Admin Dashboard (Google Maps UI) sees the building marker shift from Green to Red. The Admin opens the **Neural Diagnostic View** to read Gemini's specific reasoning and clicks "Resolve".

### 5. Automated Reward Cycle
Clicking "Resolve" resets the room state in Firestore. The Node.js backend detects the resolution, identifies the students who correctly reported the issue, and executes a secure transaction to deposit **Eco-Points** into their digital wallets.

---

## 🧠 The AI Brain

### 1. Vision Verification (Gemini Vision 1.5/2.5 Pro)
To ensure the highest-value report ("Ghost Room") is not abused, EcoSense implements a computational vision check. 
- The student submits a photo.
- Gemini is prompted: *"Look at this image. Does it look like a standard university classroom? Are there any human beings visible?"*
- If Gemini detects people or detects the user took a photo of the floor to cheat the system, the report is instantly marked invalid (`risk_score = 0`).

### 2. Predictive Scheduler
Our backend also runs a cron job utilizing Gemini to cross-reference the 5-day weather forecast with historical campus data. It generates a "Predictive Path" (e.g., *"Heavy rain forecasted tomorrow. Buildings with single-pane glass at Engineering Faculty will require proactive heating adjustments"*).

---

## 🎮 Anti-Spam Gamification

To motivate participation, students earn **Eco-Points** (1,000 pts = RM 5.00 value). However, gamification invites exploitation. Here is our A-to-Z defense architecture:

| The Exploit | Mechanism | Defense Layer implemented |
| :--- | :--- | :--- |
| **The Lazy Troller** | Tries to report Ghost Rooms from their bed via dropdown menus. | **UI Layer:** Ghost room reporting is entirely disabled unless the user physically scans the GPS-anchored QR code at the door. |
| **The Fake Photographer** | Walks to the room but photographs the ceiling so it looks "empty". | **AI Vision Layer:** Gemini Vision analyzes the photo specifically searching for room context. If it's a generic wall, the report is rejected. |
| **The Spammer** | Taps "Too Cold" 50 times in one minute. | **Spam Protection:** Strict 30-minute cooldowns are enforced locally and verified via backend server timestamps. |
| **The Troll Army** | 5 friends coordinate to report an occupied, comfortable room as a "Ghost Room" as a prank. | **Aggregation Layer:** Gemini analyzes *conflicting* data. If 5 users say "Ghost" but historical IoT says "Stable", Gemini flags the data anomaly for human review rather than blindly acting. |
| **The Farmer** | Tries to "farm" points repeatedly. | **Admin Escrow:** Points are NEVER given upon reporting. Points are only awarded *after* a Facility Manager verifies the AI logic and clicks "Resolve" on the dashboard. |

---

## ⚙️ Technical Implementation Details

- **Code Consolidation:** The entire project (Admin Web and Student Mobile) currently resides in a single, unified Flutter project repository to prevent dependency hell. Roles are handled via mock-auth on the Login Screen.
- **Custom Renderers:** The Admin map uses custom Flutter `CustomPainter` canvases overlaid on interactive `InteractiveViewer` objects (for offline GEOJson maps) or Google/Mapbox vectors.
- **API Security:** All Firebase Keys, Google Maps Keys, and Gemini keys have been stripped from the repository. They are dynamically loaded via `flutter_dotenv` (`.env`) for Flutter, and `dotenv` for the Node.js backend. Android build manifests utilize Gradle `.properties` injection to secure the Maps API.

---

## 🖥️ How to Run the App & Pitch Demo

### 1. Environment Setup
1. Define a `.env` in the project root with `FIREBASE_API_KEY=YOUR_KEY` and `GOOGLE_MAPS_API_KEY=YOUR_KEY`.
2. Define `MAPS_API_KEY=YOUR_KEY` inside `android/local.properties`.
3. Provide a `serviceAccountKey.json` and a `.env` with `GOOGLE_API_KEY_1=...` in the `/backend` folder.

### 2. Starting the Backend Engine
The backend must run concurrently to process AI requests and sync data. 
```bash
cd backend
npm install
node ai_brain.js
```

### 3. Launching the Client App
Launch the Flutter app on an Android Emulator.
```bash
flutter clean && flutter pub get
flutter run
```

### 4. Running the Interactive Demo
A specifically curated demo sequence designed for judging exists in the `demo/` folder.
```bash
cd demo
start_demo.bat
```
*(On mac/Linux, manually run `python ../backend/generate_dataset.py [ActName]`)*

**Demo Scripts Included:**
- `Normal`: A 29°C day with isolated AC overcooling events.
- `Heatwave`: A 35°C day causing widespread heatmap spikes (to demonstrate proactive vs reactive AI guidance).
- `Monsoon`: 24°C rain, perfect for showing how the AI catches "Ghost Rooms" wasting maximal energy.

---
**EcoSense** — *Real-time visibility. AI-driven action. Zero hardware.*
