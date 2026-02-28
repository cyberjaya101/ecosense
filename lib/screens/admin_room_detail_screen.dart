import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';

class AdminRoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  const AdminRoomDetailScreen(
      {super.key, required this.roomId, required this.roomName});

  @override
  State<AdminRoomDetailScreen> createState() => _AdminRoomDetailScreenState();
}

class _AdminRoomDetailScreenState extends State<AdminRoomDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _scanCtrl;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    return Scaffold(
      backgroundColor: const Color(0xFF111821),
      body: Stack(
        children: [
          // ── BACKGROUND: grid pattern + corner glows ───────────────────────
          Positioned.fill(child: _GridBackground()),

          // Top-right purple glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBC13FE).withValues(alpha: 0.08),
              ),
            ),
          ),
          // Bottom-left blue glow
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1978E5).withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── CONTENT ───────────────────────────────────────────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: service.singleRoomStream(widget.roomId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF39FF14), strokeWidth: 2));
              }
              final raw = snapshot.data!.data();
              final data = raw as Map<String, dynamic>? ?? {};

              final String statusColor = data['status_color'] ?? 'GREEN';
              final String? imageUrl = data['image_url'];
              final double wasteRm =
                  (data['total_estimated_ringgit_waste'] as num?)?.toDouble() ??
                      0.0;
              final Map<String, dynamic>? aiInsight =
                  data['pending_action'] as Map<String, dynamic>?;
              final List<dynamic> feedback =
                  data['recent_qualitative_feedback'] as List<dynamic>? ?? [];
              final Map<String, dynamic> reportCounts =
                  data['reports'] as Map<String, dynamic>? ?? {};
              final int hotCount = (reportCounts['TOO_HOT'] ?? 0) as int;
              final int coldCount = (reportCounts['TOO_COLD'] ?? 0) as int;
              final int ghostCount = (reportCounts['GHOST_ROOM'] ?? 0) as int;
              final int riskScore =
                  (aiInsight?['risk_score'] as num?)?.toInt() ?? 0;
              final bool isAlert = statusColor == 'RED';
              final bool isIdle = statusColor == 'PURPLE';

              final Color accentColor = isAlert
                  ? const Color(0xFFFF073A)
                  : isIdle
                      ? const Color(0xFFBC13FE)
                      : const Color(0xFF39FF14);

              final String threatLabel = isAlert
                  ? 'Threat Level: High'
                  : isIdle
                      ? 'Status: Analyzing'
                      : 'Status: Nominal';

              return SafeArea(
                child: Column(
                  children: [
                    // ── GLASSMORPHIC HEADER ────────────────────────────────
                    _buildHeader(context, accentColor, threatLabel, isAlert),

                    // ── HERO IMAGE ────────────────────────────────────────
                    _HeroImage(imageUrl: imageUrl, accentColor: accentColor),

                    // ── SCROLLABLE BODY ────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                        child: Column(
                          children: [
                            // 2-col grid: Risk Core + Waste Metric
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _RiskCoreCard(
                                  riskScore: riskScore,
                                  statusColor: statusColor,
                                  ringController: _ringCtrl,
                                )),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                  children: [
                                    _WasteMetricCard(
                                      wasteRm: wasteRm,
                                      isAlert: isAlert,
                                    ),
                                    const SizedBox(height: 12),
                                    _AnomalySummaryStrip(
                                      hotCount: hotCount,
                                      coldCount: coldCount,
                                      ghostCount: ghostCount,
                                    ),
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Neural Insight panel
                            _NeuralInsightPanel(
                              aiInsight: aiInsight,
                              statusColor: statusColor,
                              accentColor: accentColor,
                              scanController: _scanCtrl,
                              hotCount: hotCount,
                              coldCount: coldCount,
                              ghostCount: ghostCount,
                            ),
                            const SizedBox(height: 16),

                            // Recent Transmissions (user feedback)
                            if (feedback.isNotEmpty)
                              _RecentTransmissionsCard(feedback: feedback),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── STICKY BOTTOM ACTIONS ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomActions(
              roomId: widget.roomId,
              service: service,
              resolving: _resolving,
              onResolve: () async {
                setState(() => _resolving = true);
                await service.resolveRoom(widget.roomId);
                if (mounted) Navigator.pop(context);
              },
              onDismiss: () async {
                await service.dismissAlert(widget.roomId);
                if (mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext ctx, Color accent, String threatLabel, bool isAlert) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF111821).withValues(alpha: 0.85),
                Colors.transparent
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ),

                  // Room name + threat badge
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.roomName.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 15)
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Threat level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isAlert
                                    ? const Color(0xFFFF073A)
                                        .withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.1)),
                            gradient: LinearGradient(colors: [
                              isAlert
                                  ? const Color(0xFFFF073A)
                                      .withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.03),
                              isAlert
                                  ? const Color(0xFFFF073A)
                                      .withValues(alpha: 0.05)
                                  : Colors.transparent,
                            ]),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_rounded,
                                  color: isAlert
                                      ? const Color(0xFFFF073A)
                                      : Colors.white38,
                                  size: 12),
                              const SizedBox(width: 6),
                              Text(
                                threatLabel.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color:
                                      isAlert ? Colors.white : Colors.white54,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LIVE badge
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const _PulsingDot(color: Color(0xFF39FF14)),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                  color: const Color(0xFF39FF14)
                                      .withValues(alpha: 0.8),
                                  blurRadius: 8)
                            ],
                          ),
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
    );
  }
}

