import 'package:flutter/material.dart';
import '../services/cottage_service.dart';
import '../models/cottage.dart';
import 'theme_constants.dart';
import '../widgets/cottage_image_widget.dart';
import 'cottage_detail_page.dart';

class CottagePage extends StatefulWidget {
  const CottagePage({super.key});

  @override
  State<CottagePage> createState() => _CottagePageState();
}

class _CottagePageState extends State<CottagePage> {
  final CottageService _cottageService = CottageService();

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
                    child: Transform.scale(
                      scale: 1.43,
                      child: Image.asset(
                        'assets/icons/LOGO2.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cottage',
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
                    'Cottage Collection',
                    style: AppTheme.heading2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover our beautiful cottages for your perfect getaway',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<List<Cottage>>(
              stream: _cottageService.streamAllCottages(),
              builder: (context, snapshot) {
                // Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  );
                }

                // Handle error state
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error loading cottages',
                          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Get cottages from stream
                final cottages = snapshot.data ?? [];

                if (cottages.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 80,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No cottages available',
                          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for updates',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: cottages.length,
                    itemBuilder: (context, index) {
                      final cottage = cottages[index];
                      return _buildCottageItem(cottage);
                    },
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildCottageItem(Cottage cottage) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CottageDetailPage(cottage: cottage),
          ),
        );
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
                child: CottageImageWidget(
                  imageUrl: cottage.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cottage.name,
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
                        '${cottage.capacity} guests',
                        style: AppTheme.caption,
                      ),
                      const Spacer(),
                      Text(
                        '₱${cottage.price.toStringAsFixed(0)}',
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


