import 'package:flutter/material.dart';

/// Widget wrapper qui permet de fermer le clavier en tapant sur l'écran
class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardDismissWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Fermer le clavier quand on tape sur l'écran
        FocusScope.of(context).unfocus();
      },
      // Permettre aux enfants de gérer leurs propres gestes
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
