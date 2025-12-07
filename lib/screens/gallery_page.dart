import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/room.dart';
import 'theme_constants.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final BookingService _bookingService = BookingService();
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await _bookingService.getAllRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            toolbarHeight: 70,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/LOGO2.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gallery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resort Collection',
                    style: AppTheme.heading2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover our luxurious accommodations and amenities',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          _isLoading
              ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ),
                )
              : _rooms.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 80,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No rooms available',
                              style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for updates',
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final room = _rooms[index];
                            return _buildGalleryItem(room);
                          },
                          childCount: _rooms.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(Room room) {
    return GestureDetector(
      onTap: () {
        // Navigate to room detail page
      },
      child: Container(
        decoration: AppTheme.cardDecoration.copyWith(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: room.imageUrl.isNotEmpty
                    ? Image.network(
                        room.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            child: Center(
                              child: Icon(
                                Icons.hotel,
                                size: 40,
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.hotel,
                            size: 40,
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${room.capacity} guests',
                        style: AppTheme.caption,
                      ),
                      const Spacer(),
                      Text(
                        '₱${room.price.toStringAsFixed(0)}',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '/night',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}