import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eco_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EcoService _service = EcoService();
  String _selectedRoom = kRooms[0]; // Default: DK1
  bool _useQR = false; // Toggle between Dropdown (Manual) vs QR
  bool _hasReported = false; // Tracks if student already sent a report
  String? _reportedRoomId; // Which room they reported (to listen to)
  String? _selectedIssue; // Added for Submit button

  // ── 1. QR SIMULATION MODE
  // Shows a mock scanner overlay and then "detects" the Lounge.
  void _switchToQR() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MockScannerOverlay(),
    );

    // Simulate scanning time (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context); // Close scanner
      setState(() {
        _selectedRoom = "Lounge"; // Hardcoded for demo success
        _useQR = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('QR Code Detected: Lounge'),
        ),
      );
    }
  }

  // ── 2. SUBMIT REPORT
  Future<void> _submitReport(String type) async {
    int points = _useQR ? kPointsQR : kPointsManual;
    if (type == 'GHOST_ROOM') {
      points = kPointsGhost;
      await _triggerGhostFlow();
      return;
    }

    await _service.submitReport(
      roomId: _selectedRoom,
      type: type,
      pointsToAward: points,
    );

    setState(() {
      _hasReported = true;
      _reportedRoomId = _selectedRoom;
    });

    _showConfirmation(points);
  }

  // ── 3. GHOST ROOM AI VISION FLOW
  Future<void> _triggerGhostFlow() async {
    // Show "Gemini Vision Scanning" Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Gemini Vision'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing photo for human presence...',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3)); // Simulate AI
    if (mounted) Navigator.pop(context);

    await _service.submitReport(
      roomId: _selectedRoom,
      type: 'GHOST_ROOM',
      pointsToAward: kPointsGhost,
    );

    setState(() {
      _hasReported = true;
      _reportedRoomId = _selectedRoom;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Gemini Vision: Verified Empty! +150 Points Pending.'),
        ),
      );
    }
  }

  // ── 4. CONFIRMATION SNACKBAR
  void _showConfirmation(int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Report sent! +$points points pending Admin approval.'),
      ),
    );
  }

  // ── 5. ADMIN RESOLUTION LISTENER
  // When the Admin approves the report, this triggers the "Points Earned!" popup.
  Widget _buildResolutionListener() {
    if (!_hasReported || _reportedRoomId == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: _service.roomStream(_reportedRoomId!),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        var data = snap.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        if (data['status'] == 'resolved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showPointsEarnedDialog();
              setState(() => _hasReported = false); // Reset to avoid loop
            }
          });
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showPointsEarnedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2833), // Darker dialog
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
            child: Text('Admin Verified!',
                style: GoogleFonts.interTight(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified,
                color: Color(0xFF00FF87), size: 80), // Neon green action color
            const SizedBox(height: 16),
            Text(
              'Your report was confirmed and resolved!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00FF87).withValues(alpha: 0.3)),
              ),
              child: Text('+ Eco-Points Added!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.interTight(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FF87),
                      fontSize: 16)),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF87),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Awesome!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
              top: -100,
              right: -100,
              child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF9333EA), blurRadius: 100)
                      ]))),
          Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00FF87).withValues(alpha: 0.05),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF00FF87), blurRadius: 80)
                      ]))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [
                                Color(0xFF1978E5),
                                Color(0xFF00E5FF)
                              ]),
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCETj9oKxCs2Incfewh9XBLYbg5o2Sm_jj5tLHUp_1hplcId0LDIOuxv3B5dLVpd5uXUPCeyy-T0BRJ4zAB2ehsegBy2sEl1pivhZ1hwWRnc1bCw4mqKWCAuXRLvBfc6R2OykjAST_7gFJyvKysrAC_lB5dTV3nYM-2W6Vjy1CqIyXCgvZzLhG7U-h7bNZoDg7VpwTkzA-b_2FEkXh1Ba1MSPxIUsHX44FeUVoqkerEIngu8Snvfzt0demZSzZKTOXsJkXhIbZb6og'),
                              backgroundColor: Color(0xFF111821),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ECOSENSE',
                                  style: GoogleFonts.interTight(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFC59DD9),
                                      letterSpacing: 1)),
                              Text('Good morning, Alex',
                                  style: GoogleFonts.interTight(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF2EAF7))),
                            ],
                          )
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.notifications_none,
                                  color: Color(0xFFF2EAF7)),
                              onPressed: () {}),
                          IconButton(
                              icon: const Icon(Icons.power_settings_new,
                                  color: Color(0xFFC59DD9)),
                              onPressed: () {}),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Room Selector Dropdown
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B0D3E).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFFC59DD9).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoom,
                        dropdownColor: const Color(0xFF2B0D3E),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFF00E5FF)),
                        isExpanded: true,
                        style: GoogleFonts.inter(
                            color: const Color(0xFFF2EAF7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                        items: kRooms
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Color(0xFFC59DD9), size: 20),
                                    const SizedBox(width: 12),
                                    Text(r),
                                  ],
                                )))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedRoom = v!;
                          _useQR = false;
                          _selectedIssue = null;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Eco-Status Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0x660F172A), Color(0x331978E5)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Eco-Status: Optimal',
                                      style: GoogleFonts.interTight(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF2EAF7))),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.greenAccent,
                                            blurRadius: 10)
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '$_selectedRoom is currently energy efficient.',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFC59DD9))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child:
                              const Icon(Icons.eco, color: Colors.greenAccent),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. QR Scanner Box
                  GestureDetector(
                    onTap: _switchToQR,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2833).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _useQR
                                ? const Color(0xFF00FF87)
                                : const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.5),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF00E5FF)
                                  .withValues(alpha: 0.1),
                              blurRadius: 20)
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1978E5)
                                      .withValues(alpha: 0.1),
                                  border: Border.all(
                                      color: const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Icon(
                                    _useQR
                                        ? Icons.verified
                                        : Icons.qr_code_scanner,
                                    color: _useQR
                                        ? const Color(0xFF00FF87)
                                        : const Color(0xFF00E5FF),
                                    size: 36),
                              ),
                              const SizedBox(width: 24),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      _useQR ? 'Room Verified' : 'Scan Room QR',
                                      style: GoogleFonts.interTight(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF2EAF7))),
                                  const SizedBox(height: 4),
                                  Text(
                                      _useQR
                                          ? '+$kPointsQR pts unlocked'
                                          : 'Point camera to sync data',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFFC59DD9))),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Quick Report Header
                  Text('Quick Report',
                      style: GoogleFonts.interTight(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF2EAF7))),
                  const SizedBox(height: 16),

                  // 6. Report Options
                  _buildIssueCard(
                    type: 'TOO_COLD',
                    title: 'Too Cold',
                    subtitle: 'Request heating adjustment',
                    icon: Icons.ac_unit,
                    baseColor: Colors.blue.shade400,
                    accentColor: Colors.blue,
                  ),
                  _buildIssueCard(
                    type: 'TOO_HOT',
                    title: 'Too Hot',
                    subtitle: 'Request cooling adjustment',
                    icon: Icons.local_fire_department,
                    baseColor: Colors.orange.shade400,
                    accentColor: Colors.orange,
                  ),
                  _buildIssueCard(
                    type: 'GHOST_ROOM',
                    title: 'Ghost Room',
                    subtitle: 'Report empty room with lights on',
                    icon: Icons.sensor_occupied,
                    baseColor: Colors.purple.shade400,
                    accentColor: Colors.purple,
                    bonusPoints: '+150 pts',
                    requiresQR: true,
                  ),

                  const SizedBox(height: 24),

                  // 7. Submit Button (Brushed Emerald)
                  GestureDetector(
                    onTap: _selectedIssue != null
                        ? () => _submitReport(_selectedIssue!)
                        : null,
                    child: Opacity(
                      opacity: _selectedIssue != null ? 1.0 : 0.5,
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0D3623), Color(0xFF00281C)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF00FF9D)
                                  .withValues(alpha: 0.2)),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0xFF00FF87),
                                blurRadius: 20,
                                offset: Offset(0, 0),
                                spreadRadius: -10),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SUBMIT REPORT',
                              style: GoogleFonts.interTight(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.auto_awesome,
                                color: Color(0xFF00FF87)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Invisible listener
          _buildResolutionListener(),
        ],
      ),
    );
  }

  // ─── HELPER: ISSUE CARD ────────────────────────────────────────────────────
  Widget _buildIssueCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color baseColor,
    required Color accentColor,
    String? bonusPoints,
    bool requiresQR = false,
  }) {
    bool isSelected = _selectedIssue == type;
    bool isDisabled = requiresQR && !_useQR;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: GestureDetector(
          onTap:
              isDisabled ? null : () => setState(() => _selectedIssue = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF352242)
                  : const Color(0xFF2A1B36).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                    color: isSelected ? accentColor : baseColor, width: 4),
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 20)
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: isSelected ? Colors.white : accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(title,
                            style: GoogleFonts.interTight(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF2EAF7))),
                        if (bonusPoints != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0x3300FF87),
                                Color(0x3300E5FF)
                              ]),
                              border:
                                  Border.all(color: const Color(0x4D00E5FF)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(bonusPoints,
                                style: GoogleFonts.interTight(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00E5FF))),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFFC59DD9))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFC59DD9).withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── REPORT BUTTON WIDGET ────────────────────────────────────────────────────
// Teammate: You can restyle this any way you want.

// NOT NEEDED ANYMORE
// _ReportButton removed.

// ─── MOCK SCANNER OVERLAY ────────────────────────────────────────────────────
// This creates a "viewfinder" effect for the demo.
class _MockScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. "Camera" Background
          Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white24, size: 100),
            ),
          ),
          // 2. Viewfinder Frame
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          // 3. Scanning Line Animation
          const _ScanningLine(),
          // 4. Text
          const Positioned(
            bottom: 100,
            child: Text(
              "Align QR Code with Frame",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();

  @override
  _ScanningLineState createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 300 + (_controller.value * 250),
          child: Container(
            width: 250,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.green,
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}
