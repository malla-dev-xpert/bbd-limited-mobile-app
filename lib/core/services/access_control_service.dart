import 'package:bbd_limited/models/user.dart';
import 'package:bbd_limited/routes.dart';

class AccessControlService {
  static const String branchChina = 'Chine';
  static const String branchCongo = 'Congo';
  static const String branchMali = 'Mali';

  /// Rôle opérationnel limité : Profil, Conteneurs, Liste des items (confirm only).
  static const String roleEmployeD = 'EMPLOYE_D';

  // Singleton pattern
  static final AccessControlService _instance =
      AccessControlService._internal();

  factory AccessControlService() {
    return _instance;
  }

  AccessControlService._internal();

  /// Vérifie si l'utilisateur a le rôle EMPLOYE_D (comparaison insensible à la casse).
  bool isEmployeD(User? user) {
    if (user == null) return false;
    final name = user.role?.name ?? user.roleName ?? '';
    return name.toUpperCase() == roleEmployeD;
  }

  /// Routes autorisées pour EMPLOYE_D : Profil, Conteneur, Liste items, CBM Pricing, Sales (New purchase + History uniquement).
  static const Set<String> _allowedRoutesForEmployeD = {
    Routes.login,
    Routes.forgotPassword,
    Routes.main,
    Routes.home,
    Routes.containers,
    Routes.itemsList,
    Routes.cbmPricing,
    Routes.sales,
    Routes.purchase,
  };

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
    Routes.partners,
    Routes.devises,
    Routes.warehouse,
    Routes.accounts,
  };

  /// Vérifie si l'utilisateur peut naviguer vers une route donnée
  bool canAccessRoute(User? user, String routeName) {
    if (user == null) return false;

    if (isEmployeD(user)) {
      return _allowedRoutesForEmployeD.contains(routeName);
    }

    if (isChina(user)) {
      return true; // Accès complet
    }

    if (isRestrictedBranch(user)) {
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

  /// Vérifie si l'utilisateur peut voir l'onglet Sales (EMPLOYE_D : accès limité à New purchase + History).
  bool canShowSalesTab(User user) {
    if (isEmployeD(user)) return true;
    if (isRestrictedBranch(user)) return false;
    return true;
  }

  /// Vérifie si l'utilisateur peut voir l'onglet Admin
  bool canShowAdminTab(User user) {
    if (isEmployeD(user)) return false;
    if (user.role != null && user.role!.permissions.contains('IS_ADMIN')) {
      if (isRestrictedBranch(user)) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// EMPLOYE_D ne voit pas l’onglet Comptes
  bool canShowAccountsTab(User user) {
    if (isEmployeD(user)) return false;
    return true;
  }

  /// Vérifie si l'utilisateur peut supprimer un paiement (Admin seulement)
  bool canDeletePayment(User user) {
    return user.role?.permissions.contains('IS_ADMIN') ?? false;
  }

  // ——— Conteneurs : EMPLOYE_D a les mêmes permissions que l'admin (tous les frais, même UX/UI) ———
  bool canShowContainerFee(User? user, String feeType) {
    if (user == null) return true;
    return true; // EMPLOYE_D comme admin : tous les types de frais
  }

  // ——— Items : EMPLOYE_D peut modifier et supprimer comme l'admin ———
  bool canEditItem(User? user) {
    if (user == null) return false;
    return true;
  }

  bool canDeleteItem(User? user) {
    if (user == null) return false;
    return true; // EMPLOYE_D comme admin : peut supprimer
  }

  bool canConfirmItemDelivery(User? user) {
    if (user == null) return false;
    return true; // EMPLOYE_D peut confirmer
  }
}
