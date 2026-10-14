import '../../domain/modelos/caja.dart';

class CajaRepositorio {
  // Datos estáticos por ahora. A futuro: base de datos o API.
  Caja obtenerCaja() {
    return const Caja(
      efectivoTotal: 2500,
      reservaInsumos: 1200,
    );
  }
}