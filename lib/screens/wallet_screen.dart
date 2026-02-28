import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eco_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821), // Midnight background
      body: StreamBuilder<DocumentSnapshot>(
        stream: EcoService().studentStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF87)));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          int points = data?['total_eco_points'] ??
              2450; // Mock current points if missing

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── TOP HEADER ──────────────────────────────────────────
                  _buildTopHeader(points),

                  const SizedBox(height: 48),

                  // ── TIER PROGRESS (CIRCULAR) ─────────────────────────────
                  _buildTierCircle(points),

                  const SizedBox(height: 48),

                  // ── QUICK CLAIMS GRID ────────────────────────────────────
                  _buildSectionHeader('Quick Claims', 'History'),
                  const SizedBox(height: 16),
                  _buildClaimsGrid(points),

                  const SizedBox(height: 48),

                  // ── GRAND PRIZE ──────────────────────────────────────────
                  _buildSectionHeader('Grand Prize', null),
                  const SizedBox(height: 16),
                  _buildGrandPrizeCard(points),

                  const SizedBox(height: 100), // Spacing for floating navbar
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(int points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mission Control',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'REWARDS CENTER',
              style: GoogleFonts.inter(
                color: const Color(0xFFC59DD9).withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded,
                  color: Color(0xFF00FF87), size: 16),
              const SizedBox(width: 8),
              Text(
                '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} pts',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierCircle(int points) {
    const int targetPoints = 3000;
    final double progress = (points / targetPoints).clamp(0.0, 1.0);
    final int remaining = targetPoints - points;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)),
            ),
          ),
          // Glow effect on top of part of the circle
          ShaderMask(
            shaderCallback: (bounds) => const SweepGradient(
              colors: [Color(0xFF00FF87), Color(0xFF00E5FF)],
            ).createShader(bounds),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 0.5),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEXT TIER',
                style: GoogleFonts.inter(
                  color: const Color(0xFFC59DD9).withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silver',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Sustainability Cert',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$remaining pts to unlock',
                style: GoogleFonts.inter(
                  color: const Color(0xFFC59DD9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              title == 'Quick Claims'
                  ? Icons.flash_on_rounded
                  : Icons.diamond_rounded,
              color: title == 'Quick Claims'
                  ? const Color(0xFF00FF87)
                  : const Color(0xFF00E5FF),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (action != null)
          Text(
            action,
            style: GoogleFonts.inter(
              color: const Color(0xFF00E5FF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildClaimsGrid(int points) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.82,
      children: [
        _buildClaimCard(
          icon: Icons.coffee_rounded,
          points: 500,
          title: 'Campus Coffee',
          subtitle: 'Free tall beverage',
          currentPoints: points,
          color: const Color(0xFF00FF87),
        ),
        _buildClaimCard(
          icon: Icons.cookie_rounded,
          points: 350,
          title: 'Healthy Snack',
          subtitle: 'Granola bar or fruit',
          currentPoints: points,
          color: const Color(0xFF7A3F91),
          isLocked: true,
        ),
        _buildClaimCard(
          icon: Icons.print_rounded,
          points: 200,
          title: 'Print Credits',
          subtitle: '\$5 printing quota',
          currentPoints: points,
          color: const Color(0xFF4285F4),
        ),
        _buildClaimCard(
          icon: Icons.directions_bus_rounded,
          points: 800,
          title: 'Shuttle Pass',
          subtitle: 'One week free ride',
          currentPoints: points,
          color: const Color(0xFFEA4335),
          isLocked: true,
        ),
      ],
    );
  }

  Widget _buildClaimCard({
    required IconData icon,
    required int points,
    required String title,
    required String subtitle,
    required int currentPoints,
    required Color color,
    bool isLocked = false,
  }) {
    bool canAfford = currentPoints >= points;
    bool showLocked = isLocked || !canAfford;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$points pts',
                  style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
          const Spacer(),
          Column(
            children: [
              LinearProgressIndicator(
                value: showLocked ? 0.3 : 1.0,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                    showLocked ? Colors.white10 : color),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      showLocked ? Colors.white.withValues(alpha: 0.05) : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  showLocked ? 'LOCKED' : 'REDEEM',
                  style: GoogleFonts.inter(
                    color: showLocked ? Colors.white24 : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrandPrizeCard(int points) {
    const int target = 5000;
    double progress = (points / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.apartment_rounded,
                    color: Color(0xFF00E5FF), size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TIER 3 EXCLUSIVE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.lock_rounded,
                            color: Colors.white24, size: 14),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hostel Fee Rebate',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get 15% off next semester\'s hostel fees for being a top contributor.',
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 5,000 pts',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF00E5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
