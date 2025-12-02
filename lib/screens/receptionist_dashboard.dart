import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/guest_request_service.dart';
import '../services/notification_service.dart';
import '../services/role_based_access_control.dart';
import '../models/user.dart';
import '../models/room.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  final UserService _userService = UserService();
  final BookingService _bookingService = BookingService();
  final GuestRequestService _guestRequestService = GuestRequestService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUserProfile();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_currentUser == null || !_currentUser!.isReceptionist) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(title: const Text('Access Denied'), centerTitle: true),
        body: const Center(child: Text('You do not have permission to access this page.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          _buildSidebar(theme),
          Expanded(child: Column(children: [ _buildTopBar(theme), Expanded(child: _buildContent()) ])),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: theme.colorScheme.primary, child: Text(_currentUser?.displayName?.substring(0,1).toUpperCase() ?? 'R', style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 12),
                Expanded(child: Text(_currentUser?.displayName ?? 'Receptionist', style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const Divider(),
          ListView(
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            children: [
              _buildNavTile(icon: Icons.dashboard, label: 'Bookings', index: 0),
              _buildNavTile(icon: Icons.support_agent, label: 'Guest Requests', index: 1),
              _buildNavTile(icon: Icons.receipt, label: 'Receipts', index: 2),
              _buildNavTile(icon: Icons.notifications, label: 'Notifications', index: 3),
              const SizedBox(height: 12),
              _buildNavTile(icon: Icons.logout, label: 'Sign Out', index: 99, isLogout: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({required IconData icon, required String label, required int index, bool isLogout = false}) {
    final bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700]),
      title: Text(label, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[800])),
      onTap: () async {
        if (isLogout) {
          await _authService.signOut();
          if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          return;
        }
        setState(() { _selectedIndex = index; });
      },
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(children: [ Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const Spacer(), ]),
    );
  }

  String _getTitle() {
    return switch (_selectedIndex) {
      0 => 'Bookings',
      1 => 'Guest Requests',
      2 => 'Receipts',
      3 => 'Notifications',
      _ => 'Receptionist'
    };
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildBookingsView();
      case 1: return _buildGuestRequestsView();
      case 2: return _buildReceiptsView();
      case 3: return _buildNotificationsView();
      default: return _buildBookingsView();
    }
  }

  Widget _buildBookingsView() {
    return _buildBookingsList();
  }

  Widget _buildBookingsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final docs = snapshot.data!.docs;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final b = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(b['roomName'] ?? 'Unknown'),
                subtitle: Text('Guest: ${b['guestName'] ?? 'N/A'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (RoleBasedAccessControl.userHasPermission(_currentUser!, Permission.assignRoom))
                      IconButton(
                        icon: const Icon(Icons.meeting_room),
                        onPressed: () async {
                          final rooms = await _bookingService.getAllRoomsForAdmin();
                          final chosen = await showDialog<Room?>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: const Text('Assign Room'),
                              children: rooms.map((room) {
                                return SimpleDialogOption(
                                  child: Text('${room.name} - \$${room.price.toStringAsFixed(2)}'),
                                  onPressed: () => Navigator.pop(context, room),
                                );
                              }).toList(),
                            ),
                          );
                            if (chosen != null && _currentUser != null) {
                            await _bookingService.assignRoomToBooking(
                              bookingId: docs[index].id,
                              roomId: chosen.id,
                              roomName: chosen.name,
                              callerUserId: _currentUser!.id,
                            );
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room assigned')));
                            setState(() {});
                          }
                        },
                      ),
                    if (RoleBasedAccessControl.userHasPermission(_currentUser!, Permission.generateReceipt))
                      IconButton(icon: const Icon(Icons.receipt), onPressed: () async {
                        final receipt = await _bookingService.generateReceiptForBooking(docs[index].id, callerUserId: _currentUser!.id);
                        if (receipt != null && mounted) {
                          showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Receipt'), content: SelectableText(receipt.toString()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
                        }
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGuestRequestsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _guestRequestService.streamAllRequests(callerUserId: _currentUser!.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = items[index];
              return ListTile(
                title: Text(r['subject'] ?? 'Untitled'),
                subtitle: Text(r['description'] ?? ''),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.check), onPressed: () async { await _guestRequestService.updateGuestRequest(requestId: r['id'], callerUserId: _currentUser!.id, status: 'resolved'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated'))); }),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReceiptsView() {
    return const Center(child: Text('Receipts - to be implemented'));
  }

  Widget _buildNotificationsView() {
    final TextEditingController _recipientIdController = TextEditingController();
    final TextEditingController _notifTitleController = TextEditingController();
    final TextEditingController _notifMessageController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Send Notification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _recipientIdController, decoration: const InputDecoration(labelText: 'Recipient User ID')),
          const SizedBox(height: 8),
          TextField(controller: _notifTitleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: _notifMessageController, decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              if (_currentUser == null) return;
              try {
                await _notificationService.sendUserNotification(
                  callerUserId: _currentUser!.id,
                  userId: _recipientIdController.text.trim(),
                  title: _notifTitleController.text.trim(),
                  message: _notifMessageController.text.trim(),
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send notification: $e')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
