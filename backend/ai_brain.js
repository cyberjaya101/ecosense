require('dotenv').config();
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// 1. Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
initializeApp({
  credential: cert(serviceAccount)
});
const db = getFirestore();

// --- 3. LIVE WASTE TICKER LOOP ---
// Every 3 seconds, find all "RED" rooms and increment their waste money.
// NOTE: We deliberately omit `last_updated` here to avoid triggering the
// Firestore onSnapshot listener on every tick, which would overload API keys.
setInterval(async () => {
  try {
    const redRooms = await db.collection('room_summaries')
      .where('status_color', '==', 'RED')
      .get();

    if (redRooms.empty) return;

    const batch = db.batch();
    redRooms.forEach(doc => {
      batch.update(doc.ref, {
        total_estimated_ringgit_waste: FieldValue.increment(0.02)
        // Intentionally NOT updating last_updated — avoids spurious snapshot events
      });
    });

    await batch.commit();
  } catch (err) {
    console.error("Ticker Error:", err.message);
  }
}, 3000);

// 2. Load and Rotate Gemini API Keys from .env
const apiKeys = Object.keys(process.env).filter(k => k.startsWith('GOOGLE_API_KEY_')).map(k => process.env[k]);
let currentKeyIndex = 0;

function getNextGenAIModel() {
  if (apiKeys.length === 0) {
    console.error("❌ No API Keys found in .env. Please define GOOGLE_API_KEY_1, GOOGLE_API_KEY_2, etc.");
    process.exit(1);
  }
  const currentKey = apiKeys[currentKeyIndex];
  console.log(`🔌 Initializing Gemini with Key #${currentKeyIndex + 1}...`);
  const genAI = new GoogleGenerativeAI(currentKey);
  currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
  return genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
}

let model = getNextGenAIModel();

console.log("🟢 AI Brain is online and listening to Firestore...");

// 3. The Real-Time Listener
const processingDocs = new Set();

