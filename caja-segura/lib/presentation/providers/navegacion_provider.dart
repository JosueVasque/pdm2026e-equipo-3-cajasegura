import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavegacionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void cambiar(int indice) => state = indice;
}

final navegacionProvider = NotifierProvider<NavegacionNotifier, int>(
  NavegacionNotifier.new,
);
