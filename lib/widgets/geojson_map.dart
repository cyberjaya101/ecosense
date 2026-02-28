import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

class GeoJsonMap extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final Function(String, String) onRoomTap;

  const GeoJsonMap({
    super.key,
    required this.docs,
    required this.onRoomTap,
  });

  @override
  State<GeoJsonMap> createState() => _GeoJsonMapState();
}

class _GeoJsonMapState extends State<GeoJsonMap> {
  Map<String, dynamic>? _geoJson;
  bool _isLoading = true;
  late TransformationController _transformationController;

  double _minLat = 90.0;
  double _maxLat = -90.0;
  double _minLng = 180.0;
  double _maxLng = -180.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadGeoJson() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/maps/um_campus_new.geojson');
      final data = jsonDecode(jsonString);

      if (data['type'] == 'FeatureCollection') {
        for (var feature in data['features']) {
          _updateBounds(feature['geometry']);
        }
      }

      // If no valid points found in range, use firestore markers as secondary bounds
      if (_minLat > _maxLat) {
        for (var doc in widget.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = data['lat'] as double?;
          final lng = data['lng'] as double?;
          if (lat != null && lng != null) {
            _processPoint([lng, lat]);
          }
        }
      }

      setState(() {
        _geoJson = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading GeoJSON: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updateBounds(Map<String, dynamic>? geometry) {
    if (geometry == null) return;
    final type = geometry['type'];
    final coords = geometry['coordinates'];

    if (coords == null) return;

    if (type == 'Point') {
      _processPoint(coords);
    } else if (type == 'LineString') {
      for (var pt in coords) {
        _processPoint(pt);
      }
    } else if (type == 'Polygon') {
      for (var ring in coords) {
        for (var pt in ring) {
          _processPoint(pt);
        }
      }
    } else if (type == 'MultiPolygon') {
      for (var poly in coords) {
        for (var ring in poly) {
          for (var pt in ring) {
            _processPoint(pt);
          }
        }
      }
    }
  }

  void _processPoint(List<dynamic> pt) {
    // Standard bounds for the Maps.png background to ensure alignment
    // Shifted left by increasing the longitude bounds
    _minLat = 3.1100;
    _maxLat = 3.1315;
    _minLng = 101.6450;
    _maxLng = 101.6665;
  }

  Widget _buildMarker(
      String roomId, String roomName, String statusColor, VoidCallback onTap) {
    Color color = const Color(0xFF39FF14); // GREEN default
    if (statusColor == 'RED') color = const Color(0xFFFF073A);
    if (statusColor == 'PURPLE') color = const Color(0xFFA020F0);
    if (statusColor == 'ORANGE') color = const Color(0xFFFF8C00);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)
              ],
            ),
            child: Text(
              roomName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Outer glow ring
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              // Inner solid dot
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.9),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }

    if (_geoJson == null) {
      return const Center(
        child: Text('Error loading map data.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const canvasWidth = 2000.0;
        const canvasHeight = 2000.0;

        final double latDiff = _maxLat - _minLat;
        final double lngDiff = _maxLng - _minLng;

        if (latDiff <= 0 || lngDiff <= 0) {
          return const Center(
              child: Text("Map Data Alignment Pending...",
                  style: TextStyle(color: Colors.white54)));
        }

        // Draw smaller margin to see more detail
        const double mapPadding = 50.0;
        const double drawableWidth = canvasWidth - (mapPadding * 2);
        const double drawableHeight = canvasHeight - (mapPadding * 2);

        final double scaleX = drawableWidth / lngDiff;
        final double scaleY = drawableHeight / latDiff;
        final double scale = scaleX < scaleY ? scaleX : scaleY;

        final double xOffset =
            mapPadding + (drawableWidth - (lngDiff * scale)) / 2;
        final double yOffset =
            mapPadding + (drawableHeight - (latDiff * scale)) / 2;

        Offset transform(double lat, double lng) {
          final x = xOffset + (lng - _minLng) * scale;
          final y = yOffset + (_maxLat - lat) * scale;
          return Offset(x, y);
        }

        return InteractiveViewer(
          transformationController: _transformationController,
          maxScale: 8.0,
          minScale: 1.0,
          boundaryMargin: const EdgeInsets.all(0),
          constrained: true,
          panEnabled: true,
          scaleEnabled: true,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.8,
                        child: Image.asset(
                          'assets/maps/Maps.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GeoPainter(
                          geoJson: _geoJson!,
                          docs: widget.docs,
                          minLat: _minLat,
                          maxLat: _maxLat,
                          minLng: _minLng,
                          maxLng: _maxLng,
                          scale: scale,
                          xOffset: xOffset,
                          yOffset: yOffset,
                        ),
                      ),
                    ),
                    ...widget.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final roomId = doc.id;
                      final roomName = data['room_name'] as String? ?? roomId;
                      final statusColor =
                          data['status_color'] as String? ?? 'GREEN';
                      final lat = data['lat'] as double?;
                      final lng = data['lng'] as double?;

                      if (lat == null || lng == null) {
                        return const SizedBox.shrink();
                      }

                      final pos = transform(lat, lng);

                      return Positioned(
                        left: pos.dx - 40,
                        top: pos.dy - 30,
                        child: _buildMarker(
                          roomId,
                          roomName,
                          statusColor,
                          () => widget.onRoomTap(roomId, roomName),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GeoPainter extends CustomPainter {
  final Map<String, dynamic> geoJson;
  final List<QueryDocumentSnapshot> docs;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final double scale;
  final double xOffset;
  final double yOffset;

  _GeoPainter({
    required this.geoJson,
    required this.docs,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.scale,
    required this.xOffset,
    required this.yOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1978E5).withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 100) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 100) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    Offset transform(List<dynamic> pt) {
      final lng = pt[0] as double;
      final lat = pt[1] as double;
      final x = xOffset + (lng - minLng) * scale;
      final y = yOffset + (maxLat - lat) * scale;
      return Offset(x, y);
    }

    if (geoJson['type'] == 'FeatureCollection') {
      List<dynamic> features = geoJson['features'];

      for (var feature in features) {
        final geometry = feature['geometry'];
        if (geometry == null || geometry['type'] != 'Point') continue;

        final props = feature['properties'] ?? {};
        final name = props['name'] as String?;

        // Find matching status in docs
        Color color = const Color(0xFF00E5FF); // Default Cyan
        bool isRoomFound = false;

        if (name != null) {
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['room_name'] == name) {
              isRoomFound = true;
              final statusColor = data['status_color'] as String? ?? 'GREEN';
              if (statusColor == 'RED') color = const Color(0xFFFF073A);
              if (statusColor == 'PURPLE') color = const Color(0xFFA020F0);
              if (statusColor == 'GREEN') color = const Color(0xFF39FF14);
              break;
            }
          }
        }

        final coords = geometry['coordinates'];
        final pt = transform(coords);

        // Indicator Light Paint
        final lightPaint = Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        // Draw indicator light
        canvas.drawCircle(pt, isRoomFound ? 32 : 26, glowPaint);
        canvas.drawCircle(pt, isRoomFound ? 16 : 12, lightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GeoPainter oldDelegate) {
    return true;
  }
}
