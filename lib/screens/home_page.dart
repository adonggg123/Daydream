import 'dart:async';
import 'package:flutter/material.dart';
import 'receptionist_dashboard.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../widgets/social_feed.dart';
import 'event_booking_page.dart';
import 'login_page.dart';
import 'room_detail_page.dart';
import 'gallery_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'admin_dashboard.dart';
import 'theme_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  AppUser? _currentUserProfile;

  void _openEventBookingPage() {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book the event hall.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EventBookingPage(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _loadUserProfile();
    _searchController.addListener(_filterRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRooms = _rooms;
      } else {
        _filteredRooms = _rooms.where((room) {
          return room.name.toLowerCase().contains(query) ||
              room.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _loadUserProfile() {
    final user = _authService.currentUser;
    if (user != null) {
      _userService.streamUserProfile(user.uid).listen((profile) {
        if (mounted) {
          setState(() {
            _currentUserProfile = profile;
          });
        }
      });
    }
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    
    try {
      await _bookingService.forceInitializeRooms()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Timeout initializing rooms');
            },
          );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final rooms = await _bookingService.getAllRoomsForAdmin()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout loading rooms');
              return <Room>[];
            },
          );
      
      debugPrint('Loaded ${rooms.length} rooms');
      
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _filteredRooms = rooms;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      debugPrint('Timeout loading rooms');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _rooms = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timed out. Please check your internet connection.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading rooms: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _rooms = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rooms: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildHomeContent() {
    final user = _authService.currentUser;
    final userName = user?.email?.split('@').first ?? 'Guest';
    final userInitial = user?.email?[0].toUpperCase() ?? 'U';

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                final isCollapsed = top <= 100;
                return FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  titlePadding: EdgeInsets.only(
                    left: 20,
                    bottom: 16,
                    top: isCollapsed ? 16 : 0,
                  ),
                  title: AnimatedOpacity(
                    opacity: isCollapsed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.43, // Scale to maintain 80x80 visual size (80/56 = 1.43)
                              child: Image.asset(
                              'assets/icons/LOGO2.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              )
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Daydream Resort',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // User profile avatar - always visible when collapsed
                        PopupMenuButton<String>(
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.accentGradient,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) async {
                            if (value == 'logout') {
                              try {
                                await _authService.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } else if (value == 'admin') {
                              if (_currentUserProfile?.isReceptionist == true) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceptionistDashboard()));
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
                              }
                            }
                          },
                          itemBuilder: (context) {
                            final isStaffOrAdmin = _currentUserProfile?.isStaffOrAdmin ?? false;
                            
                            return [
                              PopupMenuItem(
                                value: 'user',
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.email ?? 'User',
                                      style: AppTheme.heading3.copyWith(fontSize: 14),
                                    ),
                                    if (_currentUserProfile != null)
                                      Text(
                                        'Role: ${_currentUserProfile!.role.name.toUpperCase()}',
                                        style: AppTheme.caption,
                                      ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                  ],
                                ),
                              ),
                              if (isStaffOrAdmin)
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 20, color: AppTheme.primaryColor),
                                      const SizedBox(width: 12),
                                      const Text('Admin Dashboard'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 20, color: AppTheme.errorColor),
                                    const SizedBox(width: 12),
                                    const Text('Sign Out'),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Logo and Welcome Section
                            Row(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Transform.scale(
                                      scale: 1.43, // Scale to maintain 80x80 visual size (80/56 = 1.43)
                                      child: Image.asset(
                                        'assets/icons/LOGO2.png',
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.accentGradient,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        userInitial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  color: Colors.white,
                                  surfaceTintColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  onSelected: (value) async {
                                    if (value == 'logout') {
                                      try {
                                        await _authService.signOut();
                                        if (mounted) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) => const LoginPage(),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                              backgroundColor: Colors.red,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    } else if (value == 'admin') {
                                      if (_currentUserProfile?.isReceptionist == true) {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceptionistDashboard()));
                                      } else {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
                                      }
                                    }
                                  },
                                  itemBuilder: (context) {
                                    final isStaffOrAdmin = _currentUserProfile?.isStaffOrAdmin ?? false;
                                    
                                    return [
                                      PopupMenuItem(
                                        value: 'user',
                                        enabled: false,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user?.email ?? 'User',
                                              style: AppTheme.heading3.copyWith(fontSize: 14),
                                            ),
                                            if (_currentUserProfile != null)
                                              Text(
                                                'Role: ${_currentUserProfile!.role.name.toUpperCase()}',
                                                style: AppTheme.caption,
                                              ),
                                            const SizedBox(height: 8),
                                            const Divider(),
                                          ],
                                        ),
                                      ),
                                      if (isStaffOrAdmin)
                                        PopupMenuItem(
                                          value: 'admin',
                                          child: Row(
                                            children: [
                                              Icon(Icons.admin_panel_settings, size: 20, color: AppTheme.primaryColor),
                                              const SizedBox(width: 12),
                                              const Text('Admin Dashboard'),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'logout',
                                        child: Row(
                                          children: [
                                            Icon(Icons.logout, size: 20, color: AppTheme.errorColor),
                                            const SizedBox(width: 12),
                                            const Text('Sign Out'),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Tagline Section
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Where Technology Meets Paradise',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.95),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ];
      },
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Available Rooms',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_rooms.where((r) => r.isAvailable).length}',
                                        style: AppTheme.heading2.copyWith(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Rooms',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_rooms.length}',
                                        style: AppTheme.heading2.copyWith(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Event Booking Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentColor.withOpacity(0.9),
                                  const Color(0xFFF472B6).withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.celebration,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Plan Your Perfect Event',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Book our event hall for celebrations, meetings, or special occasions',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _openEventBookingPage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.accentColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Book Now',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Search Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => _filterRooms(),
                              decoration: InputDecoration(
                                hintText: 'Search rooms, amenities...',
                                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
                                prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterRooms();
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _filteredRooms.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  _searchController.text.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.hotel_outlined,
                                  size: 80,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No rooms found'
                                      : 'No rooms available',
                                  style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Try different search terms'
                                      : 'Please check back later',
                                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'Search Results (${_filteredRooms.length})'
                                          : 'Featured Rooms',
                                      style: AppTheme.heading2,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 12,
                                            color: AppTheme.successColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_filteredRooms.where((r) => r.isAvailable).length} Available',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 380,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredRooms.length,
                                  itemBuilder: (context, index) {
                                    final room = _filteredRooms[index];
                                    return Container(
                                      width: 280,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: ClipRect(  
                                      child: _buildRoomCard(room),
                                      )
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Community Feed',
                                style: AppTheme.heading3,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Latest',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          user != null
                              ? SocialFeed(currentUserId: user.uid)
                              : Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 48,
                                        color: AppTheme.textSecondary.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sign in to view and share experiences',
                                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginPage(),
                                            ),
                                          );
                                        },
                                        style: AppTheme.secondaryButtonStyle,
                                        child: const Text('Sign In'),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const GalleryPage();
      case 2:
        return NotificationsPage(
          onPageOpened: () {
            setState(() {});
          },
        );
      case 3:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_rounded,
                  size: 24,
                  color: _currentIndex == 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  size: 24,
                  color: _currentIndex == 1 ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
              label: 'Gallery',
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<int>(
                stream: _authService.currentUser != null
                    ? _notificationService.getUnreadNotificationCount(_authService.currentUser!.uid)
                    : Stream.value(0),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentIndex == 2 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          size: 24,
                          color: _currentIndex == 2 ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: _currentIndex == 3 ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetailsDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.hotel_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${room.price.toStringAsFixed(2)}/night',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RoomDetailPage(room: room),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Booking',
                          style: TextStyle(
                            color: Colors.white,
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
  }

  Widget _buildRoomCard(Room room) {
    return GestureDetector(
      onTap: room.isAvailable
          ? () {
              _showRoomDetailsDialog(room);
            }
          : null,
      child: Opacity(
        opacity: room.isAvailable ? 1.0 : 0.7,
        child: Container(
          width: 280,
          height: 360,
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: room.imageUrl.isEmpty
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.1),
                                  AppTheme.secondaryColor.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                      child: room.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: Image.network(
                                room.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.hotel,
                                      size: 50,
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.hotel,
                                size: 50,
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                    ),
                    if (!room.isAvailable)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'UNAVAILABLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 12,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.capacity}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            room.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 32,
                            child: Text(
                              room.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'From',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₱${room.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(
                                maxWidth: 90,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: room.isAvailable ? AppTheme.primaryGradient : null,
                                color: !room.isAvailable ? AppTheme.textSecondary.withOpacity(0.1) : null,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: room.isAvailable
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                room.isAvailable ? 'Book Now' : 'Unavailable',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: room.isAvailable ? Colors.white : AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
