require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
initializeApp({
    credential: cert(serviceAccount)
});
const db = getFirestore();

// Rotate Gemini API Keys from .env
const apiKeys = Object.keys(process.env).filter(k => k.startsWith('GOOGLE_API_KEY_')).map(k => process.env[k]);
let currentKeyIndex = 0;

function getNextGenAIModel() {
    if (apiKeys.length === 0) {
        console.error("❌ No API Keys found in .env.");
        process.exit(1);
    }
    const currentKey = apiKeys[currentKeyIndex];
    const genAI = new GoogleGenerativeAI(currentKey);
    currentKeyIndex = (currentKeyIndex + 1) % apiKeys.length;
    return genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
}

let model = getNextGenAIModel();

// Simulated Weather Forecast Data
const weatherForecast = {
    tomorrow: {
        condition: "Heavy Rain / Monsoon",
        temperature: 24,
        humidity: 90
    }
};

const historicalPatterns = [
    { room: "DK1", pattern: "Gets humid and stuffy during rain, leading to feeling too hot if not in Dry Mode." },
    { room: "24h Study", pattern: "Glass walls make it an icebox during rain if AC is left at 18°C." }
];

async function generateDailyPrediction() {
    console.log(`📅 Generating Predictive AC Schedule for Tomorrow...`);

    try {
        // Fetch real room data
        const roomsSnapshot = await db.collection('room_summaries').get();
        const roomData = roomsSnapshot.docs.map(doc => ({
            name: doc.data().room_name,
            status: doc.data().status_color,
            temp: doc.data().internal_temp,
            waste: doc.data().total_estimated_ringgit_waste || 0
        }));

        const prompt = `
            You are the EcoSense Predictive AI. 
            Tomorrow's weather is forecast as: ${weatherForecast.tomorrow.condition}, ${weatherForecast.tomorrow.temperature}°C.
            Current Campus State: ${JSON.stringify(roomData)}
            Historical Patterns: ${JSON.stringify(historicalPatterns)}

            Based on this, generate a predictive insight for tomorrow to prevent energy waste.
            Return ONLY a valid JSON object matching this structure:
            {
                "prediction_summary": "<short string summarizing tomorrow's primary risk>",
                "actions": [
                    { "title": "Pattern Analysis", "subtitle": "<what did you detect?>", "type": "Analysis" },
                    { "title": "Optimization Strategy", "subtitle": "<what is the plan?>", "type": "Strategy" },
                    { "title": "Projected Outcome", "subtitle": "<estimated savings or impact>", "type": "Outcome" }
                ]
            }
        `;

        const result = await model.generateContent(prompt);
        let cleanText = result.response.text().trim();
        if (cleanText.startsWith('```json')) cleanText = cleanText.substring(7);
        else if (cleanText.startsWith('```')) cleanText = cleanText.substring(3);
        if (cleanText.endsWith('```')) cleanText = cleanText.substring(0, cleanText.length - 3);

        const prediction = JSON.parse(cleanText.trim());

        // Save to Firestore so the Flutter UI can read it
        await db.collection('campus_state').doc('daily_prediction').set({
            prediction_summary: prediction.prediction_summary,
            actions: prediction.actions,
            target_date: "Tomorrow",
            last_updated: new Date()
        });

        console.log(`\n🔮 Predictive Insight: ${prediction.prediction_summary}`);
        prediction.actions.forEach(action => {
            console.log(`   └─ [${action.type}] ${action.title}: ${action.subtitle}`);
        });
        console.log(`\n✅ Prediction generated and saved to Firestore (campus_state/daily_prediction) for Admin Dashboard display.`);

    } catch (error) {
        console.error("❌ Prediction Error:", error.message);
    }
}

generateDailyPrediction();
