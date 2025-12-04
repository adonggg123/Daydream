import 'package:flutter/material.dart';
import '../services/event_booking_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/booking.dart';

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
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to book an event.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
            content: Text('Event booked for ${_selectedDate.toLocal().toString().split(' ').first}.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
      appBar: AppBar(
        title: const Text('Event Booking'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please log in to book an event.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: const Icon(Icons.calendar_today, color: Colors.purple),
                            ),
                            title: Text(
                              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Function hall (one event per day)'),
                            trailing: TextButton(
                              onPressed: _pickDate,
                              child: const Text('Change'),
                            ),
                          ),
                          const Divider(),
                          const Text(
                            'Event type',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: EventType.values
                                .where((e) => e != EventType.none)
                                .map(
                                  (eventType) => ChoiceChip(
                                    label: Text(Booking.getEventTypeDisplay(eventType)),
                                    selected: _eventType == eventType,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _eventType = eventType);
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Guests attending',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _peopleCount > 10
                                    ? () => setState(() => _peopleCount -= 10)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _peopleCount.toDouble(),
                                  min: 10,
                                  max: 300,
                                  divisions: 29,
                                  label: '$_peopleCount',
                                  onChanged: (value) {
                                    setState(() => _peopleCount = value.round());
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: _peopleCount < 300
                                    ? () => setState(() => _peopleCount += 10)
                                    : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          Center(
                            child: Text(
                              '$_peopleCount guests',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Event notes / requests',
                      alignLabelWithHint: true,
                      hintText: 'Share more details about your celebration...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm event booking'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

