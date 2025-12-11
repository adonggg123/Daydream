import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../services/audit_trail_service.dart';
import '../models/user.dart';
// ignore: unused_import
import '../models/room.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../models/admin_notification.dart';
import '../services/auth_service.dart';
import '../services/role_based_access_control.dart';
import '../services/guest_request_service.dart';
import '../services/event_booking_service.dart';
import '../models/event_booking.dart';
import '../models/booking.dart';
import '../widgets/room_image_widget.dart';
import '../widgets/profile_image_widget.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuditTrailService _auditTrail = AuditTrailService();
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final GuestRequestService _guestRequestService = GuestRequestService();
  final AuthService _authService = AuthService();
  final EventBookingService _eventBookingService = EventBookingService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppUser? _currentUser;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showBookingOnly = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get user initial for fallback
  // Always shows 'A' for admin users
  String _getUserInitial(AppUser? user) {
    if (user == null) return 'A';
    
    // Always return 'A' for admin users
    if (user.role == UserRole.admin) {
      return 'A';
    }
    
    // For non-admin users, use display name or email
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName![0].toUpperCase();
    }
    if (user.email.isNotEmpty) {
      return user.email[0].toUpperCase();
    }
    
    // Default to 'A'
    return 'A';
  }

  Future<void> _loadCurrentUser() async {
    try {
    final user = await _userService.getCurrentUserProfile();
    setState(() {
      _currentUser = user;
    });
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.grey.shade300),
        ),
      );
    }
    
    if (!_currentUser!.isStaffOrAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0E6F8), Color(0xFFF0F3FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: Color(0xFF5A67D8),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You need administrator privileges\nto access this dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          
          if (isMobile) {
            return Column(
              children: [
                _buildTopBar(theme, isMobile: true),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                  child: _buildContent(),
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                _buildSidebar(theme),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(theme),
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                        child: _buildContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      drawer: MediaQuery.of(context).size.width < 768 ? _buildMobileDrawer(theme) : null,
      bottomNavigationBar: MediaQuery.of(context).size.width < 768 ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(4, 0),
          ),
        ],
        border: Border(
          right: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Column(
                  children: [
                    Container(
                  width: 100,
                  height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Transform.scale(
                        scale: 2.8, // Increased scale to better match white circle size
                        child: Image.asset(
                          'assets/icons/LOGO2.png',
                          width: 500,   // Base size (can be any)
                          height: 500,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                        'Admin Panel',
                        style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                Text(
                  'Dashboard v2.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildNavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Users',
                  index: 1,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38B2AC), Color(0xFF319795)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.king_bed_rounded,
                  label: 'Rooms',
                  index: 2,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFED8936), Color(0xFFDD6B20)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Room Bookings',
                  index: 3,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9F7AEA), Color(0xFF805AD5)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.event_rounded,
                  label: 'Event Bookings',
                  index: 4,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF687B3), Color(0xFFED64A6)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Guest Requests',
                  index: 5,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.history_toggle_off_rounded,
                  label: 'Audit Trail',
                  index: 6,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF718096), Color(0xFF4A5568)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'System',
                  index: 7,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FD1C5), Color(0xFF38B2AC)],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.shade200,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Material(
                    color: const Color(0xFFFED7D7).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF56565).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: const Color(0xFFF56565),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: const Color(0xFFF56565),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Gradient gradient,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() => _selectedIndex = index);
            _animationController.reset();
            _animationController.forward();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected ? gradient : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? null : Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(ThemeData theme) {
    return Drawer(
      width: 280,
      elevation: 0,
      backgroundColor: Colors.white,
      child: _buildSidebar(theme),
    );
  }

  Widget _buildBottomNavigationBar() {
    // Define all navigation items
    final allNavItems = [
      _NavItemData(icon: Icons.dashboard_rounded, label: 'Dashboard', index: 0),
      _NavItemData(icon: Icons.people_alt_rounded, label: 'Users', index: 1),
      _NavItemData(icon: Icons.king_bed_rounded, label: 'Rooms', index: 2),
      _NavItemData(icon: Icons.calendar_today_rounded, label: 'Bookings', index: 3),
      _NavItemData(icon: Icons.event_rounded, label: 'Events', index: 4),
      _NavItemData(icon: Icons.support_agent_rounded, label: 'Requests', index: 5),
      _NavItemData(icon: Icons.history_toggle_off_rounded, label: 'Audit', index: 6),
      _NavItemData(icon: Icons.settings_rounded, label: 'System', index: 7),
    ];

    // Show first 4 items in bottom nav, rest in "More"
    final visibleItems = allNavItems.take(4).toList();
    final moreItems = allNavItems.skip(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 65, maxHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
        children: [
              ...visibleItems.map((item) => _buildBottomNavItem(item)),
              if (moreItems.isNotEmpty)
                _buildMoreButton(moreItems), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(_NavItemData item) {
    final isSelected = _selectedIndex == item.index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = item.index;
            _animationController.reset();
            _animationController.forward();
          });
        },
                      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                color: isSelected ? const Color(0xFF5A67D8) : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 1),
              Flexible(
                        child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF5A67D8) : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                      ),
                    ),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton(List<_NavItemData> moreItems) {
    final hasSelectedInMore = moreItems.any((item) => item.index == _selectedIndex);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _showMoreMenuDialog(moreItems),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                      children: [
                  Icon(
                    Icons.more_horiz_rounded,
                    color: hasSelectedInMore ? const Color(0xFF5A67D8) : Colors.grey.shade600,
                    size: 20,
                  ),
                  if (hasSelectedInMore)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A67D8),
                          shape: BoxShape.circle,
                        ),
                      ),
                        ),
                      ],
                    ),
              const SizedBox(height: 1),
              Flexible(
                child: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: hasSelectedInMore ? FontWeight.w600 : FontWeight.normal,
                    color: hasSelectedInMore ? const Color(0xFF5A67D8) : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenuDialog(List<_NavItemData> moreItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              ...moreItems.map((item) {
                final isSelected = _selectedIndex == item.index;
                return ListTile(
                      leading: Container(
                    padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5A67D8).withOpacity(0.1)
                          : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                      item.icon,
                      color: isSelected ? const Color(0xFF5A67D8) : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF5A67D8) : Colors.grey.shade900,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF5A67D8))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedIndex = item.index;
                      _animationController.reset();
                      _animationController.forward();
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard Overview';
      case 1: return 'User Management';
      case 2: return 'Room Management';
      case 3: return 'Room Bookings';
      case 4: return 'Event Bookings';
      case 5: return 'Guest Requests';
      case 6: return 'Audit Trail';
      case 7: return 'System Settings';
      default: return 'Admin Panel';
    }
  }

  Widget _buildTopBar(ThemeData theme, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 16 : 24,
      ),
                            decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
          Row(
            children: [
              if (isMobile)
                                IconButton(
                  icon: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Transform.scale(
                      scale: 2.5,
                      child: Image.asset(
                        'assets/icons/LOGO2.png',
                        width: 500,
                        height: 500,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StreamBuilder<List<AdminNotification>>(
                stream: _notificationService.getAdminNotifications(),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  final unreadCount = notifications.where((n) => !n.isRead).length;
                      
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF56565).withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ProfileImageWidget(
                    imageUrl: _currentUser?.photoUrl,
                    size: 44,
                    fallbackText: _getUserInitial(_currentUser),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              if (!isMobile) const SizedBox(width: 12),
              if (!isMobile)
                SizedBox(
                  width: 150,
                  child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                        _currentUser?.displayName ?? 'Admin User',
                            style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _currentUser?.email ?? 'admin@example.com',
                                style: TextStyle(
                                  fontSize: 12,
                          color: Colors.grey.shade500,
                                ),
                        overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                                                ),
                                            ],
                                          ),
          if (!isMobile) const SizedBox(height: 8),
          if (!isMobile)
            Text(
              '${_currentUser?.displayName ?? 'Admin'} • ${_formatDateTime(DateTime.now())}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
        ],
                                          ),
                                        );
                                      }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardTab();
      case 1: return _buildUsersTab();
      case 2: return _buildRoomsTab();
      case 3: return _buildRoomBookingsTab();
      case 4: return _buildEventBookingsTab();
      case 5: return _buildGuestRequestsTab();
      case 6: return _buildAuditTrailTab();
      case 7: return _buildSystemTab();
      default: return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _buildStatsGrid(isMobile: isMobile),
                    SizedBox(height: isMobile ? 24 : 32),
                    if (isMobile)
                      Column(
                        children: [
                          _buildRecentBookings(isMobile: true),
                          const SizedBox(height: 20),
                          _buildAdminNotificationsCard(isMobile: true),
                          const SizedBox(height: 20),
                          _buildQuickActions(isMobile: true),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildRecentBookings(isMobile: false),
                                const SizedBox(height: 24),
                                _buildAdminNotificationsCard(isMobile: false),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildQuickActions(isMobile: false),
                          ),
                      ],
                    ),
                  ],
                ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildStatsGrid({bool isMobile = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: isMobile ? 160 : 150,
            child: Center(child: CircularProgressIndicator(color: Colors.grey.shade300)),
          );
        }

        final bookings = snapshot.data!.docs;
        final totalBookings = bookings.length;
        final confirmedBookings = bookings.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'confirmed';
        }).length;
        final pendingBookings = bookings.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending';
        }).length;
        
        double totalRevenue = 0;
        for (var doc in bookings) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'confirmed' || data['status'] == 'pending') {
            final total = data['total'];
            if (total is num) {
              totalRevenue += total.toDouble();
            }
          }
        }

        final stats = [
          _StatItem(
                      title: 'Total Bookings',
                      value: totalBookings.toString(),
                      icon: Icons.book_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
                    ),
                  ),
          _StatItem(
                      title: 'Confirmed',
                      value: confirmedBookings.toString(),
                      icon: Icons.check_circle_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF38B2AC), Color(0xFF319795)],
            ),
          ),
          _StatItem(
                      title: 'Pending',
                      value: pendingBookings.toString(),
                      icon: Icons.pending_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFED8936), Color(0xFFDD6B20)],
                    ),
                  ),
          _StatItem(
                      title: 'Total Revenue',
            value: '₱${totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.attach_money_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF9F7AEA), Color(0xFF805AD5)],
            ),
          ),
        ];

        if (isMobile) {
          return Column(
          children: [
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(stats[0], isMobile: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(stats[1], isMobile: true)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(stats[2], isMobile: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(stats[3], isMobile: true)),
                  ],
              ),
            ),
          ],
          );
        }

        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stats.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.22,
                child: _buildStatCard(stats[index], isMobile: false),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(_StatItem item, {bool isMobile = false}) {
    return Container(
      height: isMobile ? 160 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: item.gradient,
        boxShadow: [
          BoxShadow(
            color: item.gradient.colors.first.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.icon == Icons.attach_money_rounded
                  ? Text(
                      '₱',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(item.icon, color: Colors.white, size: 22),
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                  Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings({bool isMobile = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                  ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                  'Recent Bookings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'Latest 8',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('timestamp', descending: true)
                .limit(8)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(color: Colors.grey)),
                );
              }

              final bookings = snapshot.data!.docs;
              if (bookings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = bookings[index].data() as Map<String, dynamic>;
                  final total = booking['total'];
                  final status = (booking['status'] ?? 'Unknown') as String;
                  final statusColor = status == 'confirmed'
                      ? const Color(0xFF38B2AC)
                      : status == 'pending'
                          ? const Color(0xFFED8936)
                          : Colors.grey.shade600;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.2)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.hotel_rounded,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['roomName'] ?? 'Unknown Room',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      booking['guestName'] ?? 'Guest',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                            ],
                        ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₱${(total is num ? total.toDouble() : 0.0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                                      ],
                                    ),
                                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAdminNotificationsCard({bool isMobile = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9F7AEA), Color(0xFF805AD5)],
                  ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Recent Notifications',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<List<AdminNotification>>(
            stream: _notificationService.getAdminNotifications(limit: 5),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(color: Colors.grey)),
                );
              }

              final notifications = snapshot.data!;
              if (notifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                      Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                        Text(
                        'All caught up!',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final accent = Theme.of(context).colorScheme.primary;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withOpacity(0.1), accent.withOpacity(0.2)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getNotificationIcon(n.type),
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(n.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActions({bool isMobile = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFED8936), Color(0xFFDD6B20)],
                  ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                  'Quick Actions',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                _buildQuickActionButton(
                  icon: Icons.room_rounded,
                  label: 'Initialize Rooms',
                  description: 'Refresh sample room data',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                  ),
                  onTap: _initializeRooms,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),
                _buildQuickActionButton(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Cleanup Logs',
                  description: 'Remove old audit logs',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38B2AC), Color(0xFF319795)],
                  ),
                  onTap: _cleanupAuditLogs,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                        color: Colors.black87,
                    ),
                      overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                        fontSize: 13,
                    ),
                      overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomBookingsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                'Room Bookings',
            style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
                  letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
                'Manage and review all room reservations',
            style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
            children: [
                    Icon(Icons.filter_list_rounded, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Filter bookings by status or date',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A67D8).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
              ),
            ],
          ),
                      child: const Row(
                      children: [
                          Icon(Icons.download_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                        Text(
                            'Export',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
            ),
          ),
        ],
      ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.grey));
                  final bookings = snapshot.data!.docs;
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = bookings[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final bookingId = doc.id;
                      final status = BookingStatus.values.firstWhere(
                        (s) => s.name == data['status'],
                        orElse: () => BookingStatus.pending,
                      );
                      final isPending = status == BookingStatus.pending;
                      
    return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
          ),
        ],
      ),
                        child: Column(
        children: [
                            Row(
                              children: [
                                Container(
                                  width: isMobile ? 48 : 60,
                                  height: isMobile ? 48 : 60,
                                  decoration: BoxDecoration(
                                    gradient: status == BookingStatus.confirmed
                                        ? const LinearGradient(colors: [Color(0xFF38B2AC), Color(0xFF319795)])
                                        : status == BookingStatus.rejected
                                            ? const LinearGradient(colors: [Color(0xFFF56565), Color(0xFFE53E3E)])
                                            : const LinearGradient(colors: [Color(0xFFED8936), Color(0xFFDD6B20)]),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                    child: Icon(
                                    status == BookingStatus.confirmed
                                        ? Icons.check_circle
                                        : status == BookingStatus.rejected
                                            ? Icons.cancel
                                            : Icons.pending,
                                    color: Colors.white,
                                    size: isMobile ? 22 : 28,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                      Text(
                                        data['roomName'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: isMobile ? 15 : 17,
                                          color: const Color(0xFF1F2937),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                Row(
                  children: [
                                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                                              'Guest: ${data['userId'] ?? 'N/A'}',
                        style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: isMobile ? 13 : 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 6),
                                          Expanded(
                      child: Text(
                                              '${data['checkIn'] ?? ''} to ${data['checkOut'] ?? ''}',
                        style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: isMobile ? 13 : 14,
                        ),
                                              overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: status == BookingStatus.confirmed
                                            ? const Color(0xFF38B2AC).withOpacity(0.1)
                                            : status == BookingStatus.rejected
                                                ? const Color(0xFFF56565).withOpacity(0.1)
                                                : const Color(0xFFED8936).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.name.toUpperCase(),
                      style: TextStyle(
                                          color: status == BookingStatus.confirmed
                                              ? const Color(0xFF38B2AC)
                                              : status == BookingStatus.rejected
                                                  ? const Color(0xFFF56565)
                                                  : const Color(0xFFED8936),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (isMobile) const SizedBox(height: 12),
                                    if (isPending)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF48BB78).withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                ),
              ],
            ),
                                            child: IconButton(
                                              icon: Icon(Icons.check, color: Colors.white, size: isMobile ? 18 : 20),
                                              tooltip: 'Accept',
                onPressed: () async {
                                                if (_currentUser == null) return;
                                                try {
                                                  await _bookingService.acceptBooking(
                                                    bookingId: bookingId,
                                                    callerUserId: _currentUser!.id,
                                                    checkConflicts: true,
                                                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                                                        content: const Text('Booking accepted'),
                        backgroundColor: Colors.green,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Error'),
                                                        content: Text(e.toString()),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                          ),
                                                          if (e.toString().contains('Conflict'))
                                                            TextButton(
                                                              onPressed: () async {
                                                                Navigator.pop(context);
                                                                try {
                                                                  await _bookingService.acceptBooking(
                                                                    bookingId: bookingId,
                                                                    callerUserId: _currentUser!.id,
                                                                    checkConflicts: false,
                                                                  );
                                                                  if (mounted) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text('Booking accepted (conflicts ignored)'),
                                                                        backgroundColor: Colors.orange,
                                                                      ),
                                                                    );
                                                                  }
                                                                } catch (e2) {
                                                                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                                                                        content: Text('Error: ${e2.toString()}'),
                        backgroundColor: Colors.red,
                                                                      ),
                                                                    );
                                                                  }
                                                                }
                                                              },
                                                              child: const Text('Accept Anyway'),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFF56565).withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
          ),
        ],
      ),
                                            child: IconButton(
                                              icon: Icon(Icons.close, color: Colors.white, size: isMobile ? 18 : 20),
                                              tooltip: 'Reject',
                                              onPressed: () async {
                                                if (_currentUser == null) return;
                                                final reason = await showDialog<String>(
      context: context,
                                                  builder: (context) {
                                                    final controller = TextEditingController();
                                                    return AlertDialog(
                                                      title: const Text('Reject Booking'),
                                                      content: TextField(
                                                        controller: controller,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Reason (optional)',
                                                          hintText: 'Enter rejection reason...',
                                                          border: OutlineInputBorder(),
                                                        ),
                                                        maxLines: 3,
                                                      ),
        actions: [
          TextButton(
                                                          onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
                                                          onPressed: () => Navigator.pop(context, controller.text),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFFF56565),
                                                          ),
                                                          child: const Text('Reject'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                try {
                                                  await _bookingService.rejectBooking(
                                                    bookingId: bookingId,
                                                    callerUserId: _currentUser!.id,
                                                    reason: reason,
                                                  );
                if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                                                        content: Text('Booking rejected'),
                                                        backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                                                        content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
          ),
        ],
      ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Room Management',
                        style: TextStyle(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                            letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                        Text(
                          'Manage hotel rooms and availability',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                        Container(
                          decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A67D8).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showCreateRoomDialog(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.add, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add Room',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                Container(
                                    width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A67D8).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showCreateRoomDialog(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Add Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              StreamBuilder<List<Room>>(
                stream: _bookingService.streamAllRoomsForAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint('Error loading rooms: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading rooms',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Try to initialize rooms if they don't exist
                                _initializeRooms();
                              },
                              child: const Text('Initialize Rooms'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
                  }

                  final rooms = snapshot.data ?? [];

                  if (rooms.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                        children: [
                            Icon(Icons.room_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No rooms found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Room" to create your first room',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await _initializeRooms();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Rooms initialized. Please refresh.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Initialize Sample Rooms'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A67D8),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _buildRoomCard(room, isMobile: isMobile);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(Room room, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Image - Box Shape (Smaller) - Before name and description
              SizedBox(
                width: isMobile ? 120 : 150,
                height: isMobile ? 120 : 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: room.imageUrl.isNotEmpty
                      ? RoomImageWidget(
                          imageUrl: room.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: room.isAvailable
                                  ? const LinearGradient(colors: [Color(0xFF38B2AC), Color(0xFF319795)])
                                  : const LinearGradient(colors: [Color(0xFF718096), Color(0xFF4A5568)]),
                            ),
                            child: Icon(
                              Icons.room_rounded,
                              size: isMobile ? 40 : 50,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          placeholder: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              gradient: room.isAvailable
                                  ? const LinearGradient(colors: [Color(0xFF38B2AC), Color(0xFF319795)])
                                  : const LinearGradient(colors: [Color(0xFF718096), Color(0xFF4A5568)]),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: room.isAvailable
                                ? const LinearGradient(colors: [Color(0xFF38B2AC), Color(0xFF319795)])
                                : const LinearGradient(colors: [Color(0xFF718096), Color(0xFF4A5568)]),
                          ),
                          child: Icon(
                            Icons.room_rounded,
                            size: isMobile ? 40 : 50,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
                          Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 16 : 18,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (_currentUser == null) return;
                            try {
                              await _bookingService.updateRoomAvailability(
                                roomId: room.id,
                                isAvailable: !room.isAvailable,
                                userId: _currentUser!.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      room.isAvailable
                                          ? 'Room marked as unavailable'
                                          : 'Room marked as available',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: room.isAvailable
                                  ? const Color(0xFF38B2AC).withOpacity(0.1)
                                  : const Color(0xFF718096).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: room.isAvailable
                                    ? const Color(0xFF38B2AC)
                                    : const Color(0xFF718096),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  room.isAvailable ? 'Available' : 'Not Available',
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: room.isAvailable
                                        ? const Color(0xFF38B2AC)
                                        : const Color(0xFF718096),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  room.isAvailable ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: room.isAvailable
                                      ? const Color(0xFF38B2AC)
                                      : const Color(0xFF718096),
                          ),
                        ],
                      ),
                          ),
                        ),
                    ],
                  ),
                    const SizedBox(height: 4),
                    Text(
                      room.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
                Row(
                  children: [
              Text(
                '₱',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '₱${room.price.toStringAsFixed(2)}/night',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              if (!isMobile) ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        try {
                          _showEditRoomDialog(room);
                        } catch (e) {
                          debugPrint('Error showing edit dialog: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                    ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDeleteRoomDialog(room),
                            borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          try {
                            _showEditRoomDialog(room);
                                } catch (e) {
                            debugPrint('Error showing edit dialog: $e');
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDeleteRoomDialog(room),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                              const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                ),
              ],
            ),
          ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventBookingsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event Bookings',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage event reservations and bookings',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('event_bookings')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
                  }
                  final eventBookings = snapshot.data!.docs;
                  
                  if (eventBookings.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.event_available_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No event bookings yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: eventBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = eventBookings[index] as DocumentSnapshot<Map<String, dynamic>>;
                      
                      // Safely parse event booking with error handling
                      EventBooking booking;
                      try {
                        booking = EventBooking.fromSnapshot(doc);
                  } catch (e) {
                        debugPrint('Error parsing event booking ${doc.id}: $e');
                        // Return a placeholder card for invalid bookings
                        return Container(
                          padding: EdgeInsets.all(isMobile ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.grey.shade400),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Invalid booking data (ID: ${doc.id})',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
      ),
    );
  }

                      final eventDate = booking.eventDate;
                      final peopleCount = booking.peopleCount;
                      final userEmail = booking.userEmail;
                      // ignore: unused_local_variable
                      final notes = booking.notes;
                      final eventType = booking.eventType;
                      final status = booking.status;
                      final isPending = status == EventBookingStatus.pending;

                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
              ),
              child: Column(
                children: [
                            Row(
                              children: [
                  Container(
                                  width: isMobile ? 48 : 60,
                                  height: isMobile ? 48 : 60,
                    decoration: BoxDecoration(
                                    gradient: status == EventBookingStatus.confirmed
                                        ? const LinearGradient(colors: [Color(0xFF38B2AC), Color(0xFF319795)])
                                        : status == EventBookingStatus.rejected
                                            ? const LinearGradient(colors: [Color(0xFFF56565), Color(0xFFE53E3E)])
                                            : const LinearGradient(colors: [Color(0xFF9F7AEA), Color(0xFF805AD5)]),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    status == EventBookingStatus.confirmed
                                        ? Icons.check_circle
                                        : status == EventBookingStatus.rejected
                                            ? Icons.cancel
                                            : Icons.event_rounded,
                                    color: Colors.white,
                                    size: isMobile ? 22 : 28,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 12 : 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                      Text(
                                        Booking.getEventTypeDisplay(eventType),
                            style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: isMobile ? 15 : 17,
                                          color: const Color(0xFF1F2937),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  userEmail,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: isMobile ? 13 : 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                        ),
                      ],
                    ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    eventDate.toLocal().toString().substring(0, 10),
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: isMobile ? 13 : 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                                                  Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                                                  const SizedBox(width: 6),
                      Text(
                                                    '$peopleCount people',
                        style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: isMobile ? 13 : 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                        Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                                        color: status == EventBookingStatus.confirmed
                                            ? const Color(0xFF38B2AC).withOpacity(0.1)
                                            : status == EventBookingStatus.rejected
                                                ? const Color(0xFFF56565).withOpacity(0.1)
                                                : const Color(0xFF9F7AEA).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.name.toUpperCase(),
                                        style: TextStyle(
                                          color: status == EventBookingStatus.confirmed
                                              ? const Color(0xFF38B2AC)
                                              : status == EventBookingStatus.rejected
                                                  ? const Color(0xFFF56565)
                                                  : const Color(0xFF9F7AEA),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                  ),
                          ),
                        ),
                                    if (isMobile) const SizedBox(height: 12),
                                    if (isPending)
                      Row(
                                        mainAxisSize: MainAxisSize.min,
                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF48BB78).withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.check, color: Colors.white, size: isMobile ? 18 : 20),
                                              tooltip: 'Accept',
                              onPressed: () async {
                                                if (_currentUser == null) return;
                                                try {
                                                  await _eventBookingService.acceptEventBooking(
                                                    bookingId: booking.id,
                                                    callerUserId: _currentUser!.id,
                                                    checkConflicts: true,
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Event booking accepted'),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                  }
                                } catch (e) {
                                                  if (mounted) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Error'),
                                                        content: Text(e.toString()),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('OK'),
                                                          ),
                                                          if (e.toString().contains('Conflict'))
                                                            TextButton(
                                                              onPressed: () async {
                                                                Navigator.pop(context);
                                                                try {
                                                                  await _eventBookingService.acceptEventBooking(
                                                                    bookingId: booking.id,
                                                                    callerUserId: _currentUser!.id,
                                                                    checkConflicts: false,
                                                                  );
                                                                  if (mounted) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text('Event booking accepted (conflicts ignored)'),
                                                                        backgroundColor: Colors.orange,
                                                                      ),
                                                                    );
                                                                  }
                                                                } catch (e2) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                                                        content: Text('Error: ${e2.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                                                              child: const Text('Accept Anyway'),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFF56565).withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.close, color: Colors.white, size: isMobile ? 18 : 20),
                                              tooltip: 'Reject',
                              onPressed: () async {
                                                if (_currentUser == null) return;
                                                final reason = await showDialog<String>(
                                                  context: context,
                                                  builder: (context) {
                                                    final controller = TextEditingController();
                                                    return AlertDialog(
                                                      title: const Text('Reject Event Booking'),
                                                      content: TextField(
                                                        controller: controller,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Reason (optional)',
                                                          hintText: 'Enter rejection reason...',
                                                          border: OutlineInputBorder(),
                                                        ),
                                                        maxLines: 3,
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.pop(context, controller.text),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFFF56565),
                                                          ),
                                                          child: const Text('Reject'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                                try {
                                                  await _eventBookingService.rejectEventBooking(
                                                    bookingId: booking.id,
                                                    callerUserId: _currentUser!.id,
                                                    reason: reason,
                                                  );
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Event booking rejected'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                                  ],
                                ),
                              ],
                        ),
                    ],
                  ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestRequestsTab() {
    if (_currentUser == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guest Requests',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage and resolve guest service requests',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _guestRequestService.streamAllRequests(callerUserId: _currentUser!.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.support_agent_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                            Text(
                              'No guest requests',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final requests = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                  children: [
                            Container(
                              width: isMobile ? 48 : 60,
                              height: isMobile ? 48 : 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                            ),
                            SizedBox(width: isMobile ? 12 : 20),
                    Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['subject'] ?? 'Untitled',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: isMobile ? 15 : 17,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    r['description'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: isMobile ? 13 : 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                            ),
                            if (RoleBasedAccessControl.userHasPermission(_currentUser!, Permission.manageGuestRequests))
                              Row(
                                mainAxisSize: MainAxisSize.min,
                  children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF48BB78).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                ),
                        ],
                      ),
                                    child: IconButton(
                                      icon: Icon(Icons.check, color: Colors.white, size: isMobile ? 18 : 20),
                                      onPressed: () async {
                                        await _guestRequestService.updateGuestRequest(
                                          requestId: r['id'],
                                          callerUserId: _currentUser!.id,
                                          status: 'resolved',
                                        );
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Guest request updated'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5A67D8).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.person_add, color: Colors.white, size: isMobile ? 18 : 20),
                          onPressed: () async {
                                        await _guestRequestService.updateGuestRequest(
                                          requestId: r['id'],
                                          callerUserId: _currentUser!.id,
                                          assignedToUserId: _currentUser!.id,
                                          status: 'assigned',
                                        );
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                            content: Text('Assigned to you'),
                                            backgroundColor: Colors.blue,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                  ),
                ],
              ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage user accounts and permissions',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
          Container(
                width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                  color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                    Icon(Icons.people_alt_rounded, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                StreamBuilder<List<AppUser>>(
                  stream: _userService.getAllUsers(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.length : 0;
                    return Text(
                      'Showing $count users',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                            fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
              StreamBuilder<List<AppUser>>(
              stream: _userService.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
                }

                final users = snapshot.data!;

                return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final user = users[index];
                      return _buildUserCard(user, isMobile: isMobile);
                  },
                );
              },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildUserCard(AppUser user, {bool isMobile = false}) {
    final roleColor = user.isAdmin
      ? const Color(0xFF9F7AEA)
      : user.isReceptionist
        ? const Color(0xFF38B2AC)
        : user.isStaff
          ? const Color(0xFFED8936)
          : Colors.grey.shade600;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
      onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(20),
      child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
                width: isMobile ? 48 : 60,
                height: isMobile ? 48 : 60,
            decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [roleColor.withOpacity(0.2), roleColor.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
            ),
            child: ProfileImageWidget(
              imageUrl: user.photoUrl,
              size: isMobile ? 48 : 60,
              fallbackText: user.displayName?.isNotEmpty == true
                  ? user.displayName![0]
                  : user.email.isNotEmpty
                      ? user.email[0]
                      : 'U',
              backgroundColor: Colors.transparent,
              errorWidget: Center(
                child: Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName![0].toUpperCase()
                      : user.email[0].toUpperCase(),
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 20 : 24,
                  ),
                ),
              ),
            ),
          ),
              SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? user.email.split('@')[0],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 15 : 17,
                              color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton(
                          icon: Icon(Icons.more_vert_rounded, size: isMobile ? 20 : 22, color: Colors.grey.shade600),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Change Role'),
                            onTap: () => Future.delayed(
                              const Duration(milliseconds: 100),
                              () => _showRoleChangeDialog(user),
                            ),
                          ),
                          PopupMenuItem(
                            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                            onTap: () => _toggleUserActive(user),
                          ),
                        ],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ],
                  ),
                    SizedBox(height: isMobile ? 6 : 8),
                  Row(
                    children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                        SizedBox(width: isMobile ? 4 : 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                              fontSize: isMobile ? 13 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                    SizedBox(height: isMobile ? 6 : 8),
                  Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: (user.isActive ? const Color(0xFF38B2AC) : const Color(0xFFF56565)).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                              color: user.isActive ? const Color(0xFF38B2AC) : const Color(0xFFF56565),
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                    SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    'Joined ${_formatDateTime(user.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                        fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditTrailTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'Audit Trail',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track system activities and changes',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
          Container(
                width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, color: Colors.grey),
                    const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                      () {
                        final String prefix = _showBookingOnly
                            ? 'Showing booking logs'
                            : 'Showing audit logs';

                        if (_startDate == null && _endDate == null) {
                          return _showBookingOnly
                              ? 'Showing last 100 booking logs'
                              : 'Showing last 100 audit logs';
                        } else if (_startDate != null && _endDate == null) {
                          return '$prefix from ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
                        } else if (_startDate == null && _endDate != null) {
                          return '$prefix up to ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
                        } else {
                          return '$prefix from ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} '
                              'to ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
                        }
                      }(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    if (_startDate != null || _endDate != null)
                      TextButton.icon(
                        onPressed: _clearDateFilter,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700], 
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      (_startDate == null || _endDate == null)
                          ? 'Select date range'
                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            ' → '
                            '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    avatar: const Icon(Icons.book_rounded, size: 18),
                    label: const Text('Bookings only'),
                    selected: _showBookingOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showBookingOnly = selected;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
              StreamBuilder<List<AuditLog>>(
              stream: _auditTrail.getAuditLogs(
                startDate: _startDate,
                endDate: _endDate != null
                    ? DateTime(
                        _endDate!.year,
                        _endDate!.month,
                        _endDate!.day + 1,
                      )
                    : null,
                limit: _startDate == null && _endDate == null ? 100 : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load audit logs',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.grey));
                }

                var logs = snapshot.data!;
                if (_showBookingOnly) {
                  logs = logs
                      .where((log) => log.resourceType == 'booking')
                      .toList();
                }

                if (logs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                      'No audit logs found for the selected filters.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                    ),
                  );
                }

                return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                      return _buildAuditLogCard(log, isMobile: isMobile);
                  },
                );
              },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildAuditLogCard(AuditLog log, {bool isMobile = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 48 : 60,
            height: isMobile ? 48 : 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF718096), Color(0xFF4A5568)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getActionIcon(log.action),
              color: Colors.white,
              size: isMobile ? 22 : 28,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActionLabel(log.action),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 15 : 17,
                    color: const Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    SizedBox(width: isMobile ? 4 : 6),
                    Expanded(
                      child: Text(
                      log.userEmail,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                          fontSize: isMobile ? 13 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 20),
                    Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade500),
                    SizedBox(width: isMobile ? 4 : 6),
                    Text(
                      log.resourceType,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 4 : 6),
                Text(
                  _formatDateTime(log.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'System Management',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
                Text(
                'System tools and maintenance',
                  style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                    color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSystemCard(
                    icon: Icons.room_rounded,
                    title: 'Initialize Rooms',
                    description: 'Create or refresh all sample room data in the system',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                      ),
                    onTap: _initializeRooms,
                      isMobile: isMobile,
                  );
                } else {
                  return _buildSystemCard(
                      icon: Icons.cleaning_services_rounded,
                    title: 'Cleanup Audit Logs',
                    description: 'Delete audit records older than 90 days to optimize performance',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38B2AC), Color(0xFF319795)],
                      ),
                    onTap: _cleanupAuditLogs,
                      isMobile: isMobile,
                  );
                }
              },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildSystemCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(20),
      child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
                width: isMobile ? 48 : 60,
                height: isMobile ? 48 : 60,
              decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                  color: Colors.white,
                  size: isMobile ? 22 : 28,
              ),
            ),
              SizedBox(width: isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 15 : 17,
                        color: const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                        fontSize: isMobile ? 13 : 14,
                      height: 1.5,
                    ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialStart = _startDate ?? now.subtract(const Duration(days: 7));
    final DateTime initialEnd = _endDate ?? now.add(const Duration(days: 7));

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date range',
      saveText: 'Apply',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  IconData _getActionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.userLogin:
      case AuditAction.userLogout:
      case AuditAction.userRegister:
        return Icons.login_rounded;
      case AuditAction.bookingCreated:
      case AuditAction.bookingUpdated:
      case AuditAction.bookingCancelled:
        return Icons.book_rounded;
      case AuditAction.roomCreated:
      case AuditAction.roomUpdated:
      case AuditAction.roomDeleted:
        return Icons.room_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  IconData _getNotificationIcon(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.bookingCreated:
        return Icons.hotel_rounded;
      case AdminNotificationType.eventBookingCreated:
        return Icons.event_available_rounded;
      case AdminNotificationType.bookingUpdated:
        return Icons.edit_calendar_rounded;
      case AdminNotificationType.bookingCancelled:
        return Icons.event_busy_rounded;
      case AdminNotificationType.paymentProcessed:
        return Icons.payment_rounded;
      case AdminNotificationType.system:
        return Icons.notifications_rounded;
    }
  }

  String _getActionLabel(AuditAction action) {
    return action.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showRoleChangeDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Change User Role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
                    title: Text(
                      role.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              value: role,
              groupValue: user.role,
              onChanged: (value) {
                if (value != null) {
                  _userService.updateUserRole(user.id, value, callerUserId: _currentUser?.id);
                        // Log audit trail - silently handle permission errors
                  _auditTrail.logAction(
                    userId: _currentUser!.id,
                    userEmail: _currentUser!.email,
                    userRole: _currentUser!.role,
                    action: AuditAction.userRoleChanged,
                    resourceType: 'user',
                    resourceId: user.id,
                    details: {
                      'oldRole': user.role.name,
                      'newRole': value.name,
                    },
                        ).catchError((e) {
                          // Silently handle permission errors
                          debugPrint('Audit trail logging failed (permission issue): $e');
                        });
                  Navigator.pop(context);
                }
              },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    tileColor: Colors.grey.shade50,
            );
          }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleUserActive(AppUser user) {
    _userService.updateUserActiveStatus(user.id, !user.isActive);
    // Log audit trail - silently handle permission errors
    _auditTrail.logAction(
      userId: _currentUser!.id,
      userEmail: _currentUser!.email,
      userRole: _currentUser!.role,
      action: user.isActive ? AuditAction.userDeactivated : AuditAction.userActivated,
      resourceType: 'user',
      resourceId: user.id,
    ).catchError((e) {
      // Silently handle permission errors
      debugPrint('Audit trail logging failed (permission issue): $e');
    });
  }

  void _showUserDetails(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ProfileImageWidget(
                  imageUrl: user.photoUrl,
                  size: 80,
                  fallbackText: user.displayName?.isNotEmpty == true
                      ? user.displayName![0]
                      : user.email.isNotEmpty
                          ? user.email[0]
                          : 'U',
                  backgroundColor: Colors.transparent,
                  errorWidget: Center(
                    child: Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName![0].toUpperCase()
                          : user.email[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user.displayName ?? user.email.split('@')[0],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
          children: [
            _buildDetailRow('Role', user.role.name.toUpperCase()),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Created', _formatDateTime(user.createdAt)),
            if (user.lastLoginAt != null)
              _buildDetailRow('Last Login', _formatDateTime(user.lastLoginAt!)),
          ],
        ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
            onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeRooms() async {
    try {
      await _bookingService.forceInitializeRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rooms initialized successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _cleanupAuditLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      await _auditTrail.deleteOldLogs(cutoffDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Old audit logs cleaned up'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF56565).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFF56565),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
            onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF56565).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    }
  }

  void _showCreateRoomDialog() {
    if (_currentUser == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final capacityController = TextEditingController(text: '2');
    final imageUrlController = TextEditingController();
    final amenitiesController = TextEditingController();
    bool isAvailable = true;
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Create New Room',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Room Image Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Room Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Selected Image Preview
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: selectedImage != null
                                  ? (kIsWeb || 
                                      selectedImage!.path.startsWith('blob:') || 
                                      selectedImage!.path.startsWith('http://') || 
                                      selectedImage!.path.startsWith('https://')
                                      ? Image.network(
                                          selectedImage!.path,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('Network image error: $error');
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('File image error: $error');
                                            debugPrint('File path: ${selectedImage!.path}');
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            );
                                          },
                                        ))
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.room_rounded, size: 40),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          try {
                                            final ImagePicker picker = ImagePicker();
                                            final XFile? image = await picker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 85,
                                            );
                                            if (image != null) {
                                              try {
                                                // Handle web/desktop blob URLs and regular file paths
                                                if (kIsWeb || image.path.startsWith('blob:') || image.path.startsWith('http://') || image.path.startsWith('https://')) {
                                                  // For web/desktop with blob URLs, create a File object with the URL path
                                                  setDialogState(() {
                                                    selectedImage = File(image.path);
                                                  });
                                                } else {
                                                  // For mobile/desktop with file paths, try to use the file
                                                  try {
                                                    final file = File(image.path);
                                                    // Use the file directly - don't check existence as it may fail on desktop
                                                    setDialogState(() {
                                                      selectedImage = file;
                                                    });
                                                  } catch (e) {
                                                    // If file creation fails, still try to use the path
                                                    debugPrint('File creation failed, using path anyway: $e');
                                                    setDialogState(() {
                                                      selectedImage = File(image.path);
                                                    });
                                                  }
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error accessing image: ${e.toString()}'),
                                                      backgroundColor: Colors.red,
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error picking image: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.upload_rounded, size: 18),
                                  label: const Text('Upload Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5A67D8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                if (selectedImage != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const Text(
                                  'Or enter image URL below',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Image URL (optional)',
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    enabled: selectedImage == null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Price per Night *',
                            prefixText: '₱',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: capacityController,
                          decoration: InputDecoration(
                            labelText: 'Capacity *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amenitiesController,
                    decoration: InputDecoration(
                      labelText: 'Amenities (comma-separated)',
                      hintText: 'WiFi, TV, AC, Pool',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Available',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) {
                          setDialogState(() => isAvailable = value);
                        },
                        activeColor: const Color(0xFF38B2AC),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (nameController.text.isEmpty ||
                                    descriptionController.text.isEmpty ||
                                    priceController.text.isEmpty ||
                                    capacityController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill in all required fields'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isUploading = true;
                                });

                                try {
                                  String? finalImageUrl;

                                  final amenities = amenitiesController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();

                                  // Create room first (with URL if provided, or empty for now)
                                  if (selectedImage == null && imageUrlController.text.isNotEmpty) {
                                    finalImageUrl = imageUrlController.text;
                                  }

                                  final roomId = await _bookingService.createRoom(
                                    name: nameController.text,
                                    description: descriptionController.text,
                                    price: double.tryParse(priceController.text) ?? 0.0,
                                    capacity: int.tryParse(capacityController.text) ?? 2,
                                    amenities: amenities,
                                    imageUrl: finalImageUrl ?? '',
                                    isAvailable: isAvailable,
                                    userId: _currentUser!.id,
                                  );

                                  // Upload image if a new image was selected (after room creation so we have the room ID)
                                  if (selectedImage != null) {
                                    try {
                                      finalImageUrl = await _bookingService.uploadRoomImage(
                                        selectedImage!,
                                        roomId,
                                      );
                                      // Update the room with the uploaded image URL
                                      await _bookingService.updateRoom(
                                        roomId: roomId,
                                        name: nameController.text,
                                        description: descriptionController.text,
                                        price: double.tryParse(priceController.text) ?? 0.0,
                                        capacity: int.tryParse(capacityController.text) ?? 2,
                                        amenities: amenities,
                                        imageUrl: finalImageUrl,
                                        isAvailable: isAvailable,
                                        userId: _currentUser!.id,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        setDialogState(() {
                                          isUploading = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Room created but image upload failed: ${e.toString()}'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                      return;
                                    }
                                  }

                                  if (context.mounted) {
                                    setDialogState(() {
                                      isUploading = false;
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Room created successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setDialogState(() {
                                      isUploading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A67D8),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Create Room'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    if (_currentUser == null) return;

    final nameController = TextEditingController(text: room.name);
    final descriptionController = TextEditingController(text: room.description);
    final priceController = TextEditingController(text: room.price.toStringAsFixed(2));
    final capacityController = TextEditingController(text: room.capacity.toString());
    final imageUrlController = TextEditingController(text: room.imageUrl);
    final amenitiesController = TextEditingController(text: room.amenities.join(', '));
    bool isAvailable = room.isAvailable;
    File? selectedImage;
    bool isUploading = false;
    bool clearImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit Room: ${room.name}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Room Image Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Room Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Current/Selected Image Preview
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: selectedImage != null
                                  ? (kIsWeb || selectedImage!.path.startsWith('blob:')
                                      ? Image.network(
                                          selectedImage!.path,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            );
                                          },
                                        ))
                                  : (room.imageUrl.isNotEmpty
                                      ? RoomImageWidget(
                                          imageUrl: room.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: Container(
                                            color: Colors.grey.shade200,
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image_not_supported, size: 40),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.room_rounded, size: 40),
                                        )),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: isUploading
                                      ? null
                                      : () async {
                                          try {
                                            final ImagePicker picker = ImagePicker();
                                            final XFile? image = await picker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 85,
                                            );
                                            if (image != null) {
                                              try {
                                                // Handle web/desktop blob URLs and regular file paths
                                                if (kIsWeb || image.path.startsWith('blob:') || image.path.startsWith('http://') || image.path.startsWith('https://')) {
                                                  // For web/desktop with blob URLs, create a File object with the URL path
                                                  setDialogState(() {
                                                    selectedImage = File(image.path);
                                                  });
                                                } else {
                                                  // For mobile/desktop with file paths, try to use the file
                                                  try {
                                                    final file = File(image.path);
                                                    // Use the file directly - don't check existence as it may fail on desktop
                                                    setDialogState(() {
                                                      selectedImage = file;
                                                    });
                                                  } catch (e) {
                                                    // If file creation fails, still try to use the path
                                                    debugPrint('File creation failed, using path anyway: $e');
                                                    setDialogState(() {
                                                      selectedImage = File(image.path);
                                                    });
                                                  }
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error accessing image: ${e.toString()}'),
                                                      backgroundColor: Colors.red,
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error picking image: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: const Icon(Icons.upload_rounded, size: 18),
                                  label: const Text('Upload Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5A67D8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                if (selectedImage != null || room.imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (selectedImage != null)
                                        TextButton.icon(
                                          onPressed: () {
                                            setDialogState(() {
                                              selectedImage = null;
                                            });
                                          },
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('Remove New Image'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      if (room.imageUrl.isNotEmpty && selectedImage == null)
                                        TextButton.icon(
                                          onPressed: () {
                                            setDialogState(() {
                                              imageUrlController.text = '';
                                              clearImage = true;
                                            });
                                          },
                                          icon: const Icon(Icons.delete_outline, size: 16),
                                          label: const Text('Clear Current Image'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const Text(
                                  'Or enter image URL below',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Image URL (optional)',
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    enabled: selectedImage == null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Price per Night *',
                            prefixText: '₱',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: capacityController,
                          decoration: InputDecoration(
                            labelText: 'Capacity *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amenitiesController,
                    decoration: InputDecoration(
                      labelText: 'Amenities (comma-separated)',
                      hintText: 'WiFi, TV, AC, Pool',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Available',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) {
                          setDialogState(() => isAvailable = value);
                        },
                        activeColor: const Color(0xFF38B2AC),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (nameController.text.isEmpty ||
                                    descriptionController.text.isEmpty ||
                                    priceController.text.isEmpty ||
                                    capacityController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill in all required fields'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isUploading = true;
                                });

                                try {
                                  String? finalImageUrl;

                                  // Upload image if a new image was selected
                                  if (selectedImage != null) {
                                    try {
                                      // Delete old image if it exists and is from Firebase Storage
                                      if (room.imageUrl.isNotEmpty) {
                                        await _bookingService.deleteRoomImage(room.imageUrl);
                                      }
                                      // Upload new image
                                      finalImageUrl = await _bookingService.uploadRoomImage(
                                        selectedImage!,
                                        room.id,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        setDialogState(() {
                                          isUploading = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error uploading image: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  } else if (imageUrlController.text.isNotEmpty) {
                                    // Use URL if provided and no new image was selected
                                    finalImageUrl = imageUrlController.text;
                                  } else if (clearImage || (imageUrlController.text.isEmpty && room.imageUrl.isNotEmpty)) {
                                    // If URL field is cleared or clearImage flag is set, remove the image
                                    finalImageUrl = '';
                                    // Delete old image from Firebase Storage if it exists
                                    if (room.imageUrl.isNotEmpty) {
                                      await _bookingService.deleteRoomImage(room.imageUrl);
                                    }
                                  } else {
                                    // Keep existing image if no changes made
                                    finalImageUrl = room.imageUrl;
                                  }

                                  final amenities = amenitiesController.text
                                      .split(',')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();

                                  await _bookingService.updateRoom(
                                    roomId: room.id,
                                    name: nameController.text,
                                    description: descriptionController.text,
                                    price: double.tryParse(priceController.text) ?? room.price,
                                    capacity: int.tryParse(capacityController.text) ?? room.capacity,
                                    amenities: amenities,
                                    imageUrl: finalImageUrl,
                                    isAvailable: isAvailable,
                                    userId: _currentUser!.id,
                                  );

                                  if (context.mounted) {
                                    setDialogState(() {
                                      isUploading = false;
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Room updated successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setDialogState(() {
                                      isUploading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A67D8),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Update Room'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteRoomDialog(Room room) {
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delete Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${room.name}"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _bookingService.deleteRoom(
                          roomId: room.id,
                          userId: _currentUser!.id,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF56565),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int index;

  _NavItemData({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}