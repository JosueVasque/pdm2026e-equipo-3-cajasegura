import 'package:flutter/material.dart';

/// Estado común de lectura, error y reintento para los datos locales.
class CargaDatos<T> extends StatelessWidget {
  const CargaDatos({
    super.key,
    required this.future,
    required this.onReintentar,
    required this.builder,
  });

  final Future<T> future;
  final VoidCallback onReintentar;
  final Widget Function(T datos) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No se pudieron cargar los datos guardados.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onReintentar,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }
      return builder(snapshot.data as T);
    },
  );
}
