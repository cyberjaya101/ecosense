# 🎮 How to Run the EcoSense Demo

This directory contains the automation scripts required to demonstrate the **AI Brain** and **Gamification mechanics** of EcoSense.

## 🚀 Quick Start
1.  **Start the Engine:** Double-click `start_demo.bat`. 
    *   This will automatically install backend dependencies (`npm install`).
    *   It starts the **Node.js AI Worker** which listens to Firestore.
    *   It provides a menu to inject **Live Demo Scenarios** (e.g., Anomaly reporting, Ghost Room verification).
2.  **Stop the Engine:** Double-click `kill_ai.bat` to safely shut down all background AI processes.

## 👥 Running Two Instances (Admin + Student)
To demonstrate the live interaction, you should run the app in two separate windows:

### Option A: Mobile + Desktop (Recommended for judges)
1.  Terminal 1: `flutter run -d emulator-5554` (for the **Student App** view).
2.  Terminal 2: `flutter run -d windows` (for the **Admin Dashboard**).
3.  *Tip:* This looks more professional as it shows multi-platform capability.

### Option B: VS Code (Debug Sessions)
1.  Open the `lib/main.dart` file.
2.  Select **"EcoSense (Android Emulator)"** from the debug dropdown at the top.
3.  Press `F5`. The app will now launch **directly on your Android Emulator**.
4.  Launch a second session on Windows for the Admin dashboard.

## 📄 Documentation

*   **[DATASET_AND_AI_BRAIN.md](DATASET_AND_AI_BRAIN.md):** Technical details on how the Gemini-powered reasoning engine validates reports and manages the Eco-Points economy.

## ⚠️ Requirements
*   **Node.js:** Must be installed to run the backend scripts.
*   **Firebase Keys:** Ensure your `serviceAccountKey.json` is present in the `backend/` directory as detailed in the root `README.md`.

---
*Developed for KitaHack 2026 Submission.*
