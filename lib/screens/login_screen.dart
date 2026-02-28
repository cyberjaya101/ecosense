import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'admin_map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false;
  bool _obscurePassword = true;

  void _handleLogin() {
    final email = _emailController.text.trim();
    if (email.contains('admin') || _isAdmin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminMapScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNav()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111821),
      body: Stack(
        children: [
          // ── BACKGROUND GLOW ──────────────────────────────────────────────
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF87).withValues(alpha: 0.05),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF87).withValues(alpha: 0.1),
                      blurRadius: 120,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── LOGO ──────────────────────────────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D033B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              const Color(0xFF00FF87).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF87).withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: Color(0xFF00FF87), size: 36),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Welcome to',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF2EAF7),
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00FF87), Color(0xFFE0C3FC)],
                    ).createShader(bounds),
                    child: Text(
                      'EcoSense',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Smart environmental monitoring for UM campus.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE0C3FC),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── ROLE TOGGLE ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAdmin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: !_isAdmin
                                    ? const LinearGradient(colors: [
                                        Color(0xFF00FF87),
                                        Color(0xFF00E5FF)
                                      ])
                                    : null,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Student',
                                style: GoogleFonts.inter(
                                  color: !_isAdmin
                                      ? const Color(0xFF1A0826)
                                      : const Color(0xFFF2EAF7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isAdmin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: _isAdmin
                                    ? const LinearGradient(colors: [
                                        Color(0xFF00FF87),
                                        Color(0xFF00E5FF)
                                      ])
                                    : null,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Admin',
                                style: GoogleFonts.inter(
                                  color: _isAdmin
                                      ? const Color(0xFF1A0826)
                                      : const Color(0xFFF2EAF7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── INPUT FIELDS ─────────────────────────────────────────
                  _buildInputField(
                    controller: _emailController,
                    hint: 'Enter your email',
                    icon: Icons.mail_outline_rounded,
                  ),

                  const SizedBox(height: 16),

                  _buildInputField(
                    controller: _passwordController,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscure: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE0C3FC),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── SIGN IN BUTTON ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00FF87), Color(0xFF00E5FF)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF87).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1A0826),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── EXPLORE CAMPUS DATA ──────────────────────────────────
                  Text(
                    'EXPLORE CAMPUS DATA',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF2EAF7).withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildExploreItem(Icons.air_rounded, 'Air Quality'),
                      _buildExploreItem(
                          Icons.graphic_eq_rounded, 'Noise Levels'),
                      _buildExploreItem(Icons.map_rounded, 'Campus Map'),
                    ],
                  ),

                  const SizedBox(height: 48),

                  Text(
                    "Don't have an account?",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF2EAF7).withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),

                  Text(
                    'Request Access',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00FF87),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── POWERED BY GOOGLE ───────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFF2EAF7).withValues(alpha: 0.5),
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_"G"_logo.svg/1200px-Google_"G"_logo.svg.png',
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Powered by Google',
                          style: GoogleFonts.inter(
                            color:
                                const Color(0xFFF2EAF7).withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0826),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFC59DD9).withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(color: const Color(0xFFF2EAF7)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(color: const Color(0xFFB0B0B0), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFC59DD9), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: const Color(0xFFC59DD9).withValues(alpha: 0.8),
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildExploreItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF00FF87).withValues(alpha: 0.3)),
          ),
          child: Icon(icon,
              color: const Color(0xFF00FF87).withValues(alpha: 0.9), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFF2EAF7).withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
