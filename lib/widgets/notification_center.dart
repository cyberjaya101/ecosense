import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/eco_service.dart';

class NotificationCenter extends StatelessWidget {
  final ScrollController scrollController;
  const NotificationCenter({super.key, required this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => NotificationCenter(scrollController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mark all as read when the center is opened
    EcoService().markAllNotificationsAsRead();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B151D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF7A4091).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40)],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NOTIFICATIONS', style: GoogleFonts.interTight(color: const Color(0xFFF2EAF7), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const Icon(Icons.notifications_active, color: Color(0xFF00FF87), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: EcoService().notificationsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)));
                var items = snapshot.data!.docs;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text('No active alerts', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    var data = items[i].data() as Map<String, dynamic>;
                    String type = data['type'] ?? 'INFO';
                    String title = data['title'] ?? 'System Update';
                    String message = data['message'] ?? '';
                    bool isRead = data['isRead'] ?? true;
                    
                    Color color = const Color(0xFF00FF87);
                    IconData icon = Icons.info_outline;

                    if (type == 'POINTS') {
                      color = const Color(0xFF00FF87);
                      icon = Icons.bolt;
                    } else if (type == 'REWARD') {
                      color = const Color(0xFF00E5FF);
                      icon = Icons.redeem;
                    } else if (type == 'ACHIEVEMENT') {
                      color = const Color(0xFFC59DD9);
                      icon = Icons.workspace_premium;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B0D3E).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isRead ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.6)),
                        boxShadow: isRead ? [] : [
                          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 0)
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(title, style: GoogleFonts.interTight(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (!isRead)
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(message, style: GoogleFonts.inter(color: const Color(0xFFC59DD9), fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
