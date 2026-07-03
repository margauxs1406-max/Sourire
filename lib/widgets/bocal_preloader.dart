import 'package:flutter/material.dart';
import 'package:sourire/theme/tokens.dart';

/// Enveloppe ton écran d'accueil (ou ton MaterialApp) pour garantir que
/// l'image du bocal est entièrement décodée et en cache AVANT que quoi
/// que ce soit ne s'affiche — élimine le flash "pastilles avant bocal"
/// quel que soit le nombre de souvenirs ajoutés ou le moment où l'app
/// est relancée.
///
/// Utilisation dans ton MaterialApp :
/// ```dart
/// MaterialApp(
///   home: BocalPreloader(child: ScreenHome()),
///   // ...
/// )
/// ```
class BocalPreloader extends StatefulWidget {
  final Widget child;
  const BocalPreloader({super.key, required this.child});

  @override
  State<BocalPreloader> createState() => _BocalPreloaderState();
}

class _BocalPreloaderState extends State<BocalPreloader> {
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      precacheImage(const AssetImage('assets/bocal_new.png'), context).then((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Fond de la même couleur que ta home : la transition est invisible,
      // on ne voit jamais d'écran blanc ou de spinner disgracieux.
      return const Scaffold(
        backgroundColor: orange,
        body: SizedBox.shrink(),
      );
    }
    return widget.child;
  }
}