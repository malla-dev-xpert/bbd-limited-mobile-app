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

  /// Routes autorisées pour EMPLOYE_D : uniquement Profil, Conteneur, Liste items (items-list). Pas SalesHomeScreen (/sales).
  static const Set<String> _allowedRoutesForEmployeD = {
    Routes.login,
    Routes.forgotPassword,
    Routes.main,
    Routes.home,
    Routes.containers,
    Routes.itemsList,
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

  /// Vérifie si l'utilisateur peut voir l'onglet Statistiques (Sales) / Liste des items
  bool canShowSalesTab(User user) {
    if (isEmployeD(user)) return false; // EMPLOYE_D utilise uniquement /items-list depuis l'accueil
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

  // ——— Conteneurs : frais visibles pour EMPLOYE_D ———
  /// Types de frais autorisés pour EMPLOYE_D : uniquement locationFee et otherFees (otherwiseFees).
  static const Set<String> allowedFeeTypesForEmployeD = {'locationFee', 'otherFees'};

  bool canShowContainerFee(User? user, String feeType) {
    if (user == null) return true;
    if (isEmployeD(user)) {
      return allowedFeeTypesForEmployeD.contains(feeType);
    }
    return true;
  }

  // ——— Items : EMPLOYE_D peut confirmer réception, pas modifier/supprimer ———
  bool canEditItem(User? user) {
    if (user == null) return false;
    return !isEmployeD(user);
  }

  bool canDeleteItem(User? user) {
    if (user == null) return false;
    return !isEmployeD(user);
  }

  bool canConfirmItemDelivery(User? user) {
    if (user == null) return false;
    return true; // EMPLOYE_D peut confirmer
  }
}
