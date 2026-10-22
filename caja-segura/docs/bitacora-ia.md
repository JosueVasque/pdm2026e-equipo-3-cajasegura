# Bitácora de IA - Laboratorio 4

Fecha: 22 de octubre de 2026.

## Solicitud
Implementar los requisitos de Lab4 E en CajaSegura con cambios sencillos y explicar cómo subirlos.

## Aceptado
- Notifier para pestaña activa e IndexedStack con Inicio, Historial y Ajustes (Próximamente).
- Ver historial e Ir a mi caja cambian el provider, sin callbacks de navegación por constructor.
- Filtro inmutable en Notifier. historialProvider observa el filtro y consulta nuevamente el repositorio al cambiarlo.
- Dismissible con ValueKey del ID. confirmDismiss espera el borrado en SQLite; un fallo mantiene la fila.
- Deshacer inserta el mismo objeto Movimiento, conservando ID, fecha, importe, tipo y ámbito.
- Pruebas de filtro, navegación, borrado, restauración, fallo y persistencia real en SQLite.

## Corregido o descartado
- Se sustituyó el filtrado local con setState por el provider dependiente solicitado.
- Se corrigió la codificación de los archivos nuevos y un identificador con ñ que Dart rechazó.
- Se conservaron las pantallas y SQLite existentes; no se añadieron router, paquetes, edición de registros ni una nueva arquitectura.
- Borrar un movimiento del historial no cambia el saldo de caja, igual que registrar un movimiento en el repositorio existente.

## Validación
Ejecutar dart format --output=none --set-exit-if-changed lib test, flutter analyze y flutter test.
La revisión de otra pareja, capturas en dispositivo, PR y CI remoto deben completarse en GitHub.

Resultado local: formato correcto, análisis sin advertencias y 15 pruebas aprobadas. Se corrigió el desbordamiento de Inicio con ListView.
