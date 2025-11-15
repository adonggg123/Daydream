import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationCard(
            icon: Icons.event,
            title: 'Booking Confirmed',
            message: 'Your booking for Poolside Villa has been confirmed',
            time: '2 hours ago',
            color: Colors.green,
          ),
          _buildNotificationCard(
            icon: Icons.local_offer,
            title: 'Special Offer',
            message: 'Get 20% off on your next booking!',
            time: '1 day ago',
            color: Colors.orange,
          ),
          _buildNotificationCard(
            icon: Icons.info,
            title: 'Resort Update',
            message: 'New amenities added to our resort',
            time: '2 days ago',
            color: Colors.blue,
          ),
          _buildNotificationCard(
            icon: Icons.star,
            title: 'Review Request',
            message: 'How was your stay? Share your experience',
            time: '3 days ago',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

