import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/routes.dart';

class AccessControlService {
  static const String branchChina = 'Chine';
  static const String branchCongo = 'Congo';
  static const String branchMali = 'Mali';

  // Singleton pattern
  static final AccessControlService _instance =
      AccessControlService._internal();

  factory AccessControlService() {
    return _instance;
  }

  AccessControlService._internal();

  /// Vérifie si l'utilisateur appartient à la branche Chine
  bool isChina(User user) => user.branchName == branchChina;

  /// Vérifie si l'utilisateur appartient aux branches restreintes (Congo, Mali)
  bool isRestrictedBranch(User user) =>
      user.branchName == branchCongo || user.branchName == branchMali;

  /// Liste des routes accessibles pour les branches restreintes
  static const Set<String> _allowedRoutesForRestricted = {
    Routes.login,
    Routes.forgotPassword,
    Routes.main,
    Routes.home,
  };

  /// Vérifie si l'utilisateur peut naviguer vers une route donnée
  bool canAccessRoute(User user, String routeName) {
    if (isChina(user)) {
      return true; // Accès complet
    }

    if (isRestrictedBranch(user)) {
      // Vérifier si la route est explicitement autorisée
      if (_allowedRoutesForRestricted.contains(routeName)) {
        return true;
      }
      return false;
    }

    return true;
  }

  /// Vérifie si l'utilisateur peut voir les options dans Basic Home
  bool canShowBasicHomeOptions(User user) {
    if (isRestrictedBranch(user)) {
      return false;
    }
    return true;
  }

  /// Vérifie si l'utilisateur peut voir l'onglet Statistiques (Sales)
  bool canShowSalesTab(User user) {
    if (isRestrictedBranch(user)) {
      return false;
    }
    return true;
  }

  /// Vérifie si l'utilisateur peut voir l'onglet Admin
  bool canShowAdminTab(User user) {
    // Règle existante: Basée sur le rôle
    if (user.role != null && user.role!.permissions.contains('IS_ADMIN')) {
      if (isRestrictedBranch(user)) {
        return false;
      }
      return true;
    }
    return false;
  }
}
