# ADR 0002: Navegación y filtros con Riverpod

- Estado: aceptada; implementada en la aplicación actual.
- Fecha de documentación: 2026-11-04.
- Alcance: pestañas principales y listado de movimientos del Historial.

## Contexto

La app permite alternar entre Inicio, Historial, Categorías y Reportes. El
Historial combina filtros por fecha, tipo y ámbito. Cambiar una selección debe
actualizar la lista y sus totales sin reemplazar los controles por una carga de
SQLite ni perder el estado de las pestañas al navegar.

## Decisión

Guardar el índice de navegación en un `Notifier` de Riverpod y mostrar las cuatro
pantallas en un `IndexedStack`. Los accesos entre Inicio e Historial cambian el
mismo provider. Los formularios y detalles se abren con `Navigator.push`.

Separar la consulta asíncrona (`historialProvider`) del filtrado síncrono
(`historialFiltradoProvider`). Representar la selección con un `FiltroHistorial`
inmutable que se reemplaza desde su `Notifier`. Filtrar en memoria y calcular los
totales sobre la misma selección. Las escrituras y Reintentar invalidan los datos;
cambiar un filtro no vuelve a consultar SQLite. Reportes mantiene filtros propios.

## Alternativas consideradas

| Alternativa | Motivo para no elegirla |
|---|---|
| Reconstruir solo la pestaña seleccionada | Desmonta las otras pantallas y dificulta conservar su estado. |
| Consultar SQLite en cada cambio de filtro | Introduce cargas innecesarias y puede interrumpir la interacción con los controles. |
| Guardar toda la selección con `setState` en la pantalla | Dispersa la coordinación del estado y dificulta probarla con providers sustituidos. |
| Incorporar un router adicional | Las pestañas y los formularios actuales se resuelven con las herramientas existentes; no hay requisito de enlaces profundos. |

## Consecuencias

- Las pestañas permanecen montadas y conservan su estado durante la navegación.
- Los filtros se combinan sin nuevas consultas; siguen disponibles si no hay resultados.
- Mantener cuatro pantallas montadas utiliza más recursos que crear una a la vez.
- El historial completo se carga en memoria. Si crece significativamente, deberá
  evaluarse paginación y filtrado en SQLite.
- Las operaciones que modifican datos deben invalidar los providers correspondientes.

## Evidencia de implementación y verificación

- [Pantalla principal](../../caja-segura/lib/presentation/pantallas/principal_screen.dart)
  y [provider de navegación](../../caja-segura/lib/presentation/providers/navegacion_provider.dart).
- [Providers del Historial](../../caja-segura/lib/presentation/providers/historial_provider.dart).
- [Pruebas de navegación](../../caja-segura/test/widget_test.dart),
  [filtros y consultas](../../caja-segura/test/historial_screen_test.dart)
  y [rangos de fecha](../../caja-segura/test/filtro_fechas_historial_test.dart).

Desde la carpeta de la app: `flutter test test/widget_test.dart test/historial_screen_test.dart test/filtro_fechas_historial_test.dart`.
Estas pruebas son evidencia técnica; no sustituyen una sesión con usuarios.
