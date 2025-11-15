import '../models/booking.dart';

class PaymentService {
  // Tax rate (e.g., 10% tax)
  static const double taxRate = 0.10;
  
  // Discount rates based on event type
  static final Map<EventType, double> eventDiscounts = {
    EventType.none: 0.0,
    EventType.birthday: 0.05, // 5% discount
    EventType.anniversary: 0.10, // 10% discount
    EventType.wedding: 0.15, // 15% discount
    EventType.corporate: 0.08, // 8% discount
    EventType.graduation: 0.05, // 5% discount
    EventType.other: 0.0,
  };

  // Event fees based on event type
  static final Map<EventType, double> eventFees = {
    EventType.none: 0.0,
    EventType.birthday: 50.0,
    EventType.anniversary: 75.0,
    EventType.wedding: 500.0,
    EventType.corporate: 200.0,
    EventType.graduation: 30.0,
    EventType.other: 100.0,
  };

  // Calculate booking cost
  static BookingCost calculateCost({
    required double roomPricePerNight,
    required int numberOfNights,
    required EventType eventType,
    required int guests,
  }) {
    // Room cost
    final double roomCost = roomPricePerNight * numberOfNights;

    // Event fee
    final double eventFee = eventFees[eventType] ?? 0.0;

    // Subtotal (room + event fee)
    final double subtotal = roomCost + eventFee;

    // Discount
    final double discountRate = eventDiscounts[eventType] ?? 0.0;
    final double discount = subtotal * discountRate;

    // Subtotal after discount
    final double subtotalAfterDiscount = subtotal - discount;

    // Tax (applied to subtotal after discount)
    final double tax = subtotalAfterDiscount * taxRate;

    // Total
    final double total = subtotalAfterDiscount + tax;

    return BookingCost(
      roomCost: roomCost,
      eventFee: eventFee,
      subtotal: subtotal,
      discount: discount,
      subtotalAfterDiscount: subtotalAfterDiscount,
      tax: tax,
      total: total,
      discountRate: discountRate,
    );
  }

  // Process payment (mock implementation - replace with actual payment gateway)
  static Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required Map<String, dynamic> paymentMethod,
  }) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Mock payment - in production, integrate with Stripe, PayPal, etc.
    // For now, always return success for demonstration
    final String paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    return PaymentResult(
      success: true,
      paymentId: paymentId,
      message: 'Payment processed successfully',
    );
  }
}

class BookingCost {
  final double roomCost;
  final double eventFee;
  final double subtotal;
  final double discount;
  final double subtotalAfterDiscount;
  final double tax;
  final double total;
  final double discountRate;

  BookingCost({
    required this.roomCost,
    required this.eventFee,
    required this.subtotal,
    required this.discount,
    required this.subtotalAfterDiscount,
    required this.tax,
    required this.total,
    required this.discountRate,
  });
}

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String message;

  PaymentResult({
    required this.success,
    this.paymentId,
    required this.message,
  });
}
