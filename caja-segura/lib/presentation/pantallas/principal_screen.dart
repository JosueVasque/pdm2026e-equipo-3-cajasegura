import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navegacion_provider.dart';
import 'caja_negocio_screen.dart';
import 'historial_screen.dart';

class PrincipalScreen extends ConsumerWidget {
  const PrincipalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indice = ref.watch(navegacionProvider);
    return Scaffold(
      body: IndexedStack(
        index: indice,
        children: const [
          CajaNegocioScreen(),
          HistorialScreen(),
          Scaffold(body: Center(child: Text('Ajustes: Próximamente'))),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: ref.read(navegacionProvider.notifier).cambiar,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
