import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

class AdminForecastScreen extends StatefulWidget {
  const AdminForecastScreen({super.key});

  @override
  State<AdminForecastScreen> createState() => _AdminForecastScreenState();
}

class _AdminForecastScreenState extends State<AdminForecastScreen>
    with TickerProviderStateMixin {
  final AdminService _service = AdminService();
  late final AnimationController _ringCtrl;
  late final AnimationController _pathCtrl;
  late final AnimationController _topoCtrl;

  // App Colors mapped from Tailwind
  static const _bgDark = Color(0xFF0B1116);
  static const _neonCyan = Color(0xFF00F3FF);
  static const _neonEmerald = Color(0xFF10B981);
  static const _techBlue = Color(0xFF2196F3);
  static const _neonPurple = Color(0xFFBC13FE);

  @override
  void initState() {
    super.initState();
    _ringCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _pathCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _topoCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 30))
          ..repeat();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pathCtrl.dispose();
    _topoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: _service.dailyPredictionStream(),
        builder: (context, predSnapshot) {
          final predData =
              predSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final predictionSummary = predData['prediction_summary'] as String? ??
              'WAITING FOR AI ANALYSIS...';
          final efficiencyTrend =
              predData['efficiency_trend'] as String? ?? '+0.0%';
          final predictedStatus =
              predData['predicted_status'] as String? ?? 'Optimal';
          final aiActions = predData['actions'] as List<dynamic>? ?? [];

          return Scaffold(
            backgroundColor: _bgDark,
            body: Stack(
              children: [
                // Background effects
                const Positioned.fill(child: _GridPattern(opacity: 0.1)),
                const Positioned(
                    top: -100,
                    right: -100,
                    child: _GlowOrb(color: _neonCyan, size: 500)),
                const Positioned(
                    bottom: -100,
                    left: -100,
                    child: _GlowOrb(color: _neonEmerald, size: 400)),

                SafeArea(
                  bottom: false,
                  child: StreamBuilder<double>(
                      stream: _service.totalWasteStream(),
                      builder: (context, wasteSnapshot) {
                        final totalWaste = wasteSnapshot.data ?? 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(
                                context, predictionSummary, efficiencyTrend),
                            Expanded(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 120),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTopographyCard(
                                        totalWaste, predictedStatus),
                                    const SizedBox(height: 24),
                                    _buildEfficiencyTargets(),
                                    const SizedBox(height: 24),
                                    _buildNeuralPath(aiActions),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ),

                // Execute Button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildExecuteButton(),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildHeader(
      BuildContext context, String predictionSummary, String efficiencyTrend) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _bgDark.withValues(alpha: 0.8),
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05)),
              ),
              Text(
                'ECOSENSE AI FORECAST',
                style: GoogleFonts.inter(
                  color: _neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                        color: _neonCyan.withValues(alpha: 0.5), blurRadius: 8)
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () {},
                style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Ring
              SizedBox(
                width: 40,
                height: 80,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _ringCtrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(40, 40),
                          painter: _RingPainter(color: _neonCyan),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 8,
                      child: Icon(Icons.person_pin_circle,
                          color: _neonCyan, size: 24),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('AI PREDICTION',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        )),
                    Text(predictionSummary,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            const Shadow(color: Colors.white30, blurRadius: 15)
                          ],
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _neonEmerald.withValues(alpha: 0.1),
                        border: Border.all(
                            color: _neonEmerald.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up,
                              color: _neonEmerald, size: 12),
                          const SizedBox(width: 4),
                          Text(efficiencyTrend,
                              style: GoogleFonts.orbitron(
                                color: _neonEmerald,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40), // Balanced spacing
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopographyCard(double totalWaste, String predictedStatus) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121922).withValues(alpha: 0.6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _neonCyan,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _neonCyan, blurRadius: 5)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('ENERGY TOPOGRAPHY',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        )),
                  ],
                ),
                Text('T-MINUS 24H',
                    style: GoogleFonts.orbitron(
                      color: _neonCyan.withValues(alpha: 0.8),
                      fontSize: 10,
                    )),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Chart Area
          SizedBox(
            height: 192,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _topoCtrl,
                  builder: (_, __) => _TopoGridPattern(offset: _topoCtrl.value),
                ),
                Center(
                  child: Container(
                      width: 2, color: _neonCyan.withValues(alpha: 0.3)),
                ),
                // Pseudo Graph curve
                Positioned.fill(
                  child: CustomPaint(painter: _GraphPainter()),
                ),
                Positioned(
                  bottom: 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['06:00', '12:00', '18:00', '00:00']
                        .map((e) => Text(e,
                            style: GoogleFonts.orbitron(
                                color: Colors.white54, fontSize: 9)))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Metrics Row
          Row(
            children: [
              _buildMetricCell('Active Student Sensors', '1,420', Colors.white),
              Container(width: 1, height: 60, color: Colors.white10),
              _buildMetricCell('RM at Risk Today',
                  'RM ${totalWaste.toStringAsFixed(2)}', Colors.white),
              Container(width: 1, height: 60, color: Colors.white10),
              _buildMetricCell(
                  'Predicted',
                  predictedStatus,
                  predictedStatus.contains('Crit')
                      ? Colors.redAccent
                      : _neonCyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white.withValues(alpha: 0.01),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyTargets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EFFICIENCY TARGETS',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
                child: _TargetPillar(
                    icon: Icons.loyalty,
                    value: '+450',
                    label: 'Eco-Points',
                    color: _neonEmerald,
                    progress: 0.85)),
            SizedBox(width: 12),
            Expanded(
                child: _TargetPillar(
                    icon: Icons.ac_unit,
                    value: '08%',
                    label: 'HVAC',
                    color: _techBlue,
                    progress: 0.45)),
            SizedBox(width: 12),
            Expanded(
                child: _TargetPillar(
                    icon: Icons.report_problem,
                    value: '86',
                    label: 'Reports',
                    color: _neonPurple,
                    progress: 0.6)),
          ],
        ),
      ],
    );
  }

  Widget _buildNeuralPath(List<dynamic> aiActions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('NEURAL OPTIMIZATION PATH',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4)),
              child: Text('AI_ACTIVATE',
                  style:
                      GoogleFonts.orbitron(color: Colors.white54, fontSize: 9)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (aiActions.isEmpty)
          const _PathNode(
            title: 'Initializing Optimization...',
            subtitle: 'Waiting for Gemini to generate neural path nodes...',
            stepLabel: 'System',
            timeLabel: '...',
            nodeColor: Colors.white10,
            isActive: false,
          )
        else
          ...List.generate(aiActions.length, (index) {
            final action = aiActions[index] as Map<String, dynamic>;
            return _PathNode(
              title: action['title'] ?? 'Node ${index + 1}',
              subtitle: action['subtitle'] ?? 'Calculating...',
              stepLabel: action['type'] ?? 'Task',
              timeLabel: index == 0 ? '0.02s' : (index == 1 ? 'READY' : 'EST'),
              nodeColor: index == 0
                  ? _neonCyan
                  : (index == 1 ? _techBlue : _neonEmerald),
              isActive: index == 0,
              isFirst: index == 0,
              isLast: index == aiActions.length - 1,
            );
          }),
      ],
    );
  }

  Widget _buildExecuteButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_bgDark.withValues(alpha: 0.95), Colors.transparent],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          await _service.resolveAllRooms();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'AI OPTIMIZATION EXECUTED: All anomalies resolved.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                backgroundColor: _neonEmerald,
              ),
            );
          }
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _neonEmerald.withValues(alpha: 0.8),
                  const Color(0xFF065F46).withValues(alpha: 0.9),
                ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _neonEmerald.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                  color: _neonEmerald.withValues(alpha: 0.3), blurRadius: 15),
              const BoxShadow(
                  color: Colors.white30, offset: Offset(0, 1), blurRadius: 0),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('EXECUTE ALL',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ───

class _GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.cubicTo(
      size.width * 0.1,
      size.height * 0.45,
      size.width * 0.2,
      size.height * 0.6,
      size.width * 0.3,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.4,
      size.height * 0.2,
      size.width * 0.6,
      size.height * 0.3,
      size.width,
      size.height * 0.1,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF00F3FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.6)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Fill logic
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00F3FF).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Nodes
    final nodePaint = Paint()..color = Colors.white;
    final nodeGlow = Paint()
      ..color = const Color(0xFF00F3FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Point 1
    canvas.drawCircle(
        Offset(size.width * 0.33, size.height * 0.4), 4, nodeGlow);
    canvas.drawCircle(
        Offset(size.width * 0.33, size.height * 0.4), 3, nodePaint);
    // Point 2
    canvas.drawCircle(
        Offset(size.width * 0.66, size.height * 0.15), 6, nodeGlow);
    canvas.drawCircle(
        Offset(size.width * 0.66, size.height * 0.15), 4, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopoGridPattern extends StatelessWidget {
  final double offset;
  const _TopoGridPattern({required this.offset});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _TopoPainter(offset),
    );
  }
}

