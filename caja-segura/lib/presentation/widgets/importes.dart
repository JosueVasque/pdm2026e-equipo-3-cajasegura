/// Acepta quetzales con hasta dos decimales y separador punto o coma.
double? leerImporte(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(limpio)) return null;
  final valor = double.tryParse(limpio);
  if (valor == null || !valor.isFinite || valor > 999999999.99) return null;
  return valor;
}
