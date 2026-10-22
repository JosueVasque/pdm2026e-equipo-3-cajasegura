import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pantallas/principal_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Riverpod 3 reintenta solo los providers que fallan; eso esconde el estado
  // de error y el botón Reintentar. Se desactiva para toda la app.
  runApp(ProviderScope(retry: (_, _) => null, child: const MiApp()));
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caja Segura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const PrincipalScreen(),
    );
  }
}
