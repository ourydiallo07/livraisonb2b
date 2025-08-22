class CurrencyConfig {
  static const String currencyCode = 'GNF';
  static const String currencySymbol = 'GNF';

  static String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} $currencySymbol';
  }
}
