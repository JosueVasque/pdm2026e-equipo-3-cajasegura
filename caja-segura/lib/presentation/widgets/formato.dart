String dineroCentavos(int centavos) =>
    '${centavos < 0 ? '-' : ''}Q${(centavos.abs() / 100).toStringAsFixed(2)}';
String fechaHora(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
