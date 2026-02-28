// This is the merged file for the wallet screen, including backend logic and redesigned cards

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/eco_service.dart';

import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFB),
        body: StreamBuilder<DocumentSnapshot>(
          stream: EcoService().studentStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data!.data() as Map<String, dynamic>?;
            int points = data?['total_eco_points'] ?? 0;
            String name = data?['name'] ?? 'Student';

            return SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(15, 0, 15, 0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- POINTS HEADER (Integrated Design) ---
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(5, 16, 5, 0),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5CAE60),
                                  Color(
                                      0xFF4B39EF), // Replaced FF Theme Primary
                                  Color(0xFF084209)
                                ],
                                stops: [0, 1, 1],
                                begin: AlignmentDirectional(1, 1),
                                end: AlignmentDirectional(-1, -1),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back,',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xB3FFFFFF),
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(0, 4, 0, 0),
                                            child: Text(
                                              name, // Integrated logic: name variable
                                              style: GoogleFonts.interTight(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          color: Color(0x33FFFFFF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Align(
                                          alignment: AlignmentDirectional(0, 0),
                                          child: Icon(
                                            Icons.eco,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 20, 0, 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$points', // Integrated logic: points variable
                                          style: GoogleFonts.interTight(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.w800,
                                            height: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0, 4, 0, 0),
                                          child: Text(
                                            'Eco-Points',
                                            style: GoogleFonts.interTight(
                                              color: const Color(0xCCFFFFFF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Divider(
                          thickness: 1, color: Color(0xFFC5C5C3), height: 32),

                      // --- PENDING REPORTS SECTION ---
                      const _SectionHeader(title: 'Pending Reports'),
                      const SizedBox(height: 16),
                      const _PendingSection(
                          studentId: kStudentId), // Functional backend widget

                      const Divider(
                          thickness: 1, color: Color(0xFFC5C5C3), height: 32),

                      // --- REWARD TIERS SECTION ---
                      // Tier 1 — Cafeteria Voucher
                      _RewardTile(
                        tier: 1,
                        icon: Icons.local_cafe,
                        title: 'Cafeteria Credit',
                        subtitle: 'RM 5.00 voucher for campus cafe',
                        currentPoints: points,
                        targetPoints: kTier1Points,
                        color: Colors.orange,
                        redeemWidget: points >= kTier1Points
                            ? const _MockBarcode()
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Tier 2 — Certificate
                      _RewardTile(
                        tier: 2,
                        icon: Icons.verified,
                        title: 'Sustainability Certificate',
                        subtitle:
                            'Extracurricular credit — University recognized',
                        currentPoints: points,
                        targetPoints: kTier2Points,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      // Tier 3 — Hostel Rebate
                      _RewardTile(
                        tier: 3,
                        icon: Icons.apartment,
                        title: 'Hostel Fee Rebate',
                        subtitle: 'RM 50.00 off your next semester hostel bill',
                        currentPoints: points,
                        targetPoints: kTier3Points,
                        color: Colors.purple,
                      ),

                      const Divider(
                          thickness: 1, color: Color(0xFFC5C5C3), height: 32),

                      // --- ENVIRONMENTAL IMPACT SECTION ---
                      const _SectionHeader(title: 'Environmental Impact'),
                      const SizedBox(height: 16),
                      _ImpactStats(points: points), // Functional backend widget

                      const Divider(
                          thickness: 1, color: Color(0xFFC5C5C3), height: 32),

                      // --- ACTIVITY LOG SECTION ---
                      const _SectionHeader(title: 'Recent Activity'),
                      const SizedBox(height: 16),
                      const _ActivityLog(
                          studentId: kStudentId), // Functional backend widget
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── REUSABLE UI COMPONENTS FROM WALLET_DESIGN ───────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(5, 0, 5, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.interTight(
              color: const Color(0xFF1A202C),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'View All',
            style: GoogleFonts.inter(
              color: const Color(0xFF4B39EF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REWARD TILE ──────────────────────────────────────────────────────────────
class _RewardTile extends StatelessWidget {
  final int tier;
  final String title, subtitle;
  final IconData icon;
  final int currentPoints, targetPoints;
  final Color color;
  final Widget? redeemWidget;

  const _RewardTile({
    required this.tier,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.currentPoints,
    required this.targetPoints,
    required this.color,
    this.redeemWidget,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = currentPoints < targetPoints;
    final Color mainColor = isLocked ? const Color(0xFF94A3B8) : color;

    final double progress = (currentPoints / targetPoints).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(5, 0, 5, 0),
      child: Material(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: mainColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(title,
                                  style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: mainColor)),
                              if (isLocked) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.lock, color: mainColor, size: 20),
                              ]
                            ],
                          ),
                          Text(subtitle,
                              style: GoogleFonts.inter(
                                  color: mainColor, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$currentPoints / $targetPoints points',
                        style:
                            GoogleFonts.inter(fontSize: 14, color: mainColor)),
                    Text('${(progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, color: mainColor)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockBarcode extends StatelessWidget {
  const _MockBarcode();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Show this at the counter:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black,
              image: const DecorationImage(
                  image: AssetImage(
                      'assets/mock_barcode.png'), // Add a barcode image to assets
                  fit: BoxFit.cover)),
          child: const Center(
              child: Text('ECOSENSE-ECO50',
                  style: TextStyle(color: Colors.white, letterSpacing: 3))),
        ),
        const SizedBox(height: 4),
        const Text('Valid for RM 5.00 at campus cafeteria',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── PENDING SECTION ─────────────────────────────────────────────────────────
// This widget scans all rooms and shows which ones have a report from this student
// that hasn't been resolved yet.
class _PendingSection extends StatelessWidget {
  final String studentId;
  const _PendingSection({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('room_summaries')
          .where('status', isEqualTo: 'needs_review')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        // Filter rooms that have a report from this specific student ID
        var pendingRooms = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          var feedback = data['recent_qualitative_feedback'] as List<dynamic>?;
          return feedback?.any((f) => f['reporter_id'] == studentId) ?? false;
        }).toList();

        if (pendingRooms.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12)),
            child: const Text(
                "No pending reports. Every action you've taken is resolved!",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }

        return Column(
          children: pendingRooms.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var feedbackList =
                data['recent_qualitative_feedback'] as List<dynamic>;
            var feedback =
                feedbackList.firstWhere((f) => f['reporter_id'] == studentId);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading:
                    const Icon(Icons.hourglass_empty, color: Colors.orange),
                title: Text("Room: ${data['room_name'] ?? doc.id}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "Type: ${feedback['type']} | Reward: +${feedback['points_to_award']} pts"),
                trailing: const Text("Pending",
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── IMPACT STATS ────────────────────────────────────────────────────────────
class _ImpactStats extends StatelessWidget {
  final int points;
  const _ImpactStats({required this.points});

  @override
  Widget build(BuildContext context) {
    // Mock calculations
    double co2Saved = points * 0.05; // 0.05kg per point
    double treesPlanted = points / 1000;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: "CO₂ Saved",
          value: "${co2Saved.toStringAsFixed(1)} kg",
          icon: Icons.cloud_done,
          color: Colors.blue,
        ),
        _StatItem(
          label: "Tree Equivalent",
          value: treesPlanted.toStringAsFixed(2),
          icon: Icons.park,
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ─── ACTIVITY LOG ────────────────────────────────────────────────────────────
class _ActivityLog extends StatelessWidget {
  final String studentId;
  const _ActivityLog({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('room_summaries')
          .where('status', isEqualTo: 'stable')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        // This is a simplified logic for the demo activity list
        return const Column(
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("System Optimized", style: TextStyle(fontSize: 14)),
              subtitle: Text("Your report helped save 1.2kWh",
                  style: TextStyle(fontSize: 12)),
              trailing: Text("+50 pts",
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text("Daily Login Bonus", style: TextStyle(fontSize: 14)),
              subtitle: Text("Sustainability Streak: 5 days",
                  style: TextStyle(fontSize: 12)),
              trailing: Text("+5 pts", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
