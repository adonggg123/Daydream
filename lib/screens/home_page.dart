import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../widgets/social_feed.dart';
import 'login_page.dart';
import 'room_detail_page.dart';
import 'gallery_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'admin_dashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final BookingService _bookingService = BookingService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  AppUser? _currentUserProfile;

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
      // Force initialize rooms to ensure they exist
      await _bookingService.forceInitializeRooms()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Timeout initializing rooms');
            },
          );
      
      // Wait a bit for Firestore to sync
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get all rooms including unavailable ones (for display)
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
      // Print error for debugging
      debugPrint('Error loading rooms: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _rooms = []; // Set empty list on error
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
    return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.purple.shade600,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Daydream Resort',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
              actions: [
                // User Menu
                PopupMenuButton<String>(
                  icon: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.email?[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.purple.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  color: Colors.white,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboard(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    final isAdmin = _currentUserProfile?.isAdmin ?? false;
                    
                    return [
                      PopupMenuItem(
                        value: 'user',
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_currentUserProfile != null)
                              Text(
                                'Role: ${_currentUserProfile!.role.name.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 4),
                            const Divider(),
                          ],
                        ),
                      ),
                      if (isAdmin)
                        PopupMenuItem(
                          value: 'admin',
                          child: const Row(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 20),
                              SizedBox(width: 8),
                              Text('Admin Dashboard'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
                const SizedBox(width: 8),
              ],
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
                    // Welcome Section
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Daydream Resort',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Discover our luxurious accommodations',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Search Bar
                            StatefulBuilder(
                              builder: (context, setState) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade200,
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {});
                                      _filterRooms();
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search rooms...',
                                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Rooms Horizontal Scroll
                    _filteredRooms.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    _searchController.text.isNotEmpty
                                        ? Icons.search_off
                                        : Icons.hotel_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No rooms found matching your search'
                                        : 'No rooms available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
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
                                            : 'All Rooms',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 320,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _filteredRooms.length,
                                    itemBuilder: (context, index) {
                                      final room = _filteredRooms[index];
                                      return Container(
                                        width: 280,
                                        margin: const EdgeInsets.only(right: 16),
                                        child: _buildRoomCard(room),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                    // Social Feed Section
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: user != null
                            ? SocialFeed(currentUserId: user.uid)
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('Please login to view social feed'),
                                ),
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
        return const NotificationsPage();
      case 3:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple.shade600,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RoomDetailPage(room: room),
          ),
        );
      },
      child: Opacity(
        opacity: room.isAvailable ? 1.0 : 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: room.imageUrl.isNotEmpty
                    ? Image.network(
                        room.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.purple.shade100,
                            child: Icon(
                              Icons.hotel,
                              size: 50,
                              color: Colors.purple.shade300,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.purple.shade100,
                        child: Icon(
                          Icons.hotel,
                          size: 50,
                          color: Colors.purple.shade300,
                        ),
                      ),
              ),
            ),

            // Room Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        room.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${room.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        if (!room.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Not Available',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${room.capacity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
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
