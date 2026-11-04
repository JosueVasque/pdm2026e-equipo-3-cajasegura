import 'package:flutter/material.dart';

/// Identidad visual compartida por las pantallas de CajaSegura.
abstract final class CajaEstilo {
  static const tinta = Color(0xFF1B1E23);
  static const menta = Color(0xFF57EDB1);
  static const verde = Color(0xFF087F64);
  static const turquesa = Color(0xFF05BFA7);
  static const fondo = Color(0xFFF3F5F4);
  static const gris = Color(0xFF69736F);
  static const borde = Color(0xFFE5EAE7);
  static const peligro = Color(0xFFB84444);
  static const gradiente = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [menta, turquesa],
  );

  static ThemeData get tema {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: verde,
        primary: verde,
        secondary: menta,
        surface: Colors.white,
        onSurface: tinta,
        error: peligro,
      ),
    );
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: tinta, displayColor: tinta)
          .copyWith(
            headlineLarge: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
              color: tinta,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: tinta,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: tinta,
            ),
            titleMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tinta,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.5,
              color: gris,
            ),
            labelLarge: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          )
          .apply(fontFamily: 'Roboto'),
      appBarTheme: const AppBarTheme(
        backgroundColor: tinta,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
        titleSpacing: 24,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: menta,
          foregroundColor: tinta,
          disabledBackgroundColor: borde,
          minimumSize: const Size(0, 56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tinta,
          minimumSize: const Size(0, 54),
          shape: const StadiumBorder(),
          side: const BorderSide(color: borde),
          backgroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: verde),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: tinta,
        foregroundColor: menta,
        elevation: 2,
        shape: StadiumBorder(),
        extendedPadding: EdgeInsets.symmetric(horizontal: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        labelStyle: const TextStyle(fontFamily: 'Roboto', color: gris),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: verde, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        height: 76,
        indicatorColor: menta,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? tinta : gris,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? tinta : gris,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: tinta,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? tinta : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? Colors.white : gris,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: borde)),
          shape: WidgetStatePropertyAll(forma),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tinta,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: gris,
        ),
      ),
      dividerTheme: const DividerThemeData(color: borde, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tinta,
        actionTextColor: menta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: fondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: verde,
        linearTrackColor: borde,
      ),
    );
  }
}

class IconoCaja extends StatelessWidget {
  const IconoCaja(
    this.icono, {
    super.key,
    this.oscuro = false,
    this.tamano = 46,
  });
  final IconData icono;
  final bool oscuro;
  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      color: oscuro
          ? CajaEstilo.tinta
          : CajaEstilo.menta.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(
      icono,
      size: tamano * 0.48,
      color: oscuro ? CajaEstilo.menta : CajaEstilo.verde,
    ),
  );
}

/// Superficie con esquinas superiores redondeadas, sobre el encabezado oscuro.
class SuperficieCaja extends StatelessWidget {
  const SuperficieCaja({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CajaEstilo.tinta,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: ColoredBox(color: CajaEstilo.fondo, child: child),
    ),
  );
}
