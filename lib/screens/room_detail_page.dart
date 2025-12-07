import 'package:flutter/material.dart';
import '../models/room.dart';
import '../widgets/enhanced_booking_form.dart';
import 'theme_constants.dart';

class RoomDetailPage extends StatelessWidget {
  final Room room;

  const RoomDetailPage({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final defaultCheckIn = today;
    final defaultCheckOut = today.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: room.imageUrl.isNotEmpty
                  ? Image.network(
                      room.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.hotel,
                              size: 100,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.hotel,
                          size: 100,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
            ),
            leading: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.black87,
                  ),
                ),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: room.isAvailable 
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          room.isAvailable ? Icons.check_circle : Icons.block,
                          size: 14,
                          color: room.isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          room.isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: room.isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: AppTheme.heading2,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Up to ${room.capacity} ${room.capacity > 1 ? 'guests' : 'guest'}',
                                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${room.price.toStringAsFixed(2)}',
                            style: AppTheme.heading2.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            'per night',
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Description',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    room.description,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (room.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: AppTheme.heading3,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: room.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAmenityIcon(amenity),
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                amenity,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],

                  if (!room.isAvailable)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.block,
                            size: 48,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Currently Unavailable',
                            style: AppTheme.heading3.copyWith(color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This room is not available for booking at the moment. Please check back later or explore other rooms.',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: AppTheme.secondaryButtonStyle,
                            child: const Text('Browse Other Rooms'),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ready to Book?',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Select your dates and book this room',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EnhancedBookingForm(
                                      room: room,
                                      initialCheckIn: defaultCheckIn,
                                      initialCheckOut: defaultCheckOut,
                                      initialGuests: 1,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'air conditioning':
        return Icons.ac_unit;
      case 'tv':
        return Icons.tv;
      case 'minibar':
        return Icons.local_bar;
      case 'safe':
        return Icons.security;
      case 'balcony':
        return Icons.balcony;
      case 'bathtub':
        return Icons.bathtub;
      case 'shower':
        return Icons.shower;
      case 'coffee maker':
        return Icons.coffee;
      case 'fridge':
        return Icons.kitchen;
      default:
        return Icons.check_circle;
    }
  }
}