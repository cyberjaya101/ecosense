import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';

class AdminInsightsScreen extends StatelessWidget {
  const AdminInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService service = AdminService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0826),
      body: Stack(
        children: [
          // ── BACKGROUND GLOWS ─────────────────────────────────────────────
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC59DD9).withValues(alpha: 0.05),
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              StreamBuilder<QuerySnapshot>(
                stream: service.roomsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00FF87))),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  double totalWaste = 0;
                  int anomalies = 0;
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalWaste += (data['total_estimated_ringgit_waste'] ?? 0.0)
                        .toDouble();
                    if (data['status_color'] == 'RED' ||
                        data['status_color'] == 'PURPLE') {
                      anomalies++;
                    }
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(24.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTopStats(totalWaste, anomalies),
                        const SizedBox(height: 32),
                        _buildSectionHeader('CAMPUS NEURAL LOAD'),
                        const SizedBox(height: 16),
                        _buildEnergyTrendChart(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('ANOMALY DISTRIBUTION'),
                        const SizedBox(height: 16),
                        _buildDistributionCards(docs),
                        const SizedBox(height: 32),
                        _buildSectionHeader("TOMORROW'S PREDICTION"),
                        const SizedBox(height: 16),
                        _buildPredictiveScheduler(service),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white70, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'NEURAL ANALYTICS',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      pinned: true,
    );
  }

  Widget _buildTopStats(double waste, int anomalies) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TOTAL WASTE',
            value: 'RM ${waste.toStringAsFixed(0)}',
            color: const Color(0xFFef4444),
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'ACTIVE ALERTS',
            value: anomalies.toString(),
            color: const Color(0xFF7A3F91),
            icon: Icons.radar_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: const Color(0xFFC59DD9),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildEnergyTrendChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2B0D3E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: const Color(0xFFC59DD9).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY IMPACT',
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const Icon(Icons.show_chart_rounded,
                  color: Color(0xFF00FF87), size: 18),
            ],
          ),
          const Spacer(),
          // Simple visual representation of a chart
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ChartBar(height: 40, label: 'M'),
              _ChartBar(height: 70, label: 'T'),
              _ChartBar(height: 55, label: 'W'),
              _ChartBar(height: 90, label: 'T', isActive: true),
              _ChartBar(height: 65, label: 'F'),
              _ChartBar(height: 30, label: 'S'),
              _ChartBar(height: 20, label: 'S'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCards(List<QueryDocumentSnapshot> docs) {
    int hotReports = 0;
    int coldReports = 0;
    int ghostReports = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final reports = data['reports'] as Map<String, dynamic>? ?? {};

      hotReports += (reports['TOO_HOT'] ?? 0) as int;
      coldReports += (reports['TOO_COLD'] ?? 0) as int;
      ghostReports += (reports['GHOST_ROOM'] ?? 0) as int;
    }

    return Column(
      children: [
        _DistributionItem(
          label: 'OVER-COOLING ANOMALIES (COLD)',
          count: coldReports,
          color: const Color(0xFF00E5FF),
          icon: Icons.ac_unit_rounded,
        ),
        const SizedBox(height: 12),
        _DistributionItem(
          label: 'SYSTEM FAILURES (HOT)',
          count: hotReports,
          color: const Color(0xFFFE53BB),
          icon: Icons.local_fire_department_rounded,
        ),
        const SizedBox(height: 12),
        _DistributionItem(
          label: 'GHOST ROOM INCIDENTS',
          count: ghostReports,
          color: const Color(0xFF39FF14),
          icon: Icons.visibility_off_outlined,
        ),
      ],
    );
  }

  Widget _buildPredictiveScheduler(AdminService service) {
    return StreamBuilder<DocumentSnapshot>(
      stream: service.dailyPredictionStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF87)));
        }
        if (!snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2B0D3E).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: Text(
                'AI Scheduler offline / No data',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final summary =
            data['prediction_summary'] as String? ?? 'No summary available.';
        final actions = data['actions'] as List<dynamic>? ?? [];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2B0D3E).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: const Color(0xFF00FF87).withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFF00FF87), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI PREDICTIVE INSIGHT',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF87),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                summary,
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (actions.isNotEmpty) ...[
                Text(
                  'PREEMPTIVE ACTIONS',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ...actions.map((act) {
                  final room = act['room'] as String? ?? 'Unknown';
                  final action =
                      act['recommended_action'] as String? ?? 'Investigate';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFF00FF87).withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF00FF87).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room,
                            style: GoogleFonts.inter(
                                color: const Color(0xFF00FF87),
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action,
                            style: GoogleFonts.inter(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B0D3E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double height;
  final String label;
  final bool isActive;

  const _ChartBar(
      {required this.height, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isActive
                  ? [const Color(0xFF00FF87), const Color(0xFF00E5FF)]
                  : [
                      const Color(0xFFC59DD9).withValues(alpha: 0.3),
                      const Color(0xFFC59DD9).withValues(alpha: 0.1)
                    ],
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                        blurRadius: 10)
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DistributionItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _DistributionItem(
      {required this.label,
      required this.count,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B0D3E).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
