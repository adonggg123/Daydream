import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cottage.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../screens/booking_confirmation_page.dart';
import '../screens/theme_constants.dart';

class CottageBookingForm extends StatefulWidget {
  final Cottage cottage;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;
  final int? initialGuests;

  const CottageBookingForm({
    super.key,
    required this.cottage,
    this.initialCheckIn,
    this.initialCheckOut,
    this.initialGuests,
  });

  @override
  State<CottageBookingForm> createState() => _CottageBookingFormState();
}

class _CottageBookingFormState extends State<CottageBookingForm> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _guests;
  final TextEditingController _specialRequestsController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _checkIn = widget.initialCheckIn ?? today;
    // For cottages: one day only - set check-out to next day for proper cost calculation (1 day = 1 night)
    _checkOut = DateTime(_checkIn.year, _checkIn.month, _checkIn.day + 1);
    _guests = widget.initialGuests ?? 1;
    
    // Ensure guests is within cottage capacity
    if (_guests > widget.cottage.capacity) {
      _guests = widget.cottage.capacity;
    }
    if (_guests < 1) {
      _guests = 1;
    }
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Booking Date',
    );
    if (picked != null && picked != _checkIn) {
      setState(() {
        _checkIn = picked;
        // For cottages: one day only - set check-out to next day for proper cost calculation
        _checkOut = DateTime(_checkIn.year, _checkIn.month, _checkIn.day + 1);
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
    if (_guests < widget.cottage.capacity) {
      setState(() {
        _guests++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum capacity is ${widget.cottage.capacity} guests'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _proceedToPayment() {
    // Validate cottage availability
    if (!widget.cottage.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This cottage is currently not available for booking'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For cottages: one day only (check-out is automatically set to next day for calculation)
    // Validation is handled by ensuring check-out is always next day after check-in

    // Validate guests - must be within cottage capacity
    if (_guests < 1 || _guests > widget.cottage.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Number of guests must be between 1 and ${widget.cottage.capacity} (cottage capacity)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Convert cottage to room for booking system compatibility
    // TODO: Extend booking system to support cottages natively
    final room = Room(
      id: widget.cottage.id,
      name: widget.cottage.name,
      description: widget.cottage.description,
      price: widget.cottage.price,
      capacity: widget.cottage.capacity,
      amenities: widget.cottage.amenities,
      imageUrl: widget.cottage.imageUrl,
      isAvailable: widget.cottage.isAvailable,
    );

    // For cottages: one day only
    // Set check-out to next day at start (00:00) so difference is 1 day for cost calculation
    // But in UI we show it as "one day only"
    final checkOutDate = DateTime(_checkIn.year, _checkIn.month, _checkIn.day + 1);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
          room: room,
          checkIn: _checkIn,
          checkOut: checkOutDate,
          guests: _guests,
          eventType: EventType.none,
          eventDetails: null,
          specialRequests: _specialRequestsController.text.trim().isEmpty
              ? null
              : _specialRequestsController.text.trim(),
          isCottageBooking: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Booking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cottage Summary Card
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
                      widget.cottage.name,
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
                        Icon(Icons.home, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          '1 day • $_guests ${_guests == 1 ? 'guest' : 'guests'}',
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

                    // Booking Date (one day only for cottages)
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
                            Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking Date',
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
                                  const SizedBox(height: 4),
                                  Text(
                                    'One day only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
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
                        Icon(Icons.people, color: AppTheme.primaryColor, size: 24),
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
                                'Max capacity: ${widget.cottage.capacity} guests',
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
                                  color: _guests > 1 ? AppTheme.primaryColor : Colors.grey.shade400,
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
                                  color: _guests < widget.cottage.capacity
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade400,
                                ),
                                onPressed: _guests < widget.cottage.capacity ? _increaseGuests : null,
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
                        Icon(Icons.note_add, color: AppTheme.primaryColor, size: 24),
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
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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

