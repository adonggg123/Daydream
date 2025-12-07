import 'package:flutter/material.dart';
import '../services/event_booking_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/booking.dart';
import 'theme_constants.dart';

class EventBookingPage extends StatefulWidget {
  const EventBookingPage({super.key});

  @override
  State<EventBookingPage> createState() => _EventBookingPageState();
}

class _EventBookingPageState extends State<EventBookingPage> {
  final EventBookingService _eventService = EventBookingService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  DateTime _selectedDate = DateTime.now();
  EventType _eventType = EventType.birthday;
  int _peopleCount = 50;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _userService.getUserProfile(user.uid);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select event date',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppTheme.primaryColor,
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to book an event.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _eventService.createEventBooking(
        userId: user.uid,
        userEmail: user.email ?? 'unknown',
        eventType: _eventType,
        eventDate: _selectedDate,
        peopleCount: _peopleCount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event booked for ${_formatDate(_selectedDate)}'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.43, // Scale to maintain 80x80 visual size (80/56 = 1.43)
                  child: Image.asset(
                    'assets/icons/LOGO2.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Event Booking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderColor, width: 2),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sign In Required',
                      style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please sign in to book events at our resort',
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppTheme.primaryButtonStyle,
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
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
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Event Details',
                              style: AppTheme.heading3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Event Date',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(_selectedDate),
                                        style: AppTheme.heading3.copyWith(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Event Type',
                          style: AppTheme.heading3.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: EventType.values
                              .where((e) => e != EventType.none)
                              .map(
                                (eventType) {
                                  final isSelected = _eventType == eventType;
                                  return ChoiceChip(
                                    label: Text(
                                      Booking.getEventTypeDisplay(eventType),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _eventType = eventType);
                                      }
                                    },
                                    selectedColor: AppTheme.primaryColor,
                                    backgroundColor: Colors.white,
                                    checkmarkColor: Colors.white,
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  );
                                },
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
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
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.people,
                                color: AppTheme.accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Guest Count',
                              style: AppTheme.heading3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            children: [
                              Slider(
                                value: _peopleCount.toDouble(),
                                min: 10,
                                max: 300,
                                divisions: 29,
                                onChanged: (value) {
                                  setState(() => _peopleCount = value.round());
                                },
                                activeColor: AppTheme.primaryColor,
                                inactiveColor: AppTheme.borderColor,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: _peopleCount > 10
                                          ? () => setState(() => _peopleCount -= 10)
                                          : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: _peopleCount > 10 ? AppTheme.primaryColor : AppTheme.textSecondary,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '$_peopleCount',
                                          style: AppTheme.heading2.copyWith(
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          'guests',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: _peopleCount < 300
                                          ? () => setState(() => _peopleCount += 10)
                                          : null,
                                      icon: Icon(
                                        Icons.add,
                                        color: _peopleCount < 300 ? AppTheme.primaryColor : AppTheme.textSecondary,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
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
                                color: AppTheme.infoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.note,
                                color: AppTheme.infoColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Additional Notes',
                              style: AppTheme.heading3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            labelText: 'Special requests or notes',
                            hintText: 'Tell us more about your event...',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: AppTheme.gradientButtonStyle.copyWith(
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Confirm Event Booking',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.celebration, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.infoColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Our event coordinator will contact you within 24 hours to confirm details.',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
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
    );
  }
}