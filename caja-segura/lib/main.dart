import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pantallas/principal_screen.dart';
import 'presentation/tema/caja_estilo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Riverpod 3 reintenta solo los providers que fallan; eso esconde el estado
  // de error y el botón Reintentar. Se desactiva para toda la app.
  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (_) =>
          ProviderScope(retry: (_, _) => null, child: const MiApp()),
    ),
  );
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caja Segura',
      debugShowCheckedModeBanner: false,
      theme: CajaEstilo.tema,
      locale: DevicePreview.locale(context),
      builder: (context, child) => DevicePreview.appBuilder(
        context,
        ColoredBox(
          color: const Color(0xFFE3E9E5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE3E9E5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ),
      home: const PrincipalScreen(),
    );
  }
}