// ─── RISK CORE CARD ───────────────────────────────────────────────────────────
class _RiskCoreCard extends StatelessWidget {
  final int riskScore;
  final String statusColor;
  final AnimationController ringController;
  const _RiskCoreCard(
      {required this.riskScore,
      required this.statusColor,
      required this.ringController});

  @override
  Widget build(BuildContext context) {
    final isAlert = statusColor == 'RED';
    final accentColor = isAlert
        ? const Color(0xFFFF073A)
        : statusColor == 'PURPLE'
            ? const Color(0xFFBC13FE)
            : const Color(0xFF39FF14);
    final displayScore = riskScore > 0 ? riskScore : (isAlert ? 75 : 22);
    final riskLabel = isAlert
        ? 'CRITICAL'
        : statusColor == 'PURPLE'
            ? 'MODERATE'
            : 'SAFE';

    return _NeuralCard(
      child: Column(
        children: [
          Text('RISK CORE',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.04),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.2)),
                  ),
                ),
                // Spinning conic ring
                AnimatedBuilder(
                  animation: ringController,
                  builder: (_, __) => Transform.rotate(
                    angle: ringController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(140, 140),
                      painter: _ConicRingPainter(
                        sweepFraction: displayScore / 100,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$displayScore%',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 10)
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(riskLabel,
                          style: GoogleFonts.inter(
                            color: accentColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAlert ? 'SECTOR 4 UNSTABLE' : 'SECTOR NOMINAL',
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CONIC RING PAINTER ───────────────────────────────────────────────────────
class _ConicRingPainter extends CustomPainter {
  final double sweepFraction;
  final Color color;
  const _ConicRingPainter({required this.sweepFraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;
    final innerRadius = radius - strokeWidth;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepFraction * 2 * math.pi,
        colors: [color.withValues(alpha: 0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepFraction * 2 * math.pi,
      false,
      fgPaint..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3),
    );

    // Glow draw
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepFraction * 2 * math.pi,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── WASTE METRIC CARD ────────────────────────────────────────────────────────
class _WasteMetricCard extends StatelessWidget {
  final double wasteRm;
  final bool isAlert;
  const _WasteMetricCard({required this.wasteRm, required this.isAlert});

  @override
  Widget build(BuildContext context) {
    final displayWaste = wasteRm > 0 ? wasteRm : 45.30;

    return _NeuralCard(
      padding: const EdgeInsets.all(10), // Even more compact
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WASTE METRIC',
                style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color:
                    isAlert ? const Color(0xFFFF073A) : const Color(0xFF1978E5),
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'RM ${displayWaste.toStringAsFixed(2)}',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18, // Much smaller
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'PROJECTED DAILY DRAIN',
            style: GoogleFonts.inter(
              color: isAlert
                  ? const Color(0xFFFF073A).withValues(alpha: 0.7)
                  : Colors.white38,
              fontSize: 7,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NEURAL INSIGHT PANEL ────────────────────────────────────────────────────
class _NeuralInsightPanel extends StatelessWidget {
  final Map<String, dynamic>? aiInsight;
  final String statusColor;
  final Color accentColor;
  final AnimationController scanController;
  final int hotCount;
  final int coldCount;
  final int ghostCount;
  const _NeuralInsightPanel({
    required this.aiInsight,
    required this.statusColor,
    required this.accentColor,
    required this.scanController,
    required this.hotCount,
    required this.coldCount,
    required this.ghostCount,
  });

  @override
  Widget build(BuildContext context) {
    final String reasoning =
        aiInsight?['reasoning'] ?? 'Gathering system context...';
    final String recommendation =
        aiInsight?['recommendation'] ?? 'Monitor and report.';
    final int confidence =
        ((aiInsight?['risk_score'] as num?)?.toInt() ?? 94).clamp(0, 100);
    final bool isAlert = statusColor == 'RED';
    final bool isIdle = statusColor == 'PURPLE';

    return _NeuralCard(
      hasScanLine: true,
      scanController: scanController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFFBC13FE),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text('NEURAL INSIGHT',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      )),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF39FF14)),
                  ),
                  const SizedBox(width: 4),
                  Text('ACTIVE_SCAN',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),

          // Inner grid
          Column(
            children: [
              // Root Cause Analysis (full width)
              _TacticalCell(
                accentColor: isAlert ? const Color(0xFFFF073A) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ROOT CAUSE ANALYSIS',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            )),
                        Icon(Icons.thermostat_rounded,
                            color: isAlert
                                ? const Color(0xFFFF073A)
                                : Colors.white38,
                            size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(reasoning,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          shadows: isAlert
                              ? [
                                  Shadow(
                                      color: const Color(0xFFFF073A)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8)
                                ]
                              : [],
                        )),
                    const SizedBox(height: 2),
                    Text(recommendation,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFA5B4FC).withValues(alpha: 0.8),
                          fontSize: 8,
                        )),
                    const SizedBox(height: 6),
                    // Confidence bar
                    Row(
                      children: [
                        Text('CONFIDENCE',
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(2)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: confidence / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: isAlert
                                        ? [
                                            const Color(0xFFFF073A),
                                            Colors.orange
                                          ]
                                        : [
                                            const Color(0xFF39FF14),
                                            const Color(0xFF1978E5)
                                          ]),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAlert
                                            ? const Color(0xFFFF073A)
                                            : const Color(0xFF39FF14))
                                        .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ),
                        )),
                        const SizedBox(width: 8),
                        Text('$confidence%',
                            style: GoogleFonts.inter(
                              color: isAlert
                                  ? const Color(0xFFFF073A)
                                  : const Color(0xFF39FF14),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  // Status cell
                  Expanded(
                    child: _TacticalCell(
                      accentColor: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('STATUS',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  )),
                              Icon(
                                  !isAlert && !isIdle
                                      ? Icons.check_circle_outline_rounded
                                      : (hotCount >= coldCount &&
                                              hotCount >= ghostCount)
                                          ? Icons.local_fire_department_rounded
                                          : (coldCount >= hotCount &&
                                                  coldCount >= ghostCount)
                                              ? Icons.ac_unit_rounded
                                              : Icons.visibility_off_outlined,
                                  color: Colors.white38,
                                  size: 14),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              !isAlert && !isIdle
                                  ? 'Nominal'
                                  : (hotCount >= coldCount &&
                                          hotCount >= ghostCount)
                                      ? 'Too Hot'
                                      : (coldCount >= hotCount &&
                                              coldCount >= ghostCount)
                                          ? 'Too Cold'
                                          : 'Ghost Room',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          Text(
                              !isAlert && !isIdle
                                  ? 'All systems stable'
                                  : (hotCount >= coldCount &&
                                          hotCount >= ghostCount)
                                      ? '$hotCount reports / High Load'
                                      : (coldCount >= hotCount &&
                                              coldCount >= ghostCount)
                                          ? '$coldCount reports / High Load'
                                          : '0 Pax / Active AC',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 9),
                              maxLines: 1),
                          const SizedBox(height: 10),
                          const _ConfidenceBarRow(
                              label: 'Certainty',
                              value: 0.98,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action cell
                  Expanded(
                    child: _TacticalCell(
                      accentColor: const Color(0xFF00F3FF),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ACTION',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  )),
                              const Icon(Icons.power_settings_new,
                                  color: Color(0xFF00F3FF), size: 14),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              !isAlert && !isIdle
                                  ? 'Monitor'
                                  : (hotCount >= coldCount &&
                                          hotCount >= ghostCount)
                                      ? 'Adjust'
                                      : (coldCount >= hotCount &&
                                              coldCount >= ghostCount)
                                          ? 'Adjust'
                                          : 'Override',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00F3FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                      color: const Color(0xFF00F3FF)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8)
                                ],
                              )),
                          Text(
                              !isAlert && !isIdle
                                  ? 'System Auto'
                                  : (hotCount >= coldCount &&
                                          hotCount >= ghostCount)
                                      ? 'Lower Setpoint'
                                      : (coldCount >= hotCount &&
                                              coldCount >= ghostCount)
                                          ? 'Raise Setpoint'
                                          : 'Shutdown Zone',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 9)),
                          const SizedBox(height: 10),
                          const _ConfidenceBarRow(
                              label: 'Logic',
                              value: 0.89,
                              color: Color(0xFF00F3FF)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── RECENT TRANSMISSIONS ────────────────────────────────────────────────────
class _RecentTransmissionsCard extends StatelessWidget {
  final List<dynamic> feedback;
  const _RecentTransmissionsCard({required this.feedback});

  static const List<Color> _avatarGradients = [
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
  ];

  @override
  Widget build(BuildContext context) {
    return _NeuralCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF1978E5)),
              ),
              const SizedBox(width: 8),
              Text('RECENT TRANSMISSIONS',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...feedback.take(4).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final dynamic rawF = entry.value;
            String message = "";
            String name = "Alex Rivera"; // Default for demo

            if (rawF is Map) {
              final type = rawF['type'] ?? 'Report';
              message = (type == 'TOO_COLD')
                  ? "Room is freezing!"
                  : (type == 'TOO_HOT')
                      ? "It's too hot here."
                      : (type == 'GHOST_ROOM')
                          ? "AC is on in empty room!"
                          : "General comfort report.";
              if (rawF['reporter_id'] != 'alex_rivera') {
                name =
                    "User ${rawF['reporter_id']?.toString().split('_').last ?? i}";
              }
            } else {
              message = rawF.toString();
              name = "System Event";
            }

            final gradientColor = _avatarGradients[i % _avatarGradients.length];
            final timeLabels = ['Just Now', '15m ago', '1h ago', '3h ago'];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradientColor,
                          gradientColor.withValues(alpha: 0.5)
                        ],
                      ),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                )),
                            Text(timeLabels[i % timeLabels.length],
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 8,
                                )),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('"$message"',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── BOTTOM ACTIONS ───────────────────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  final String roomId;
  final AdminService service;
  final bool resolving;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;
  const _BottomActions({
    required this.roomId,
    required this.service,
    required this.resolving,
    required this.onResolve,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF111821).withValues(alpha: 0.97)
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Engage Resolution
              GestureDetector(
                onTap: resolving ? null : onResolve,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1978E5),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1978E5).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: -4,
                      )
                    ],
                    border: Border.all(
                        color: const Color(0xFF1978E5).withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: resolving
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('ENGAGE RESOLUTION',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  )),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Dismiss
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune, color: Colors.white60, size: 16),
                        const SizedBox(width: 8),
                        Text('Dismiss Alert',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _NeuralCard extends StatelessWidget {
  final Widget child;
  final bool hasScanLine;
  final AnimationController? scanController;
  final EdgeInsetsGeometry padding;
  const _NeuralCard({
    required this.child,
    this.hasScanLine = false,
    this.scanController,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [Color(0xFF141923), Color(0xFF0A0C10)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background topography pattern
          Positioned.fill(child: _TopoPattern()),
          if (hasScanLine && scanController != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: scanController!,
                builder: (_, __) => Align(
                  alignment: Alignment(0, scanController!.value * 2 - 1),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        const Color(0xFF39FF14).withValues(alpha: 0.6),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _TacticalCell extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  const _TacticalCell({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          // Corner accents
          Positioned(
              top: 0,
              left: 0,
              child: _CornerAccent(
                  accentColor: accentColor, top: true, right: false)),
          Positioned(
              top: 0,
              right: 0,
              child: _CornerAccent(
                  accentColor: accentColor, top: true, right: true)),
          Positioned(
              bottom: 0,
              left: 0,
              child: _CornerAccent(
                  accentColor: accentColor, top: false, right: false)),
          Positioned(
              bottom: 0,
              right: 0,
              child: _CornerAccent(
                  accentColor: accentColor, top: false, right: true)),
          child,
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Color accentColor;
  final bool top;
  final bool right;
  const _CornerAccent(
      {required this.accentColor, required this.top, required this.right});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: CustomPaint(
        painter: _CornerPainter(color: accentColor, top: top, right: right),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool right;
  const _CornerPainter(
      {required this.color, required this.top, required this.right});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, color.a > 0.3 ? 2.0 : 0.0);

    final path = Path();
    if (top && !right) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    }
    if (top && right) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    }
    if (!top && !right) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    if (!top && right) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfidenceBarRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ConfidenceBarRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 7,
                    fontWeight: FontWeight.w700)),
            Text('${(value * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                )),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: 2,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(1)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: _c.value * 0.8),
                    blurRadius: 8 + _c.value * 4)
              ]),
        ),
      );
}

class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _TopoPattern extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TopoPainter(), size: Size.infinite);
}

class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    const n = 8;
    for (var i = 0; i < n; i++) {
      final r = (size.shortestSide / 2) * (i / n);
      canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.25), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── HERO IMAGE ──────────────────────────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final Color accentColor;
  const _HeroImage({this.imageUrl, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: -10,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _ImagePlaceholder(accentColor: accentColor),
            )
          else
            _ImagePlaceholder(accentColor: accentColor),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF111821).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color accentColor;
  const _ImagePlaceholder({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: Center(
        child: Icon(Icons.image_outlined,
            color: accentColor.withValues(alpha: 0.2), size: 40),
      ),
    );
  }
}

// ─── ANOMALY SUMMARY STRIP ───────────────────────────────────────────────────
class _AnomalySummaryStrip extends StatelessWidget {
  final int hotCount;
  final int coldCount;
  final int ghostCount;

  const _AnomalySummaryStrip({
    required this.hotCount,
    required this.coldCount,
    required this.ghostCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnomalySmallCard(
          label: 'HOT',
          count: hotCount,
          color: const Color(0xFFFE53BB),
          icon: Icons.local_fire_department_rounded,
        ),
        const SizedBox(height: 8),
        _AnomalySmallCard(
          label: 'COLD',
          count: coldCount,
          color: const Color(0xFF00E5FF),
          icon: Icons.ac_unit_rounded,
        ),
        const SizedBox(height: 8),
        _AnomalySmallCard(
          label: 'GHOST',
          count: ghostCount,
          color: const Color(0xFF39FF14),
          icon: Icons.visibility_off_outlined,
        ),
      ],
    );
  }
}

class _AnomalySmallCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _AnomalySmallCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: GoogleFonts.orbitron(
              color: count > 0 ? color : Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
