import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
// import 'package:mapbox_gl/mapbox_gl.dart' as mapbox;
import 'package:google_fonts/google_fonts.dart';
import '../widgets/geojson_map.dart';
import '../services/admin_service.dart';
import 'admin_room_detail_screen.dart';
import 'admin_insights_screen.dart';
import 'admin_forecast_screen.dart';
import 'login_screen.dart';

enum AdminMapType { tactical, google }

// ─── ROOM IMAGE MAPPING ───────────────────────────────────────────────────────
// Maps room IDs to representative image URLs for the room cards.
const Map<String, String> kRoomImages = {
  'DK1':
      'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=480&q=80',
  '24h Study':
      'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=480&q=80',
  'Lounge':
      'https://images.unsplash.com/photo-1610465300074-8d9479f65640?w=480&q=80',
};

const String _kDefaultRoomImage =
    'https://images.unsplash.com/photo-1497366216548-37526070297c?w=480&q=80';

// ─── NEURAL MAP COORDINATES ──────────────────────────────────────────────────
// Maps room IDs to pixel-percentage offsets (0.0 - 1.0) on the isometric render.
const Map<String, Offset> kNeuralOffsets = {
  'DK1': Offset(0.42, 0.45),
  '24h Study': Offset(0.38, 0.52),
  'Lounge': Offset(0.45, 0.55),
  'FK Tower': Offset(0.32, 0.48),
  'Eng Lab 4': Offset(0.28, 0.54),
  'Eng Room A': Offset(0.35, 0.58),
  'DTC Hall': Offset(0.55, 0.38),
  'DTC Stage': Offset(0.58, 0.32),
  'Physics Lab 1': Offset(0.62, 0.45),
  'Library Ground': Offset(0.48, 0.42),
  'Lake Cafe': Offset(0.65, 0.58),
  'Science Block C': Offset(0.72, 0.42),
  'UM Gate': Offset(0.15, 0.65),
  'Varsity Hall': Offset(0.52, 0.62),
};

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final AdminService _service = AdminService();
  static const gmaps.LatLng _campusCenter = gmaps.LatLng(3.1200, 101.6600);
  bool _showListView = false;
  AdminMapType _mapType = AdminMapType.tactical;
  // mapbox.MapboxMapController? _mapboxController;

  // ── CYBER MAP STYLE ────────────────────────────────────────────────────────
  final String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [{ "color": "#111821" }] },
  { "elementType": "labels.icon", "stylers": [{ "visibility": "off" }] },
  { "elementType": "labels.text.fill", "stylers": [{ "color": "#6b7280" }] },
  { "elementType": "labels.text.stroke", "stylers": [{ "color": "#111821" }] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [{ "color": "#374151" }] },
  { "featureType": "landscape", "elementType": "geometry", "stylers": [{ "color": "#0d1117" }] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [{ "color": "#1f2937" }] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [{ "color": "#374151" }] },
  { "featureType": "road", "elementType": "geometry.stroke", "stylers": [{ "color": "#1f2937" }] },
  { "featureType": "water", "elementType": "geometry", "stylers": [{ "color": "#060d17" }] }
]
''';

  double _hueFromStatus(String? statusColor) {
    switch (statusColor) {
      case 'RED':
        return gmaps.BitmapDescriptor.hueRed;
      case 'PURPLE':
        return gmaps.BitmapDescriptor.hueViolet;
      default:
        return gmaps.BitmapDescriptor.hueGreen;
    }
  }

  Set<gmaps.Marker> _buildGoogleMarkers(QuerySnapshot snapshot) {
    final Set<gmaps.Marker> markers = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final roomId = doc.id;

      gmaps.LatLng? position;
      if (data.containsKey('lat') && data.containsKey('lng')) {
        position = gmaps.LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );
      } else {
        final fallback = kRoomLocations[roomId];
        position = fallback != null
            ? gmaps.LatLng(fallback.latitude, fallback.longitude)
            : _campusCenter;
      }
      final statusColor = data['status_color'] as String? ?? 'GREEN';
      final roomName = data['room_name'] as String? ?? roomId;
      markers.add(gmaps.Marker(
        markerId: gmaps.MarkerId(roomId),
        position: position,
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            _hueFromStatus(statusColor)),
        onTap: () => _openRoomDetail(roomId, roomName),
      ));
    }
    return markers;
  }

  /* 
  void _updateMapboxMarkers(QuerySnapshot snapshot) {
    if (_mapboxController == null) return;
    _mapboxController!.clearSymbols();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final roomId = doc.id;

      mapbox.LatLng? position;
      if (data.containsKey('lat') && data.containsKey('lng')) {
        position = mapbox.LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );
      } else {
        final fallback = kRoomLocations[roomId];
        position = fallback != null 
            ? gmaps.LatLng(fallback.latitude, fallback.longitude)
            : _campusCenter;
      }

      final statusColor = data['status_color'] as String? ?? 'GREEN';
      String iconImage = 'marker-green';
      if (statusColor == 'RED') iconImage = 'marker-red';
      if (statusColor == 'PURPLE') iconImage = 'marker-purple';

      _mapboxController!.addSymbol(mapbox.SymbolOptions(
        geometry: position,
        iconImage: iconImage,
        iconSize: 1.5,
        textField: data['room_name'] as String? ?? roomId,
        textOffset: const Offset(0, 2),
        textColor: '#FFFFFF',
        textHaloColor: '#000000',
        textHaloWidth: 1.0,
      ));
    }
  }
  */

  void _openRoomDetail(String roomId, String roomName) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminRoomDetailScreen(roomId: roomId, roomName: roomName),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821),
      body: Stack(
        children: [
          // ── MAP VIEW (API or FALLBACK) ──
          if (!_showListView)
            Positioned.fill(
              child: StreamBuilder<QuerySnapshot>(
                stream: _service.roomsStream(),
                builder: (context, snapshot) {
                  return Stack(
                    children: [
                      // ── GOOGLE MAP (Legacy) ──
                      if (_mapType == AdminMapType.google)
                        Positioned.fill(
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -1,
                              0,
                              0,
                              0,
                              255,
                              0,
                              -1,
                              0,
                              0,
                              255,
                              0,
                              0,
                              -1,
                              0,
                              255,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.33,
                                0.33,
                                0.33,
                                0,
                                0,
                                0.33,
                                0.33,
                                0.33,
                                0,
                                0,
                                0.33,
                                0.33,
                                0.33,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ]),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  1.2,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0.5,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: gmaps.GoogleMap(
                                  initialCameraPosition:
                                      const gmaps.CameraPosition(
                                          target: _campusCenter, zoom: 17.5),
                                  style: _darkMapStyle,
                                  markers: snapshot.hasData
                                      ? _buildGoogleMarkers(snapshot.data!)
                                      : <gmaps.Marker>{},
                                  mapType: gmaps.MapType.normal,
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  compassEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ── TACTICAL MAP (Vectors Offline) ──
                      if (_mapType == AdminMapType.tactical)
                        Positioned.fill(
                          child: GeoJsonMap(
                            docs: snapshot.hasData ? snapshot.data!.docs : [],
                            onRoomTap: (roomId, roomName) =>
                                _openRoomDetail(roomId, roomName),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

          if (_showListView)
            Positioned.fill(
              top: 180,
              child: _TacticalListView(
                  service: _service, onRoomTap: _openRoomDetail),
            ),

          // Subtle dark gradient overlay
          if (!_showListView)
            const IgnorePointer(
              child: Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99111821),
                        Color(0x00111821),
                        Color(0x00111821),
                        Color(0xCC111821)
                      ],
                      stops: [0.0, 0.2, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // ── GLASSMORPHIC HEADER ──
          _EcoCommandHeader(
            service: _service,
            isListView: _showListView,
            onToggleView: () => setState(() => _showListView = !_showListView),
          ),

          // ── MAP LEGEND ──
          if (!_showListView)
            Positioned(
              top: 280,
              left: 16,
              child: _MapLegend(
                selectedType: _mapType,
                onTypeChanged: (type) => setState(() => _mapType = type),
              ),
            ),

          // ── ACTIVE ZONES BOTTOM PANEL (DRAGGABLE) ──
          if (!_showListView)
            _ActiveZonesPanel(service: _service, onRoomTap: _openRoomDetail),
        ],
      ),
    );
  }
}

// ─── ECO-COMMAND HEADER ───────────────────────────────────────────────────────
class _EcoCommandHeader extends StatelessWidget {
  final AdminService service;
  final bool isListView;
  final VoidCallback onToggleView;
  const _EcoCommandHeader({
    required this.service,
    required this.isListView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2B0D3E).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Brand + Alert Badge & Bypass Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Brand
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hub_outlined,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'ECO-COMMAND',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const _PulsingDot(color: Color(0xFF39FF14)),
                                const SizedBox(width: 6),
                                Text(
                                  'SYSTEM STATUS: ONLINE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Control Row: Insights, Forecast, Sign Out
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Insights Button
                            _HeaderActionButton(
                              icon: Icons.query_stats_rounded,
                              color: const Color(0xFF00F3FF),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminInsightsScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Forecast Button
                            _HeaderActionButton(
                              icon: Icons.auto_graph_rounded,
                              color: const Color(0xFF00FF87),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminForecastScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sign Out Button
                            _HeaderActionButton(
                              icon: Icons.power_settings_new_rounded,
                              color: const Color(0xFFFF073A),
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status Ticker
                    Row(
                      children: [
                        Text('NODE FEED: ',
                            style: GoogleFonts.inter(
                                color: Colors.white24,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                        Text(
                          isListView
                              ? 'LIVE ANOMALY FEED (TACTICAL)'
                              : 'REAL-TIME GEOSPATIAL SCANNING...',
                          style: GoogleFonts.inter(
                              color: isListView
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFF39FF14),
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    Divider(
                        color: Colors.white.withValues(alpha: 0.1), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Daily Savings
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAILY SAVINGS',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<double>(
                                stream: service.dailySavingsStream(),
                                builder: (context, snap) {
                                  final savings = snap.data ?? 1245.0;
                                  final formatted = savings
                                      .toStringAsFixed(0)
                                      .replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (m) => '${m[1]},',
                                      );
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        'RM $formatted',
                                        style: GoogleFonts.inter(
                                          color: const Color(
                                              0xFF00FF87), // Green for savings
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Center/Right Divider
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.1),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        // Right: Live Energy Leak
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'TOTAL ENERGY LEAK',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFFF073A)
                                          .withValues(alpha: 0.6),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const _PulsingDot(
                                      color: Color(0xFFFF073A), size: 4),
                                ],
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<double>(
                                stream: service.totalWasteStream(),
                                builder: (context, snap) {
                                  final waste = snap.data ?? 0.0;
                                  final formatted = waste.toStringAsFixed(2);
                                  return Text(
                                    'RM $formatted',
                                    style: GoogleFonts.inter(
                                      color: const Color(
                                          0xFFFF073A), // Red for waste
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveZonesPanel extends StatefulWidget {
  final AdminService service;
  final Function(String, String) onRoomTap;
  const _ActiveZonesPanel({required this.service, required this.onRoomTap});

  @override
  State<_ActiveZonesPanel> createState() => _ActiveZonesPanelState();
}

class _ActiveZonesPanelState extends State<_ActiveZonesPanel> {
  bool _showOnlyCritical = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.32,
      maxChildSize: 0.92, // Cover whole screen except top bar
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F15).withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Drag handle & Header
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Section header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.sensors,
                                      color: Color(0xFF00F3FF), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _showOnlyCritical
                                        ? 'CRITICAL ALERTS'
                                        : 'ACTIVE ZONES',
                                    style: GoogleFonts.inter(
                                      color: _showOnlyCritical
                                          ? const Color(0xFFFF073A)
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  StreamBuilder<int>(
                                    stream: widget.service.alertCountStream(),
                                    builder: (context, snap) {
                                      final count = snap.data ?? 0;
                                      if (count == 0 && !_showOnlyCritical) {
                                        return const SizedBox.shrink();
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showOnlyCritical =
                                                !_showOnlyCritical;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _showOnlyCritical
                                                ? const Color(0xFFFF073A)
                                                : const Color(0xFFFF073A)
                                                    .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: const Color(0xFFFF073A)
                                                    .withValues(alpha: 0.5)),
                                            boxShadow: [
                                              if (_showOnlyCritical)
                                                BoxShadow(
                                                  color: const Color(0xFFFF073A)
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 8,
                                                )
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  _showOnlyCritical
                                                      ? Icons.filter_list
                                                      : Icons.warning_rounded,
                                                  color: Colors.white,
                                                  size: 10),
                                              const SizedBox(width: 4),
                                              Text(
                                                _showOnlyCritical
                                                    ? 'CLEAR'
                                                    : '$count',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (_showOnlyCritical)
                                Text(
                                  'FILTER ACTIVE',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFF073A)
                                        .withValues(alpha: 0.5),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Room Content (Grid when expanded, List-like when small)
                  StreamBuilder<QuerySnapshot>(
                    stream: widget.service.roomsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF39FF14), strokeWidth: 2),
                          ),
                        );
                      }
                      var docs = snapshot.data!.docs;

                      // Apply Filter
                      if (_showOnlyCritical) {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['status_color'] == 'RED';
                        }).toList();
                      }

                      if (docs.isEmpty && _showOnlyCritical) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: const Color(0xFF39FF14)
                                        .withValues(alpha: 0.2),
                                    size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'NO CRITICAL ANOMALIES',
                                  style: GoogleFonts.inter(
                                    color: Colors.white24,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Using a SliverGrid for consistent layout
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final data =
                                  docs[i].data() as Map<String, dynamic>;
                              final roomId = docs[i].id;
                              final name =
                                  data['room_name'] as String? ?? roomId;
                              final statusColor =
                                  data['status_color'] as String? ?? 'GREEN';
                              final temp =
                                  (data['internal_temp'] as num?)?.toInt() ??
                                      22;
                              final imageUrl =
                                  kRoomImages[roomId] ?? _kDefaultRoomImage;

                              return _RoomCard(
                                roomId: roomId,
                                name: name,
                                statusColor: statusColor,
                                temp: temp,
                                imageUrl: imageUrl,
                                onTap: () => widget.onRoomTap(roomId, name),
                              );
                            },
                            childCount: docs.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── ROOM CARD ────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final String roomId;
  final String name;
  final String statusColor;
  final int temp;
  final String imageUrl;
  final VoidCallback onTap;

  const _RoomCard({
    required this.roomId,
    required this.name,
    required this.statusColor,
    required this.temp,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = statusColor == 'RED';
    final isIdle = statusColor == 'PURPLE';

    final badgeColor = isAlert
        ? const Color(0xFFFF073A)
        : isIdle
            ? const Color(0xFF00F3FF)
            : const Color(0xFF39FF14);
    final badgeText = isAlert
        ? 'Alert'
        : isIdle
            ? 'Idle'
            : 'Live';
    final statusText = isAlert
        ? 'Critical'
        : isIdle
            ? 'Eco-Mode'
            : 'Optimal';
    final statusIcon = isAlert
        ? Icons.thermostat
        : isIdle
            ? Icons.eco
            : Icons.wifi_tethering;

    final borderColor = isAlert
        ? const Color(0xFFFF073A).withValues(alpha: 0.35)
        : isIdle
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1);

    final cardBg = isAlert
        ? const Color(0xFF2D0A0A).withValues(alpha: 0.8)
        : const Color(0xFF141928).withValues(alpha: 0.85);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isAlert
              ? [
                  BoxShadow(
                      color: const Color(0xFFFF073A).withValues(alpha: 0.08),
                      blurRadius: 20)
                ]
              : [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image section ──
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Room image or alert placeholder
                  isAlert
                      ? Container(
                          color: Colors.black.withValues(alpha: 0.8),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF073A)
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                const Icon(Icons.warning_rounded,
                                    color: Color(0xFFFF073A), size: 38),
                              ],
                            ),
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF1F2937)),
                        ),

                  // Gradient at bottom of image
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7)
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Alert pulsing overlay
                  if (isAlert)
                    const Positioned.fill(
                      child: _PulsingOverlay(color: Color(0xFFFF073A)),
                    ),

                  // Live/Idle/Alert badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: badgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingDot(color: badgeColor, size: 5),
                          const SizedBox(width: 4),
                          Text(badgeText,
                              style: GoogleFonts.inter(
                                color: isAlert
                                    ? const Color(0xFFFF073A)
                                    : Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              )),
                        ],
                      ),
                    ),
                  ),

                  // Status label (bottom-left of image)
                  Positioned(
                    bottom: 6,
                    left: 10,
                    child: Row(
                      children: [
                        Icon(statusIcon, color: badgeColor, size: 12),
                        const SizedBox(width: 4),
                        Text(statusText,
                            style: GoogleFonts.inter(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Info section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TEMP',
                              style: GoogleFonts.inter(
                                color: isAlert
                                    ? const Color(0xFFef4444)
                                    : Colors.white38,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              )),
                          Text.rich(
                            TextSpan(
                              text: '$temp',
                              style: GoogleFonts.inter(
                                color: isAlert
                                    ? const Color(0xFFFF073A)
                                    : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                              children: [
                                TextSpan(
                                  text: '°C',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('OCCUPANCY',
                              style: GoogleFonts.inter(
                                color: Colors.white24,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              )),
                          const SizedBox(height: 4),
                          _WaveformBars(
                            barCount: 7,
                            color: isAlert
                                ? const Color(0xFFFF073A)
                                : const Color(0xFF1978E5),
                            active: !isIdle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MAP LEGEND ───────────────────────────────────────────────────────────────
class _MapLegend extends StatelessWidget {
  final AdminMapType selectedType;
  final Function(AdminMapType) onTypeChanged;
  const _MapLegend({required this.selectedType, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    // Map Selection HUD
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapToggleButton(
            icon: Icons.layers_outlined,
            label: 'TACTICAL MAP (OFFLINE)',
            active: selectedType == AdminMapType.tactical,
            color: const Color(0xFF00E5FF),
            onTap: () => onTypeChanged(AdminMapType.tactical),
          ),
          const SizedBox(height: 4),
          _MapToggleButton(
            icon: Icons.public_rounded,
            label: 'GOOGLE (LEGACY)',
            active: selectedType == AdminMapType.google,
            color: const Color(0xFF39FF14),
            onTap: () => onTypeChanged(AdminMapType.google),
          ),
        ],
      ),
    );
  }
}

class _MapToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _MapToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? color : Colors.white38, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: active ? Colors.white : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WAVEFORM BARS ────────────────────────────────────────────────────────────
class _WaveformBars extends StatefulWidget {
  final int barCount;
  final Color color;
  final bool active;
  const _WaveformBars(
      {required this.barCount, required this.color, required this.active});

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      // Idle: static minimal bars
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
            widget.barCount,
            (i) => Container(
                  width: 3,
                  height: 4,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                )),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (i) {
            final phase = (i / widget.barCount) * 2 * math.pi;
            final offset = (_controller.value * 2 * math.pi) + phase;
            final height = 6 + (math.sin(offset) * 8).abs();
            final opacity = 0.4 + (math.sin(offset + math.pi / 4) * 0.5).abs();
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  if (opacity > 0.7)
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 4),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── PULSING DOT ─────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, this.size = 6});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.8),
              blurRadius: 8 + _anim.value * 6,
              spreadRadius: _anim.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PULSING OVERLAY ─────────────────────────────────────────────────────────
class _PulsingOverlay extends StatefulWidget {
  final Color color;
  const _PulsingOverlay({required this.color});

  @override
  State<_PulsingOverlay> createState() => _PulsingOverlayState();
}

class _PulsingOverlayState extends State<_PulsingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          color: widget.color.withValues(alpha: _ctrl.value * 0.08),
        ),
      );
}

// ─── TACTICAL LIST VIEW ──────────────────────────────────────────────────────
class _TacticalListView extends StatelessWidget {
  final AdminService service;
  final Function(String, String) onRoomTap;
  const _TacticalListView({required this.service, required this.onRoomTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: service.roomsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final roomId = docs[i].id;
            final roomName = data['room_name'] ?? roomId;
            final statusColor = data['status_color'] ?? 'GREEN';
            final status = data['status'] ?? 'stable';

            Color color = const Color(0xFF39FF14);
            if (statusColor == 'RED') color = const Color(0xFFFF073A);
            if (statusColor == 'PURPLE') color = const Color(0xFFA020F0);

            return GestureDetector(
              onTap: () => onRoomTap(roomId, roomName),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2833).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.05), blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusColor == 'RED'
                            ? Icons.warning_amber_rounded
                            : Icons.sensors,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(roomName,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            status.toUpperCase(),
                            style: GoogleFonts.inter(
                                color: color.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── HEADER ACTION BUTTON ──────────────────────────────────────────────────
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
