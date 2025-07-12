class OrderStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static const List<String> values = [
    pending,
    processing,
    shipped,
    delivered,
    cancelled,
  ];
}
