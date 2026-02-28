import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/* 
  🚀 ECO-SENSE DEVELOPER STARTER KIT
  -----------------------------------
  Hey Teammate! This file contains the "brain" for the Student App. 
  You can copy-paste these classes into your project or use them as a reference.
  
  CORE IDs FOR DEMO:
  - Current Student: "alex_rivera" (seeded with 50 points)
  - Room Names: "DK1", "24h Study", "Lounge"
*/

/// 1. DATA SERVICE LAYER
/// ---------------------
/// This class handles all communication with Firebase.
/// Move this to a separate file like `services/eco_service.dart`.
class EcoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentStudentId = "alex_rivera";

  // Updates the room document.
  // This is the 'trigger' that makes the AI Brain start analyzing.
  Future<void> submitReport({
    required String roomId,
    required String type, // Use "TOO_COLD", "TOO_HOT", or "GHOST_ROOM"
    required int pointsToAward, // 10 (Manual), 50 (QR), 150 (Ghost)
  }) async {
    try {
      final docRef = _db.collection('room_summaries').doc(roomId);

      await docRef.update({
        'recent_qualitative_feedback': FieldValue.arrayUnion([
          {
            'type': type,
            'reporter_id': currentStudentId,
            'points_to_award': pointsToAward,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
        'status': 'pending', // <--- CRITICAL: Backend AI brain listens for this
        'last_updated': FieldValue.serverTimestamp(),
      });
      print("✅ Report submitted for $roomId");
    } catch (e) {
      print("❌ Error submitting report: $e");
    }
  }

  // Stream for the User's points (use this in the Wallet/Profile)
  Stream<DocumentSnapshot> getStudentStream() {
    return _db.collection('users').doc(currentStudentId).snapshots();
  }

  // Stream for a specific room (use this to detect Admin resolution)
  Stream<DocumentSnapshot> getRoomStream(String roomId) {
    return _db.collection('room_summaries').doc(roomId).snapshots();
  }
}

/// 2. UI COMPONENTS
/// ----------------

/// A Progress Bar for the Wallet - shows how close you are to a reward!
class RewardProgressBar extends StatelessWidget {
  final String label;
  final int currentPoints;
  final int targetPoints;
  final Color color;

  const RewardProgressBar({
    super.key,
    required this.label,
    required this.currentPoints,
    required this.targetPoints,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    double progress = (currentPoints / targetPoints).clamp(0.0, 1.0);
    bool isUnlocked = progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${(progress * 100).toInt()}%",
                  style: TextStyle(
                      color: isUnlocked ? Colors.green : Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  isUnlocked ? Colors.green : color),
            ),
          ),
          if (isUnlocked)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text("✨ Ready to Redeem!",
                  style: TextStyle(fontSize: 12, color: Colors.green)),
            ),
        ],
      ),
    );
  }
}

/// The "Popup Listener"
/// Add this to your Main Screen. It stays invisible but shows a
/// Success Dialog the moment the Admin "Resolves" a room issue.
class GlobalPointsListener extends StatefulWidget {
  final String activeRoomId;
  const GlobalPointsListener({super.key, required this.activeRoomId});

  @override
  _GlobalPointsListenerState createState() => _GlobalPointsListenerState();
}

class _GlobalPointsListenerState extends State<GlobalPointsListener> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: EcoService().getRoomStream(widget.activeRoomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        // If Admin marked as resolved, show the 'Win' screen
        if (data['status'] == 'resolved') {
          // We use addPostFrameCallback to avoid building dialog during build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showResolutionDialog(context);
          });
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showResolutionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
            child: Text("🎉 SUCCESS!", style: TextStyle(fontSize: 24))),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text("Admin has verified your report!",
                textAlign: TextAlign.center),
            Text("Eco-Points added to your wallet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("VIEW WALLET"),
            ),
          )
        ],
      ),
    );
  }
}

/// 3. THE GHOST ROOM FLOW
/// Call this function when the student taps the "Ghost Room" button.
Future<void> triggerGhostRoomInteraction(
    BuildContext context, String roomId) async {
  // 1. Simulate Camera Opening & Gemini Vision Scan
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      title: Text("Gemini Vision AI"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Analyzing photo for human presence...",
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  // 2. Wait for 3 seconds (The 'AI Processing' moment)
  await Future.delayed(const Duration(seconds: 3));
  Navigator.pop(context); // Close loading dialog

  // 3. Update Database
  await EcoService().submitReport(
    roomId: roomId,
    type: "GHOST_ROOM",
    pointsToAward: 150,
  );

  // 4. Toast Message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.green,
      content: Text("✅ Gemini Vision: Verified Empty! +150 Points Pending."),
    ),
  );
}
