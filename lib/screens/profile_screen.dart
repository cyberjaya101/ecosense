import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eco_service.dart';
import '../widgets/notification_center.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821),
      body: Stack(
        children: [
          // Background ambient glows (Nebula Glow V2)
          Positioned(
              bottom: -50,
              left: 50,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF00FF87), blurRadius: 100)
                      ]))),
          Positioned(
              bottom: -100,
              right: 50,
              child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF00E5FF), blurRadius: 80)
                      ]))),

          StreamBuilder<DocumentSnapshot>(
            stream: EcoService().studentStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF87)));
              }

              var data = snapshot.data!.data() as Map<String, dynamic>?;
              int points = data?['total_eco_points'] ?? 2450;
              int reports = data?['reports'] ?? 48;

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: Column(
                    children: [
                      // ── HEADER TOP ROW ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          StreamBuilder<int>(
                            stream:
                                EcoService().unreadNotificationsCountStream(),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none,
                                        color: Color(0xFFF2EAF7)),
                                    onPressed: () =>
                                        _showNotificationCenter(context),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFef4444),
                                            shape: BoxShape.circle),
                                        constraints: const BoxConstraints(
                                            minWidth: 8, minHeight: 8),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.power_settings_new,
                                color: Color(0xFFF2EAF7)),
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── PROFILE AVATAR & INFO ───────────────────────────────
                      _buildProfileInfo(data?['name'] ?? 'Alex Rivera',
                          data?['major'] ?? 'Environmental Science • Year 2'),
                      const SizedBox(height: 32),

                      // ── IMPACT DASHBOARD CARD ───────────────────────────────
                      _buildImpactDashboard(points, reports),
                      const SizedBox(height: 32),

                      // ── RECENT ACTIVITY LIST ────────────────────────────────
                      _buildRecentActivity(),
                      const SizedBox(height: 32),

                      // ── MISSION CONTROL LAUNCHER ────────────────────────────
                      _buildMissionControlCard(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String name, String major) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF87), Color(0xFF00E5FF)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.5),
                        blurRadius: 40)
                  ]),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF111821),
                  ),
                  child: const CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCETj9oKxCs2Incfewh9XBLYbg5o2Sm_jj5tLHUp_1hplcId0LDIOuxv3B5dLVpd5uXUPCeyy-T0BRJ4zAB2ehsegBy2sEl1pivhZ1hwWRnc1bCw4mqKWCAuXRLvBfc6R2OykjAST_7gFJyvKysrAC_lB5dTV3nYM-2W6Vjy1CqIyXCgvZzLhG7U-h7bNZoDg7VpwTkzA-b_2FEkXh1Ba1MSPxIUsHX44FeUVoqkerEIngu8Snvfzt0demZSzZKTOXsJkXhIbZb6og'),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111821),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E5FF)),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                        blurRadius: 15)
                  ],
                ),
                child:
                    const Icon(Icons.edit, color: Color(0xFF00E5FF), size: 16),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(name,
            style: GoogleFonts.interTight(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF2EAF7))),
        const SizedBox(height: 4),
        Text(major,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFF2EAF7))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0826).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3A1F45)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium,
                  color: Color(0xFF00FF87), size: 18),
              const SizedBox(width: 8),
              Text('DIAMOND TIER',
                  style: GoogleFonts.interTight(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FF87),
                      letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactDashboard(int points, int reports) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xCC00FF87), Color(0x801978E5), Color(0xCC00E5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00FF87).withValues(alpha: 0.15),
              blurRadius: 25)
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xEE1A0826),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL IMPACT',
                        style: GoogleFonts.interTight(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFC59DD9),
                            letterSpacing: 1)),
                    Text('Dashboard',
                        style: GoogleFonts.interTight(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF2EAF7))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00FF87).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF00FF87).withValues(alpha: 0.2),
                          blurRadius: 15)
                    ],
                  ),
                  child: const Icon(Icons.bolt, color: Color(0xFF00FF87)),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL POINTS',
                            style: GoogleFonts.interTight(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC59DD9),
                                letterSpacing: 1)),
                        Text(
                            points.toString().replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]},'),
                            style: GoogleFonts.interTight(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1B2B2B),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up,
                                  color: Color(0xFF00FF87), size: 12),
                              const SizedBox(width: 4),
                              Text('+15% this week',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00FF87))),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('REPORTS',
                            style: GoogleFonts.interTight(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC59DD9),
                                letterSpacing: 1)),
                        Text('$reports',
                            style: GoogleFonts.interTight(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF00FF87),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('${reports - 3} Approved',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFC59DD9))),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity',
                style: GoogleFonts.interTight(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF2EAF7))),
            Row(
              children: [
                Text('SHOW ALL',
                    style: GoogleFonts.interTight(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC59DD9))),
                const Icon(Icons.chevron_right,
                    color: Color(0xFFC59DD9), size: 16),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x991A0826),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                  'Reported \'Too Cold\'',
                  'Dewan Kuliah 1 (DK1)',
                  '+50',
                  '2h ago',
                  Icons.ac_unit,
                  Colors.blue),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              _buildActivityItem('Ghost Room Report', 'Library Zone B', '+150',
                  'Yesterday', Icons.sensor_occupied, Colors.purple),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              _buildActivityItem('Reported \'Too Hot\'', 'Cafeteria', '+50',
                  '2 days ago', Icons.local_fire_department, Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String points,
      String time, IconData icon, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.shade500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: color.shade500.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color.shade400, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.interTight(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF2EAF7))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: const Color(0xFFC59DD9))),
                ],
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(points,
                  style: GoogleFonts.interTight(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FF87))),
              const SizedBox(height: 2),
              Text(time,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFC59DD9).withValues(alpha: 0.7))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMissionControlCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Show the new Rewards pop-up widget
        _showRewardsWidget(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xB31E1228), Color(0xCC2A1B36)]),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFC59DD9).withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                          blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.redeem,
                      color: Color(0xFF00FF87), size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enter Mission Control',
                        style: GoogleFonts.interTight(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('3 active rewards available',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFC59DD9))),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFF00E5FF)),
            )
          ],
        ),
      ),
    );
  }

  // ─── NOTIFICATION CENTER (MODAL BOTTOM SHEET) ──────────────────────────────
  void _showNotificationCenter(BuildContext context) {
    NotificationCenter.show(context);
  }

  // ─── REWARDS POPUP (MISSION CONTROL) ──────────────────────────────────────
  void _showRewardsWidget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) =>
            _RewardsPopupContent(scrollController: controller),
      ),
    );
  }
}

