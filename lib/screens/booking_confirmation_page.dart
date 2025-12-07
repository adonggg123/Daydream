import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'theme_constants.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final EventType eventType;
  final String? eventDetails;
  final String? specialRequests;

  const BookingConfirmationPage({
    super.key,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.eventType,
    this.eventDetails,
    this.specialRequests,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  final BookingService _bookingService = BookingService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _isProcessing = false;
  late BookingCost _bookingCost;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final numberOfNights = widget.checkOut.difference(widget.checkIn).inDays;
    _bookingCost = PaymentService.calculateCost(
      roomPricePerNight: widget.room.price,
      numberOfNights: numberOfNights,
      eventType: widget.eventType,
      guests: widget.guests,
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid card number (13-19 digits)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final expiry = _expiryController.text.trim();
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter expiry in MM/YY format (e.g., 12/25)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cvv = _cvvController.text.trim();
    if (cvv.length < 3 || cvv.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid CVV (3-4 digits)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cardNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the cardholder name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentResult = await PaymentService.processPayment(
        amount: _bookingCost.total,
        currency: 'USD',
        paymentMethod: {
          'cardNumber': cardNumber,
          'expiry': expiry,
          'cvv': cvv,
          'cardName': _cardNameController.text.trim(),
        },
      );

      if (paymentResult.success && paymentResult.paymentId != null) {
        final authService = AuthService();
        final user = authService.currentUser;
        
        if (user != null) {
          final bookingId = await _bookingService.createBooking(
            userId: user.uid,
            roomId: widget.room.id,
            roomName: widget.room.name,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            guests: widget.guests,
            eventType: widget.eventType,
            eventDetails: widget.eventDetails,
            specialRequests: widget.specialRequests,
            roomPrice: _bookingCost.roomCost,
            eventFee: _bookingCost.eventFee,
            subtotal: _bookingCost.subtotal,
            tax: _bookingCost.tax,
            discount: _bookingCost.discount,
            total: _bookingCost.total,
            paymentId: paymentResult.paymentId,
            isPaid: true,
          );

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => BookingSuccessPage(bookingId: bookingId),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberOfNights = widget.checkOut.difference(widget.checkIn).inDays;

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
                child: Image.asset(
                  'assets/icons/LOGO2.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Booking Confirmation',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.hotel,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.room.name,
                          style: AppTheme.heading3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDetailChip(
                        icon: Icons.calendar_today,
                        label: 'Check-in',
                        value: _dateFormat.format(widget.checkIn),
                      ),
                      const SizedBox(width: 12),
                      _buildDetailChip(
                        icon: Icons.calendar_today,
                        label: 'Check-out',
                        value: _dateFormat.format(widget.checkOut),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildDetailChip(
                        icon: Icons.bed,
                        label: 'Nights',
                        value: '$numberOfNights',
                      ),
                      const SizedBox(width: 12),
                      _buildDetailChip(
                        icon: Icons.people,
                        label: 'Guests',
                        value: '${widget.guests}',
                      ),
                    ],
                  ),
                  if (widget.eventType != EventType.none) ...[
                    const SizedBox(height: 12),
                    _buildDetailChip(
                      icon: Icons.celebration,
                      label: 'Event Type',
                      value: Booking.getEventTypeDisplay(widget.eventType),
                      isHighlighted: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
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
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cost Breakdown',
                        style: AppTheme.heading3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCostItem(
                    label: 'Room (${numberOfNights} nights)',
                    amount: _bookingCost.roomCost,
                    isBold: false,
                  ),
                  if (_bookingCost.eventFee > 0) ...[
                    _buildCostItem(
                      label: 'Event Fee',
                      amount: _bookingCost.eventFee,
                      isBold: false,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildCostItem(
                    label: 'Subtotal',
                    amount: _bookingCost.subtotal,
                    isBold: true,
                  ),
                  if (_bookingCost.discount > 0) ...[
                    _buildCostItem(
                      label: 'Discount (${(_bookingCost.discountRate * 100).toStringAsFixed(0)}%)',
                      amount: -_bookingCost.discount,
                      isDiscount: true,
                    ),
                  ],
                  _buildCostItem(
                    label: 'Tax (10%)',
                    amount: _bookingCost.tax,
                    isBold: false,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₱${_bookingCost.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.credit_card,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payment Details',
                        style: AppTheme.heading3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _cardNameController,
                    decoration: AppTheme.textFieldDecoration.copyWith(
                      labelText: 'Cardholder Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    decoration: AppTheme.textFieldDecoration.copyWith(
                      labelText: 'Card Number',
                      hintText: '1234 5678 9012 3456',
                      counterText: '',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            labelText: 'Expiry (MM/YY)',
                            hintText: '12/25',
                            counterText: '',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                          ],
                          onChanged: (value) {
                            if (value.length == 2 && !value.contains('/')) {
                              _expiryController.value = TextEditingValue(
                                text: '$value/',
                                selection: TextSelection.collapsed(offset: 3),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          decoration: AppTheme.textFieldDecoration.copyWith(
                            labelText: 'CVV',
                            hintText: '123',
                            counterText: '',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                onPressed: _isProcessing ? null : _processPayment,
                style: AppTheme.gradientButtonStyle.copyWith(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pay ₱${_bookingCost.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.lock, size: 20),
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
                    Icons.security,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is secure and encrypted',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted ? AppTheme.accentColor.withOpacity(0.1) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isHighlighted ? AppTheme.accentColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTheme.caption.copyWith(
                    color: isHighlighted ? AppTheme.accentColor : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighlighted ? AppTheme.accentColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem({
    required String label,
    required double amount,
    bool isBold = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)
                : AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          Text(
            '${isDiscount ? '-' : ''}₱${amount.toStringAsFixed(2)}',
            style: (isBold
                ? AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600)
                : AppTheme.bodyMedium).copyWith(
              color: isDiscount ? AppTheme.successColor : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingSuccessPage extends StatelessWidget {
  final String bookingId;

  const BookingSuccessPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your booking has been confirmed successfully.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Booking ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookingId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate to bookings page
                  },
                  child: Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}