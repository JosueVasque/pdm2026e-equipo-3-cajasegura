import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navegacion_provider.dart';
import 'caja_negocio_screen.dart';
import 'historial_screen.dart';
import 'categorias_screen.dart';
import 'reportes_screen.dart';

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
          CategoriasScreen(),
          ReportesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: ref.read(navegacionProvider.notifier).cambiar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categorías',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
