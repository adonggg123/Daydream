import 'package:flutter/material.dart';
import '../models/cottage.dart';
import '../widgets/cottage_image_widget.dart';
import '../widgets/cottage_booking_form.dart';
import 'theme_constants.dart';

class CottageDetailPage extends StatelessWidget {
  final Cottage cottage;

  const CottageDetailPage({
    super.key,
    required this.cottage,
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
              background: cottage.imageUrl.isNotEmpty
                  ? CottageImageWidget(
                      imageUrl: cottage.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.home,
                            size: 100,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.home,
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
                      color: cottage.isAvailable 
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cottage.isAvailable ? Icons.check_circle : Icons.block,
                          size: 14,
                          color: cottage.isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cottage.isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cottage.isAvailable ? AppTheme.successColor : AppTheme.errorColor,
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
                              cottage.name,
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
                                  'Up to ${cottage.capacity} ${cottage.capacity > 1 ? 'guests' : 'guest'}',
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
                            '₱${cottage.price.toStringAsFixed(0)}',
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
                    cottage.description,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (cottage.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: AppTheme.heading3,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: cottage.amenities.map((amenity) {
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

                  if (!cottage.isAvailable)
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
                            'This cottage is not available for booking at the moment. Please check back later or explore other cottages.',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: AppTheme.secondaryButtonStyle,
                            child: const Text('Browse Other Cottages'),
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
                                    const Text(
                                      'Ready to Book?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Select your dates and book this cottage',
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
                                    builder: (context) => CottageBookingForm(
                                      cottage: cottage,
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
      case 'kitchen':
        return Icons.kitchen;
      case 'parking':
        return Icons.local_parking;
      case 'balcony':
        return Icons.balcony;
      case 'garden':
        return Icons.local_florist;
      case 'bbq':
      case 'barbecue':
        return Icons.outdoor_grill;
      case 'fireplace':
        return Icons.fireplace;
      case 'hot tub':
      case 'jacuzzi':
        return Icons.hot_tub;
      default:
        return Icons.check_circle;
    }
  }
}

