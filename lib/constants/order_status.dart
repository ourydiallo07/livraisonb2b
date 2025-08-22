class OrderStatus {
  // Valeurs en anglais pour le backend
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  // Traductions en français pour l'UI
  static String getFrenchTranslation(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours de traitement';
      case 'shipped':
        return 'Expédié';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  // Pour convertir du français vers l'anglais
  static String getEnglishValue(String frenchStatus) {
    switch (frenchStatus) {
      case 'En attente':
        return pending;
      case 'En cours de traitement':
        return processing;
      case 'Expédié':
        return shipped;
      case 'Livré':
        return delivered;
      case 'Annulé':
        return cancelled;
      default:
        return frenchStatus;
    }
  }

  static const List<String> values = [
    pending,
    processing,
    shipped,
    delivered,
    cancelled,
  ];
}
