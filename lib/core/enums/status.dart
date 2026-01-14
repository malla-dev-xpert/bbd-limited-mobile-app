enum Status {
  CREATE,
  DELETE,
  DISABLE,
  PENDING,
  RECEIVED,
  INPROGRESS,
  DELIVERED,
  RETRIEVE,
  DELETE_ON_CONTAINER,
  IN_CONTAINER,
  COMPLETED
}

/// Extension pour obtenir la clé de traduction d'un statut
extension StatusTranslation on Status {
  /// Retourne la clé de traduction correspondant au statut
  String getTranslationKey() {
    switch (this) {
      case Status.PENDING:
        return 'package_status_pending';
      case Status.INPROGRESS:
        return 'package_status_in_transit';
      case Status.DELIVERED:
        return 'package_status_arrived';
      case Status.RECEIVED:
        return 'package_status_delivered';
      case Status.DELETE:
      case Status.DELETE_ON_CONTAINER:
        return 'package_status_cancelled';
      default:
        return 'package_status_unknown';
    }
  }
}
