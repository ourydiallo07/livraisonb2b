enum AppErrorType {
  network,
  notFound,
  invalidInput,
  unauthorized,
  authFailed,
  serverError,
}

class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final dynamic details;

  AppError(this.type, {this.message = '', this.details});

  @override
  String toString() =>
      message.isNotEmpty ? message : 'Une erreur est survenue (${type.name})';

  // Helper pour afficher dans l'UI
  String getUserMessage() {
    if (message.isNotEmpty) return message;

    switch (type) {
      case AppErrorType.network:
        return 'Problème de connexion internet';
      case AppErrorType.unauthorized:
        return 'Accès non autorisé';
      // ... autres cas
      default:
        return 'Erreur inattendue';
    }
  }
}
