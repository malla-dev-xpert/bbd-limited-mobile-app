import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class ErrorMessages {
  static String getErrorMessage(BuildContext context, String key,
      [Map<String, String>? params]) {
    final localizations = AppLocalizations.of(context);

    if (params != null) {
      String message = localizations.translate(key);
      params.forEach((paramKey, paramValue) {
        message = message.replaceAll('{$paramKey}', paramValue);
      });
      return message;
    }

    return localizations.translate(key);
  }

  static String getSuccessMessage(BuildContext context, String key,
      [Map<String, String>? params]) {
    final localizations = AppLocalizations.of(context);

    if (params != null) {
      String message = localizations.translate(key);
      params.forEach((paramKey, paramValue) {
        message = message.replaceAll('{$paramKey}', paramValue);
      });
      return message;
    }

    return localizations.translate(key);
  }

  // Messages d'erreur communs
  static String networkError(BuildContext context) =>
      getErrorMessage(context, 'network_error');
  static String serverError(BuildContext context) =>
      getErrorMessage(context, 'server_error');
  static String unauthorized(BuildContext context) =>
      getErrorMessage(context, 'unauthorized');
  static String forbidden(BuildContext context) =>
      getErrorMessage(context, 'forbidden');
  static String notFound(BuildContext context) =>
      getErrorMessage(context, 'not_found');
  static String timeout(BuildContext context) =>
      getErrorMessage(context, 'timeout');
  static String unknownError(BuildContext context) =>
      getErrorMessage(context, 'unknown_error');

  // Messages de succès communs
  static String savedSuccessfully(BuildContext context) =>
      getSuccessMessage(context, 'saved_successfully');
  static String deletedSuccessfully(BuildContext context) =>
      getSuccessMessage(context, 'deleted_successfully');
  static String createdSuccessfully(BuildContext context) =>
      getSuccessMessage(context, 'created_successfully');
  static String updatedSuccessfully(BuildContext context) =>
      getSuccessMessage(context, 'updated_successfully');

  // Messages spécifiques aux partenaires
  static String partnerCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'partner_created_success');
  static String partnerUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'partner_updated_success');
  static String partnerDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'partner_deleted_success');
  static String errorCreatingPartner(BuildContext context) =>
      getErrorMessage(context, 'error_creating_partner');
  static String errorUpdatingPartner(BuildContext context) =>
      getErrorMessage(context, 'error_updating_partner');
  static String errorDeletingPartner(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_partner');

  // Messages spécifiques aux utilisateurs
  static String userCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'user_created_success');
  static String userUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'user_updated_success');
  static String userDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'user_deleted_success');
  static String errorCreatingUser(BuildContext context) =>
      getErrorMessage(context, 'error_creating_user');
  static String errorUpdatingUser(BuildContext context) =>
      getErrorMessage(context, 'error_updating_user');
  static String errorDeletingUser(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_user');

  // Messages spécifiques aux achats
  static String purchaseCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'purchase_created_success');
  static String purchaseUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'purchase_updated_success');
  static String purchaseDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'purchase_deleted_success');
  static String errorCreatingPurchase(BuildContext context) =>
      getErrorMessage(context, 'error_creating_purchase');
  static String errorUpdatingPurchase(BuildContext context) =>
      getErrorMessage(context, 'error_updating_purchase');
  static String errorDeletingPurchase(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_purchase');

  // Messages spécifiques aux versements
  static String versementCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'versement_created_success');
  static String versementUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'versement_updated_success');
  static String versementDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'versement_deleted_success');
  static String errorCreatingVersement(BuildContext context) =>
      getErrorMessage(context, 'error_creating_versement');
  static String errorUpdatingVersement(BuildContext context) =>
      getErrorMessage(context, 'error_updating_versement');
  static String errorDeletingVersement(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_versement');

  // Messages spécifiques aux colis
  static String packageCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'package_created_success');
  static String packageUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'package_updated_success');
  static String packageDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'package_deleted_success');
  static String errorCreatingPackage(BuildContext context) =>
      getErrorMessage(context, 'error_creating_package');
  static String errorUpdatingPackage(BuildContext context) =>
      getErrorMessage(context, 'error_updating_package');
  static String errorDeletingPackage(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_package');

  // Messages spécifiques aux conteneurs
  static String containerCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'container_created_success');
  static String containerUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'container_updated_success');
  static String containerDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'container_deleted_success');
  static String errorCreatingContainer(BuildContext context) =>
      getErrorMessage(context, 'error_creating_container');
  static String errorUpdatingContainer(BuildContext context) =>
      getErrorMessage(context, 'error_updating_container');
  static String errorDeletingContainer(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_container');

  // Messages spécifiques aux entrepôts
  static String warehouseCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'warehouse_created_success');
  static String warehouseUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'warehouse_updated_success');
  static String warehouseDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'warehouse_deleted_success');
  static String errorCreatingWarehouse(BuildContext context) =>
      getErrorMessage(context, 'error_creating_warehouse');
  static String errorUpdatingWarehouse(BuildContext context) =>
      getErrorMessage(context, 'error_updating_warehouse');
  static String errorDeletingWarehouse(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_warehouse');

  // Messages spécifiques aux ports
  static String harborCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'harbor_created_success');
  static String harborUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'harbor_updated_success');
  static String harborDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'harbor_deleted_success');
  static String errorCreatingHarbor(BuildContext context) =>
      getErrorMessage(context, 'error_creating_harbor');
  static String errorUpdatingHarbor(BuildContext context) =>
      getErrorMessage(context, 'error_updating_harbor');
  static String errorDeletingHarbor(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_harbor');

  // Messages spécifiques aux devises
  static String deviceCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'device_created_success');
  static String deviceUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'device_updated_success');
  static String deviceDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'device_deleted_success');
  static String errorCreatingDevice(BuildContext context) =>
      getErrorMessage(context, 'error_creating_device');
  static String errorUpdatingDevice(BuildContext context) =>
      getErrorMessage(context, 'error_updating_device');
  static String errorDeletingDevice(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_device');

  // Messages spécifiques aux articles
  static String itemCreatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'item_created_success');
  static String itemUpdatedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'item_updated_success');
  static String itemDeletedSuccess(BuildContext context) =>
      getSuccessMessage(context, 'item_deleted_success');
  static String errorCreatingItem(BuildContext context) =>
      getErrorMessage(context, 'error_creating_item');
  static String errorUpdatingItem(BuildContext context) =>
      getErrorMessage(context, 'error_updating_item');
  static String errorDeletingItem(BuildContext context) =>
      getErrorMessage(context, 'error_deleting_item');
}
