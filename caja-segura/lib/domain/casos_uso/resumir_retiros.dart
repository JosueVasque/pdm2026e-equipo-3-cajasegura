import '../modelos/movimiento.dart';
import 'generar_reporte.dart';

class ResumenRetiros {
  const ResumenRetiros(this.retiros, this.totalCentavos);
  final List<Movimiento> retiros;
  final int totalCentavos;
}

ResumenRetiros resumirRetiros(
  List<Movimiento> movimientos, {
  RangoReporte? rango,
}) {
  final retiros =
      movimientos
          .where(
            (m) =>
                m.esRetiro &&
                m.esEmpresa &&
                !m.esIngreso &&
                (rango == null || rango.contiene(m.fecha)),
          )
          .toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
  return ResumenRetiros(
    List.unmodifiable(retiros),
    retiros.fold<int>(0, (s, m) => s + (m.monto * 100).round()),
  );
}
