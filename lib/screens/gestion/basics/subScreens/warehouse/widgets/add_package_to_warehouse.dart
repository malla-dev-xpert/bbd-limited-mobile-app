import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/add_package_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/providers/package_provider.dart';
import 'package:provider/provider.dart';

Future<bool?> showAddPackageModal(BuildContext context, int warehouseId) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return ChangeNotifierProvider(
        create: (_) => PackageProvider(),
        child: Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: AddPackageForm(warehouseId: warehouseId),
        ),
      );
    },
  );
}