// ─── NEW REWARDS POPUP WIDGET EXTRACED FROM HTML ─────────────────────────────
class _RewardsPopupContent extends StatelessWidget {
  final ScrollController scrollController;

  const _RewardsPopupContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B151D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7A4091).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, -5))
        ],
      ),
      child: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7A4091).withValues(alpha: 0.15),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF7A4091), blurRadius: 100)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF00E5FF), blurRadius: 80)
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Pop-up drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: EcoService().studentStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00FF87)));
                      }
                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                      int points = data?['total_eco_points'] ?? 2450;

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                        children: [
                          // 1. Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mission Control',
                                      style: GoogleFonts.interTight(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF2EAF7))),
                                  Text('REWARDS CENTER',
                                      style: GoogleFonts.interTight(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFC59DD9),
                                          letterSpacing: 1.5)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt,
                                        color: Color(0xFF00FF87), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} pts',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 13)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 2. Circular Target Status (Royal Amethyst)
                          _buildCircularStatus(),
                          const SizedBox(height: 32),

                          // 3. Quick Claims
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flash_on,
                                      color: Color(0xFF00FF87)),
                                  const SizedBox(width: 8),
                                  Text('Quick Claims',
                                      style: GoogleFonts.interTight(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF2EAF7))),
                                ],
                              ),
                              Text('View All',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF00E5FF))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: [
                              _buildClaimCard(
                                  Icons.print,
                                  'Free Printing Quota',
                                  '\$2 print balance',
                                  150,
                                  points,
                                  const Color(0xFF00FF87)),
                              _buildClaimCard(
                                  Icons.local_cafe,
                                  'Campus Cafe',
                                  'Free beverage',
                                  300,
                                  points,
                                  const Color(0xFF00E5FF)),
                              _buildClaimCard(
                                  Icons.shopping_bag,
                                  'Bookstore Discount',
                                  '15% off merch',
                                  500,
                                  points,
                                  const Color(0xFFC59DD9)),
                              _buildClaimCard(
                                  Icons.inventory,
                                  'Exam Care Package',
                                  'Snacks & stationery',
                                  750,
                                  points,
                                  const Color(0xFFC59DD9)),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 4. Grand Prize
                          Row(
                            children: [
                              const Icon(Icons.diamond,
                                  color: Color(0xFF00E5FF)),
                              const SizedBox(width: 8),
                              Text('Grand Prize',
                                  style: GoogleFonts.interTight(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF2EAF7))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildGrandPrize(points),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularStatus() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: CircularProgressIndicator(
              value: 0.49, // 49%
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00FF87)), // Ideally gradient
            ),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0x1A00FF87), Color(0x1A00E5FF)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                    blurRadius: 40)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('GLOBAL STATUS',
                    style: GoogleFonts.interTight(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC59DD9),
                        letterSpacing: 1.5)),
                Text('Royal',
                    style: GoogleFonts.interTight(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Amethyst Rank',
                      style: GoogleFonts.interTight(
                          fontSize: 10, color: const Color(0xFF00E5FF))),
                ),
                Text('Progress to Grand Prize',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC59DD9).withValues(alpha: 0.8))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildClaimCard(IconData icon, String title, String subtitle,
      int itemPts, int currentPoints, Color accentColor) {
    bool canAfford = currentPoints >= itemPts;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x991A0826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1), // Match design
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 10)
                    ],
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A4091).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF7A4091).withValues(alpha: 0.3)),
                  ),
                  child: Text('$itemPts pts',
                      style: GoogleFonts.interTight(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )
              ],
            ),
            const Spacer(),
            Text(title,
                style: GoogleFonts.interTight(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 10, color: const Color(0xFFC59DD9))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: canAfford
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: canAfford
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              alignment: Alignment.center,
              child: Text(
                canAfford ? 'REDEEM' : 'LOCKED',
                style: GoogleFonts.interTight(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: canAfford
                        ? const Color(0xFF1B151D)
                        : const Color(0xFFC59DD9)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGrandPrize(int points) {
    double progress = (points / 5000).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              blurRadius: 30)
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0x991B151D),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1B151D), Color(0xFF2D1F33)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          blurRadius: 20)
                    ],
                  ),
                  child: const Icon(Icons.apartment,
                      color: Color(0xFF00E5FF), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PREMIUM TIER GOAL',
                              style: GoogleFonts.interTight(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00E5FF),
                                  letterSpacing: 1.5)),
                          const Icon(Icons.lock,
                              color: Color(0xFF00E5FF), size: 14),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Hostel Fee Rebate',
                          style: GoogleFonts.interTight(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          'Unlock a significant credit toward your next semester\'s residence fees.',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: const Color(0xFFC59DD9))),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mission Progress',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC59DD9))),
                Text(
                    '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 5,000 pts',
                    style: GoogleFonts.interTight(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF))),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black45,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
