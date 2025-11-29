import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../screens/booking_confirmation_page.dart';

class EnhancedBookingForm extends StatefulWidget {
  final Room room;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int? initialGuests;

  const EnhancedBookingForm({
    super.key,
    required this.room,
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialGuests,
  });

  @override
  State<EnhancedBookingForm> createState() => _EnhancedBookingFormState();
}

class _EnhancedBookingFormState extends State<EnhancedBookingForm> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _guests;
  EventType _selectedEventType = EventType.none;
  final TextEditingController _eventDetailsController = TextEditingController();
  final TextEditingController _specialRequestsController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _checkIn = widget.initialCheckIn ?? today;
    _checkOut = widget.initialCheckOut ?? today.add(const Duration(days: 1));
    _guests = widget.initialGuests ?? 1;
    
    // Ensure check-out is after check-in
    if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
      _checkOut = _checkIn.add(const Duration(days: 1));
    }
    
    // Ensure guests is within room capacity
    if (_guests > widget.room.capacity) {
      _guests = widget.room.capacity;
    }
    if (_guests < 1) {
      _guests = 1;
    }
  }

  @override
  void dispose() {
    _eventDetailsController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Check-in Date',
    );
    if (picked != null && picked != _checkIn) {
      setState(() {
        _checkIn = picked;
        // If check-out is before or same as new check-in, adjust it
        if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOut,
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Check-out Date',
    );
    if (picked != null && picked != _checkOut) {
      setState(() {
        _checkOut = picked;
      });
    }
  }

  void _decreaseGuests() {
    if (_guests > 1) {
      setState(() {
        _guests--;
      });
    }
  }

  void _increaseGuests() {
    if (_guests < widget.room.capacity) {
      setState(() {
        _guests++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum capacity is ${widget.room.capacity} guests'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _proceedToPayment() {
    // Validate room availability
    if (!widget.room.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This room is currently not available for booking'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate dates
    if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-out date must be after check-in date'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate guests
    if (_guests < 1 || _guests > widget.room.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Number of guests must be between 1 and ${widget.room.capacity}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
          room: widget.room,
          checkIn: _checkIn,
          checkOut: _checkOut,
          guests: _guests,
          eventType: _selectedEventType,
          eventDetails: _eventDetailsController.text.trim().isEmpty
              ? null
              : _eventDetailsController.text.trim(),
          specialRequests: _specialRequestsController.text.trim().isEmpty
              ? null
              : _specialRequestsController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberOfNights = _checkOut.difference(_checkIn).inDays;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Complete Booking'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Room Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '${_dateFormat.format(_checkIn)} - ${_dateFormat.format(_checkOut)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.bed, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '$numberOfNights ${numberOfNights == 1 ? 'night' : 'nights'} • $_guests ${_guests == 1 ? 'guest' : 'guests'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Booking Details Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Check-in Date
                    InkWell(
                      onTap: _selectCheckInDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.purple.shade600, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateFormat.format(_checkIn),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Check-out Date
                    InkWell(
                      onTap: _selectCheckOutDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.purple.shade600, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-out Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dateFormat.format(_checkOut),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Number of Guests
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.purple.shade600, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Number of Guests',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Room capacity: ${widget.room.capacity} guests',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.remove,
                                  color: _guests > 1 ? Colors.purple.shade600 : Colors.grey.shade400,
                                ),
                                onPressed: _guests > 1 ? _decreaseGuests : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_guests',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: _guests < widget.room.capacity
                                      ? Colors.purple.shade600
                                      : Colors.grey.shade400,
                                ),
                                onPressed: _guests < widget.room.capacity ? _increaseGuests : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Event Reservation Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade50,
                    Colors.blue.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.shade200,
                  width: 2,
                ),
              ),
              child: Card(
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Reservation',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Celebrate your special occasion with us!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.purple.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select an event type to see special discounts and services',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'What are you celebrating?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EventType.values.where((e) => e != EventType.none).map((eventType) {
                          final isSelected = _selectedEventType == eventType;
                          return FilterChip(
                            label: Text(Booking.getEventTypeDisplay(eventType)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedEventType = selected ? eventType : EventType.none;
                                if (!selected) {
                                  _eventDetailsController.clear();
                                }
                              });
                            },
                            selectedColor: Colors.purple.shade100,
                            checkmarkColor: Colors.purple.shade600,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.purple.shade600 : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Event Details (if event selected)
                      if (_selectedEventType != EventType.none) ...[
                        TextField(
                          controller: _eventDetailsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Event Details (optional)',
                            hintText: 'Tell us more about your event...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Special Requests Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note_add, color: Colors.purple.shade600, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Special Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _specialRequestsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Any special requests?',
                        hintText: 'E.g., Late check-in, extra towels, dietary requirements...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
