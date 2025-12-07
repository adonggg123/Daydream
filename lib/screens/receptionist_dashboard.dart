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
import 'login_page.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final BookingService _bookingService = BookingService();
  final GuestRequestService _guestRequestService = GuestRequestService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppUser? _currentUser;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    if (!_currentUser!.isReceptionist) {
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
                  'You need receptionist privileges\nto access this dashboard',
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
                        scale: 2.8,
                        child: Image.asset(
                          'assets/icons/LOGO2.png',
                          width: 500,
                          height: 500,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Receptionist Panel',
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
                  label: 'Bookings',
                  index: 0,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildNavItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Guest Requests',
                  index: 1,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.receipt_rounded,
                  label: 'Receipts',
                  index: 2,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9F7AEA), Color(0xFF805AD5)],
                  ),
                ),
                _buildNavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  index: 3,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFED8936), Color(0xFFDD6B20)],
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
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFF56565),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Color(0xFFF56565),
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

  void _handleLogout() async {
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
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('user_notifications').where('userId', isEqualTo: _currentUser?.id ?? '').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final unreadCount = docs.where((d) => (d.data() as Map<String, dynamic>)['isRead'] == false).length;
                  
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
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
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
                  child: Center(
                    child: Text(
                      _currentUser?.displayName?.isNotEmpty == true
                          ? _currentUser!.displayName![0].toUpperCase()
                          : 'R',
                      style: const TextStyle(
                        color: Color(0xFF5A67D8),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
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
                        _currentUser?.displayName ?? 'Receptionist',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _currentUser?.email ?? 'receptionist@example.com',
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
              '${_currentUser?.displayName ?? 'Receptionist'} • ${_formatDateTime(DateTime.now())}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'Bookings Overview';
      case 1: return 'Guest Requests';
      case 2: return 'Receipts';
      case 3: return 'Notifications';
      default: return 'Receptionist Panel';
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              if (isMobile)
                Column(
                  children: [
                    _buildRecentBookingsCard(isMobile: isMobile),
                    const SizedBox(height: 16),
                    _buildGuestRequestsCard(isMobile: isMobile),
                    const SizedBox(height: 16),
                    _buildQuickActions(isMobile: isMobile),
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
                          _buildRecentBookingsCard(isMobile: isMobile),
                          const SizedBox(height: 20),
                          _buildGuestRequestsCard(isMobile: isMobile),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: _buildQuickActions(isMobile: isMobile)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Gradient gradient, bool isMobile = false}) {
    return Container(
      height: isMobile ? 160 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.2),
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
              child: icon == Icons.attach_money_rounded
                  ? Text(
                      '₱',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
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
                  title,
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
        final docs = snapshot.data!.docs;
        final total = docs.length;
        final confirmed = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'confirmed').length;
        final pending = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'pending').length;
        double totalRevenue = 0;
        for (var d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final t = data['total'];
          if (t is num) totalRevenue += t.toDouble();
        }

        final stats = [
          _StatItem(
            title: 'Total Bookings',
            value: total.toString(),
            icon: Icons.book_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF5A67D8), Color(0xFF4C51BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _StatItem(
            title: 'Confirmed',
            value: confirmed.toString(),
            icon: Icons.check_circle_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF38B2AC), Color(0xFF319795)],
            ),
          ),
          _StatItem(
            title: 'Pending',
            value: pending.toString(),
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
                    Expanded(child: _buildStatCard(title: stats[0].title, value: stats[0].value, icon: stats[0].icon, gradient: stats[0].gradient, isMobile: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(title: stats[1].title, value: stats[1].value, icon: stats[1].icon, gradient: stats[1].gradient, isMobile: true)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(title: stats[2].title, value: stats[2].value, icon: stats[2].icon, gradient: stats[2].gradient, isMobile: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(title: stats[3].title, value: stats[3].value, icon: stats[3].icon, gradient: stats[3].gradient, isMobile: true)),
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
                child: _buildStatCard(title: stats[index].title, value: stats[index].value, icon: stats[index].icon, gradient: stats[index].gradient, isMobile: false),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentBookingsCard({bool isMobile = false}) {
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
          const Divider(height: 0),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: _buildBookingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestRequestsCard({bool isMobile = false}) {
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
                      colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Guest Requests',
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
          const Divider(height: 0),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: _buildGuestRequestsView(),
          ),
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
                _buildActionTile(
            icon: Icons.add_box_rounded,
            title: 'Create Booking',
            color: const Color(0xFF5A67D8),
            onTap: () {/* TODO: Open create booking dialog */},
          ),
          const Divider(),
          _buildActionTile(
            icon: Icons.search_rounded,
            title: 'Search Guest',
            color: Colors.blueGrey,
            onTap: () {/* TODO: open search */},
          ),
          const Divider(),
          _buildActionTile(
            icon: Icons.meeting_room_rounded,
            title: 'Assign Room',
            color: Colors.teal,
            onTap: () {/* Show bookings*/},
          ),
          const Divider(),
          _buildActionTile(
            icon: Icons.receipt_rounded,
            title: 'Generate Receipt',
            color: const Color(0xFF9F7AEA),
            onTap: () {/* TODO: Generate */},
          ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
      ),
      onTap: onTap,
    );
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
                                  child: Text('${room.name} - ₱${room.price.toStringAsFixed(2)}'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return Center(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                    Icons.receipt_rounded,
                    size: 48,
                    color: Color(0xFF9F7AEA),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Receipts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Receipt management coming soon',
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
        );
      },
    );
  }

  Widget _buildNotificationsView() {
    final TextEditingController _recipientIdController = TextEditingController();
    final TextEditingController _notifTitleController = TextEditingController();
    final TextEditingController _notifMessageController = TextEditingController();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send Notification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recipientIdController,
                decoration: const InputDecoration(
                  labelText: 'Recipient User ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notifTitleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notifMessageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
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
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Notification sent'),
                          backgroundColor: const Color(0xFF48BB78),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send notification: $e'),
                          backgroundColor: const Color(0xFFF56565),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A67D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    final allNavItems = [
      _NavItemData(icon: Icons.dashboard_rounded, label: 'Bookings', index: 0),
      _NavItemData(icon: Icons.support_agent_rounded, label: 'Requests', index: 1),
      _NavItemData(icon: Icons.receipt_rounded, label: 'Receipts', index: 2),
      _NavItemData(icon: Icons.notifications_rounded, label: 'Notifications', index: 3),
    ];

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
                      size: 20,
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