db.collection('room_summaries').onSnapshot((snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    const doc = change.doc;
    const data = doc.data();
    const roomId = doc.id;

    if (processingDocs.has(roomId)) return;

    // --- SCENARIO A: New Data Arrives (Needs AI Analysis) ---
    if ((change.type === 'added' || change.type === 'modified') && data.status === 'pending') {

      // Skip NPC rooms — they are background noise and must never trigger AI analysis.
      if (data.type === 'npc') {
        console.log(`⏭️  Skipping NPC room: ${data.room_name}`);
        // Silently clear the pending status so it won't loop
        await db.collection('room_summaries').doc(roomId).update({
          status: 'stable',
          status_color: 'GREEN'
        });
        return;
      }

      processingDocs.add(roomId);
      console.log(`\n🔍 New data detected in ${data.room_name}. Analyzing with Gemini...`);

      try {
        let imageParts = [];
        let visionContext = "";

        // Check for base64 image in recent feedback
        if (data.recent_qualitative_feedback && data.recent_qualitative_feedback.length > 0) {
          const latestWithImage = [...data.recent_qualitative_feedback].reverse().find(f => f.base64_image);
          if (latestWithImage) {
            console.log(`📸 Image detected in report. Activating Gemini Vision...`);
            imageParts = [
              {
                inlineData: {
                  data: latestWithImage.base64_image.split(',').pop(),
                  mimeType: "image/jpeg"
                }
              }
            ];
            visionContext = "\nCRITICAL: An image has been provided. Use it to verify if the room is actually empty (Zero Occupancy). If empty, mark as RED.";
          }
        }

        // Calculate total anomaly count for deterministic pre-check
        const reports = data.reports || {};
        const maxSingleCategory = Math.max(0, ...Object.values(reports).map(v => Number(v) || 0));
        const hasFeedback = data.recent_qualitative_feedback && data.recent_qualitative_feedback.length > 0;
        const hasImage = imageParts.length > 0;

        // DETERMINISTIC PRE-CHECK: If all counts are trivially low and no feedback/image,
        // skip Gemini entirely to conserve API quota.
        if (maxSingleCategory < 5 && !hasFeedback && !hasImage) {
          console.log(`✅ Pre-check: ${data.room_name} has low anomaly counts (max: ${maxSingleCategory}). Resolving as PURPLE without AI.`);
          await db.collection('room_summaries').doc(roomId).update({
            status: 'needs_review',
            status_color: 'PURPLE',
            pending_action: {
              risk_score: maxSingleCategory * 5,
              suggested_temp: 24,
              reasoning: `Low anomaly activity detected (max count: ${maxSingleCategory}). No student feedback. Room flagged for routine review.`,
              recommendation: 'Monitor room conditions. No immediate action required.',
              status_color: 'PURPLE'
            },
            last_updated: new Date()
          });
          processingDocs.delete(roomId);
          return;
        }

        const prompt = `
          You are an AI Smart Building Manager for a university campus. Analyze this room data:
          Room: ${data.room_name}
          Room Type: functional (this is a real monitored room, not a background sensor)
          Room Context: ${data.description || 'Standard room, no special notes.'}
          Current Internal Temp: ${data.internal_temp}°C
          Sensor Anomaly Counts: ${JSON.stringify(reports)}
          Accumulated Unresolved Hours: ${data.accumulated_hours_unresolved || 0}
          Total Financial Waste: ${data.total_estimated_ringgit_waste || 0} RM
          Recent Student Feedback: ${JSON.stringify(data.recent_qualitative_feedback || [])}
          ${visionContext}

          STRICT RULES — follow these exactly, no exceptions:
          1. Return RED ONLY IF: any single anomaly category count exceeds 10, OR vision confirms the room is empty.
          2. Return PURPLE IF: anomaly counts are between 5–10, or unresolved hours > 2, or meaningful student complaints exist.
          3. Return GREEN IF: all anomaly counts are below 5 and no strong complaints are present.
          4. Low counts (1–4 per category) are NORMAL background noise — do NOT return RED for these alone.
          5. Financial waste is informational only — do not use it as the sole reason to return RED.
          6. Use the Room Context to write a specific, insightful reasoning (e.g. mention glass walls, equipment heat, etc.).

          Return ONLY a valid JSON object. No markdown, no code fences.
          {
            "risk_score": <1-100>,
            "suggested_temp": <number>,
            "reasoning": "<use room context, mention qualitative comments if present, and state the RM waste figure>",
            "recommendation": "<single action sentence>",
            "status_color": "<RED | PURPLE | GREEN>"
          }
        `;

        const result = await model.generateContent([prompt, ...imageParts]);
        let rawText = result.response.text().trim();

        // Robust JSON extraction (removes potential markdown code blocks)
        const jsonMatch = rawText.match(/\{[\s\S]*\}/);
        if (!jsonMatch) throw new Error("Could not find JSON object in Gemini response");

        const aiInsight = JSON.parse(jsonMatch[0]);

        // Update Firestore
        await db.collection('room_summaries').doc(roomId).update({
          status: 'needs_review',
          status_color: aiInsight.status_color || 'PURPLE',
          pending_action: aiInsight,
          last_updated: new Date()
        });

        console.log(`🧠 Analysis complete for ${data.room_name}. Sent ${aiInsight.status_color} alert.`);
        console.log(`   └─ RM Waste: RM ${data.total_estimated_ringgit_waste || 0}`);
        processingDocs.delete(roomId);

      } catch (error) {
        console.error("❌ Gemini/JSON Error:", error.message);
        processingDocs.delete(roomId);

        if (error.message.includes('API key') || error.message.includes('Quota') || error.message.includes('exhausted')) {
          console.log("🔄 Rotating API Key...");
          model = getNextGenAIModel();
        }

        // Safe Fallback
        await db.collection('room_summaries').doc(roomId).update({
          status: 'needs_review',
          status_color: 'PURPLE',
          pending_action: {
            risk_score: 50,
            suggested_temp: 24,
            reasoning: "AI evaluation error. Proceeding with manual safety baseline.",
            recommendation: "Review room conditions manually.",
            status_color: "PURPLE"
          },
          last_updated: new Date()
        });
      }
    }

    // --- SCENARIO B: "Closing the Loop" (Frontend clicked "Approve") ---
    if (change.type === 'modified' && data.status === 'resolved') {
      console.log(`\n✅ SUCCESS: Admin approved action for ${data.room_name}!`);

      const savedAmount = data.total_estimated_ringgit_waste || 0;
      if (savedAmount > 0) {
        console.log(`💰 Saving RM ${savedAmount.toFixed(2)} to global analytics...`);
        await db.collection('analytics').doc('daily_summary').set({
          daily_savings_rm: FieldValue.increment(savedAmount),
          last_updated: FieldValue.serverTimestamp()
        }, { merge: true });
      }

      console.log(`⚙️  Initiating IoT command: Setting ${data.room_name} AC to ${data.pending_action?.suggested_temp || 24}°C...`);

      // --- NEW: Reward Eco-Points to Reporters ---
      if (data.recent_qualitative_feedback && data.recent_qualitative_feedback.length > 0) {
        console.log(`🏆 Awarding points to ${data.recent_qualitative_feedback.length} reporters...`);

        for (const report of data.recent_qualitative_feedback) {
          if (report.reporter_id) {
            const userRef = db.collection('users').doc(report.reporter_id);
            const points = report.points_to_award || 10;

            await db.runTransaction(async (t) => {
              const userDoc = await t.get(userRef);
              const currentPoints = userDoc.exists ? (userDoc.data().total_eco_points || 0) : 0;
              t.set(userRef, { total_eco_points: currentPoints + points }, { merge: true });

              // Create notification
              const notifRef = userRef.collection('notifications').doc();
              t.set(notifRef, {
                type: 'POINTS',
                title: 'Eco-Points Awarded!',
                message: `Admin verified your ${data.room_name} report. +${points} points added.`,
                timestamp: new Date(),
                isRead: false
              });
            });

            console.log(`   └─ Added ${points} points and notification for user: ${report.reporter_id}`);
          }
        }
      }

      console.log(`🌱 Energy savings locked in. Returning room map marker to GREEN.\n`);

      // Optional: Auto-reset it back to "stable" after a few seconds so the demo loop can run again
      setTimeout(() => {
        db.collection('room_summaries').doc(roomId).update({
          status: 'stable',
          status_color: 'GREEN',
          internal_temp: 24,
          reports: {},
          total_estimated_ringgit_waste: 0,
          accumulated_hours_unresolved: 0,
          pending_action: null,
          recent_qualitative_feedback: [] // Clear the feedback list for next time
        });
      }, 5000);
    }
  });
});