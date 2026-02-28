import 'package:cloud_firestore/cloud_firestore.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────
// These match the backend exactly. Do NOT change.
const String kStudentId = 'alex_rivera';
const List<String> kRooms = [
  'DK1',
  '24h Study',
  'Lounge',
  'Examination Hall',
  'Faculty of Engineering',
  'Science Lecture Hall'
];

// Points are determined by HOW the student selected the room:
const int kPointsManual = 10; // Dropdown selection
const int kPointsQR = 50; // QR Code scan report reward
const int kPointsGhost = 150; // Ghost Room + QR

// Reward Tiers (must match gamification.md)
const int kTier1Points = 1000;
const int kTier2Points = 5000;
const int kTier3Points = 10000;
// ──────────────────────────────────────────────────────────────────────────

class EcoService {
  final _db = FirebaseFirestore.instance;

  // Submit a comfort report to a room.
  // This sets status:'pending' which triggers the AI Brain on the backend.
  Future<void> submitReport({
    required String roomId,
    required String type, // 'TOO_COLD', 'TOO_HOT', 'GHOST_ROOM'
    required int pointsToAward, // 10, 50, or 150
    String? base64Image, // Optional base64 image data for Vision
  }) async {
    await _db.collection('room_summaries').doc(roomId).update({
      'recent_qualitative_feedback': FieldValue.arrayUnion([
        {
          'type': type,
          'reporter_id': kStudentId,
          'points_to_award': pointsToAward,
          'timestamp': DateTime.now().toIso8601String(),
          if (base64Image != null) 'base64_image': base64Image,
        }
      ]),
      'status': 'pending', // IMPORTANT: This wakes up the AI Brain
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  // Stream of the current student's user document.
  // Contains: total_eco_points, name, major
  Stream<DocumentSnapshot> studentStream() =>
      _db.collection('users').doc(kStudentId).snapshots();

  // Stream of notifications for the current student.
  Stream<QuerySnapshot> notificationsStream() => _db
      .collection('users')
      .doc(kStudentId)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots();

  // Stream of unread notification count.
  Stream<int> unreadNotificationsCountStream() {
    return _db
        .collection('users')
        .doc(kStudentId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all notifications as read.
  Future<void> markAllNotificationsAsRead() async {
    final snapshot = await _db
        .collection('users')
        .doc(kStudentId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Stream of a specific room's status.
  // Used to detect when admin resolves an issue.
  Stream<DocumentSnapshot> roomStream(String roomId) =>
      _db.collection('room_summaries').doc(roomId).snapshots();
}
