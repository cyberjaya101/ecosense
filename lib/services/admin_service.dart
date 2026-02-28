import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── ROOM LOCATIONS: UNIVERSITI MALAYA (UM) ──────────────────────────────────
// These coordinates place your markers at key UM landmarks.
const Map<String, LatLng> kRoomLocations = {
  // Faculty of Engineering, Block B
  'DK1': LatLng(3.1197, 101.6622),
  // UM Central Library (Perpustakaan Utama)
  '24h Study': LatLng(3.1215, 101.6583),
  // Near Dewan Tunku Canselor (DTC)
  'Lounge': LatLng(3.1208, 101.6619),
};

// ─── COLOR MAPPING ───────────────────────────────────────────────────────────
// These must match what the AI Brain writes to Firestore: "RED", "GREEN", "PURPLE".
const Map<String, BitmapDescriptor> kMarkerColors =
    {}; // Initialized at runtime

class AdminService {
  final _db = FirebaseFirestore.instance;

  // Stream all room summaries. The map screen listens to this.
  Stream<QuerySnapshot> roomsStream() {
    return _db.collection('room_summaries').snapshots();
  }

  // Stream a single room. Room Detail screen uses this.
  Stream<DocumentSnapshot> singleRoomStream(String roomId) {
    return _db.collection('room_summaries').doc(roomId).snapshots();
  }

  // Returns a live count of rooms with RED status (critical anomalies).
  Stream<int> alertCountStream() {
    return _db
        .collection('room_summaries')
        .snapshots()
        .map((snapshot) => snapshot.docs.where((doc) {
              final data = doc.data();
              final color =
                  (data as Map<String, dynamic>?)?['status_color'] as String? ??
                      'GREEN';
              return color == 'RED';
            }).length);
  }

  // Returns a live daily savings value from Firestore analytics doc.
  Stream<double> dailySavingsStream() {
    return _db
        .collection('analytics')
        .doc('daily_summary')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 1245.0; // Fallback demo value
      final data = doc.data() as Map<String, dynamic>;
      return (data['daily_savings_rm'] as num? ?? 1245.0).toDouble();
    });
  }

  // Returns a live total waste count across all rooms.
  Stream<double> totalWasteStream() {
    return _db.collection('room_summaries').snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total +=
            (data['total_estimated_ringgit_waste'] as num? ?? 0.0).toDouble();
      }
      return total;
    });
  }

  // Admin clicks "Resolve" — this closes the loop and triggers point awarding.
  Future<void> resolveRoom(String roomId) async {
    await _db.collection('room_summaries').doc(roomId).update({
      'status': 'resolved',
      'status_color': 'GREEN',
      'pending_action': FieldValue.delete(),
      'recent_qualitative_feedback': FieldValue.delete(),
    });
  }

  // Admin clicks "Dismiss" — marks as stable without awarding points.
  Future<void> dismissAlert(String roomId) async {
    await _db.collection('room_summaries').doc(roomId).update({
      'status': 'stable',
      'status_color': 'GREEN',
      'pending_action': FieldValue.delete(),
      'recent_qualitative_feedback': FieldValue.delete(),
    });
  }

  // Predictive Scheduler: powers the "Tomorrow's Schedule" widget
  Stream<DocumentSnapshot> dailyPredictionStream() {
    return _db.collection('campus_state').doc('daily_prediction').snapshots();
  }

  // Resolves all active anomalies in one go (Demo Shortcut)
  Future<void> resolveAllRooms() async {
    final snapshot = await _db.collection('room_summaries').get();
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      final color = doc.data()['status_color'];
      if (color == 'RED' || color == 'PURPLE') {
        batch.update(doc.reference, {
          'status': 'resolved',
          'status_color': 'GREEN',
          'pending_action': FieldValue.delete(),
          'recent_qualitative_feedback': FieldValue.delete(),
        });
      }
    }
    await batch.commit();
  }
}