class _TopoPainter extends CustomPainter {
  final double offset;
  _TopoPainter(this.offset);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F3FF).withValues(alpha: 0.05)
      ..strokeWidth = 1;

    final dx = offset * 40;
    final dy = offset * 40;

    for (double x = -40 + dx; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -40 + dy; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}

class _TargetPillar extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double progress;
  const _TargetPillar(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color,
      required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            children: [
              Text(value,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  )),
              Text(label.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 9,
                  )),
            ],
          ),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final String title;
  final String subtitle;
  final String stepLabel;
  final String timeLabel;
  final Color nodeColor;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _PathNode({
    required this.title,
    required this.subtitle,
    required this.stepLabel,
    required this.timeLabel,
    required this.nodeColor,
    required this.isActive,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Line and Dot
          SizedBox(
            width: 48,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // The vertical line
                Positioned(
                  top: isFirst ? 24 : 0,
                  bottom: isLast ? 0 : 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: nodeColor.withValues(alpha: 0.2),
                      gradient: isLast
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                nodeColor.withValues(alpha: 0.2),
                                Colors.transparent
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                // The Dot
                Positioned(
                  top: 18,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1116),
                      shape: BoxShape.circle,
                      border: Border.all(color: nodeColor, width: 2),
                      boxShadow: isActive
                          ? [BoxShadow(color: nodeColor, blurRadius: 8)]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right side: Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121922)
                      .withValues(alpha: isActive ? 0.6 : 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stepLabel.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: isActive ? nodeColor : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: GoogleFonts.orbitron(
                            color: Colors.white54,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.3,
                      ),
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
}

// Reuse from map
class _GridPattern extends StatelessWidget {
  final double opacity;
  const _GridPattern({this.opacity = 0.05});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GridPainter(opacity: opacity), size: Size.infinite);
}

class _GridPainter extends CustomPainter {
  final double opacity;
  _GridPainter({required this.opacity});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 100,
                  spreadRadius: size / 2)
            ]),
      );
}

class _RingPainter extends CustomPainter {
  final Color color;
  _RingPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2);
    final paint = Paint()
      ..shader = SweepGradient(colors: [color, color.withValues(alpha: 0.1)])
          .createShader(rect)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
