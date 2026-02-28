import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
// Keep in case needed directly
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EcoSenseApp());
}

class EcoSenseApp extends StatelessWidget {
  const EcoSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A3F91),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    const ProfileScreen(), // Maps to the new Nebula Glow V2 design
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0826),
      body: Stack(
        children: [
          _screens[_currentIndex == 1 ? 1 : 0], // Map 0 to Home, 1 to Profile

          // ── FLOATING CUSTOM NAVBAR ─────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 32,
            right: 32,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2B0D3E).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                    color: const Color(0xFFC59DD9).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavBarItem(
                    icon: Icons.home_filled,
                    label: 'Home',
                    isActive: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _buildScanFAB(),
                  _NavBarItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isActive: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFAB() {
    return GestureDetector(
      onTap: () {
        // This triggers the QR scanner on the Home screen
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          // Wait for the tab to switch before calling the method
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _homeKey.currentState?.switchToQR();
          });
        } else {
          _homeKey.currentState?.switchToQR();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF87), Color(0xFF00E5FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF87).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_rounded,
            color: Color(0xFF1A0826), size: 30),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF00FF87) : const Color(0xFFC59DD9);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF00FF87),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
