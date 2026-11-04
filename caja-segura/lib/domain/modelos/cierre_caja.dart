class CierreCaja {
  const CierreCaja({
    required this.id,
    required this.fecha,
    required this.esperadoCentavos,
    required this.contadoCentavos,
    required this.reservaCentavos,
    required this.nota,
  });
  final String id;
  final DateTime fecha;
  final int esperadoCentavos;
  final int contadoCentavos;
  final int reservaCentavos;
  final String nota;
  int get diferenciaCentavos => contadoCentavos - esperadoCentavos;
}

class SaldoCambioException implements Exception {
  const SaldoCambioException();
  @override
  String toString() =>
      'El saldo cambió. Revisa el nuevo saldo y confirma otra vez.';
}
