# Pruebas de la app con usuarios

## Estado de la evidencia

Hallazgos comunicados por el equipo el 2026-11-04 a partir de la prueba de la app.
Se reportaron funciones faltantes y un problema de fluidez, sin un fallo que
detuviera la aplicación. Las tareas de la tabla se reconstruyen a partir de ese
reporte; no son una transcripción de la sesión.

No se proporcionaron fecha de la sesión, participantes, dispositivo ni versión
probada. La entrevista con Maria Yax mencionada en el
[README](../README.md#evidencia-disponible) es evidencia del problema de negocio;
no se atribuyen estos hallazgos a esa persona sin confirmación.

## Qué intentaron, qué falló y qué PR lo arregló

| Hallazgo | Qué intentaron | Qué falló | Corrección y PR | Estado |
|---|---|---|---|---|
| U-01: filtros por fecha | Consultar movimientos de un período específico en Historial. | Faltaba filtrar por fecha; los filtros existentes no permitían acotar el período. | Se añadieron Hoy, Esta semana, Este mes y rango personalizado, combinables con tipo y ámbito. [PR #25](https://github.com/JosueVasque/pdm2026e-equipo-3-cajasegura/pull/25). | Corregido en código; pendiente de validar nuevamente con usuarios. |
| U-02: asignación de categorías | Clasificar un movimiento con una categoría desde la interfaz. | Se podían crear categorías, pero no asignarlas a un movimiento desde la interfaz. | Se incorporó la selección de categoría al registrar movimientos y la asignación o cambio desde Historial para movimientos no conciliados. [PR #25](https://github.com/JosueVasque/pdm2026e-equipo-3-cajasegura/pull/25). | Corregido en código; pendiente de validar nuevamente con usuarios. |
| U-03: parpadeo del Historial | Alternar entre Todos, Ingresos y Gastos. | La vista parpadeaba al cambiar el filtro, afectando la fluidez de consulta. | Se separó la carga asíncrona del filtrado en memoria para mantener los controles y evitar nuevas consultas a SQLite al cambiar la selección. [PR #25](https://github.com/JosueVasque/pdm2026e-equipo-3-cajasegura/pull/25). | Corregido en código; pendiente de validar nuevamente con usuarios. |

Los vínculos al PR se identificaron en el historial Git local: el commit
`563d77d` corresponde al PR #25 y contiene las tres mejoras. El PR #24
(`d1a4366`) incorporó el CRUD de categorías; la asignación desde Historial se
añadió posteriormente en el PR #25.

## Verificación técnica disponible

- U-01: [pruebas de fechas del Historial](../caja-segura/test/filtro_fechas_historial_test.dart).
- U-02: [pruebas de operaciones desde la interfaz](../caja-segura/test/operaciones_widget_test.dart).
- U-03: [prueba que conserva los controles sin recargar SQLite](../caja-segura/test/historial_screen_test.dart).

La [bitácora de implementación](../caja-segura/docs/bitacora-ia.md) describe estas
mejoras. Las pruebas automatizadas respaldan el comportamiento técnico; la
confirmación de que las dificultades desaparecieron requiere repetir las tareas
con usuarios. No se ejecutaron estas pruebas al actualizar este documento.

## Guion para la próxima sesión

Usar datos de prueba y registrar versión o commit, fecha, dispositivo/plataforma,
facilitador y un identificador del participante. Pedir consentimiento antes de
grabar; evitar publicar datos financieros o personales sensibles.

| Caso | Qué se pide intentar | Resultado esperado | Resultado observado |
|---|---|---|---|
| U-01 | Consultar el efectivo y verificar un retiro de sueldo. Probar también un importe que afecte la reserva. | Comprende cuánto puede retirar; la app protege la reserva al confirmar. | Pendiente de sesión. |
| U-02 | Registrar un ingreso de empresa y encontrarlo en Historial usando filtros de fecha, tipo y ámbito. | Encuentra el registro y entiende los totales filtrados. | Pendiente de sesión. |
| U-03 | Navegar de Inicio a Historial, Categorías y Reportes, y regresar a Historial. | Localiza las pantallas y conserva la selección del Historial. | Pendiente de sesión. |

Observar primero sin indicar qué botón tocar. Anotar si completa la tarea sin
ayuda, con ayuda o no la completa, junto con la dificultad concreta y cualquier
comentario del participante.

## Validación posterior de las correcciones

Repetir específicamente U-01, U-02 y U-03 y registrar fecha, versión, dispositivo,
participante, resultado y ayuda requerida. En U-03 comprobar también visualmente
que ya no aparece el parpadeo. Conservar una nota o captura autorizada por hallazgo.

| Hallazgo | Fecha / versión / dispositivo | Resultado observado después de la corrección |
|---|---|---|
| U-01 | Pendiente | Pendiente de nueva prueba con usuarios. |
| U-02 | Pendiente | Pendiente de nueva prueba con usuarios. |
| U-03 | Pendiente | Pendiente de nueva prueba con usuarios. |
