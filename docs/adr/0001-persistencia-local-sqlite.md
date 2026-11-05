# ADR 0001: Persistencia local con SQLite

- Estado: aceptada; implementada en la aplicación actual.
- Fecha de documentación: 2026-11-04.
- Alcance: caja, movimientos, categorías, frecuentes, cierres y trazabilidad.

## Contexto

CajaSegura necesita conservar las operaciones al cerrar y abrir la app. Registrar
un movimiento o confirmar un retiro también cambia el saldo: ambas escrituras
deben completarse juntas para evitar inconsistencias. El MVP no dispone de un
servidor ni de cuentas para sincronizar información.

## Decisión

Guardar los datos en SQLite mediante repositorios asíncronos en la capa de datos.
Usar `sqflite` en Android/iOS y `sqflite_common_ffi_web` en web, seleccionados
mediante imports condicionales. En web, SQLite se ejecuta con WebAssembly y
persiste en IndexedDB.

Aplicar transacciones a las operaciones que modifican registros y saldo. Mantener
un esquema versionado con migraciones; insertar los datos de demostración solo
al crear la base, sin sobrescribir los datos al reabrirla.

## Alternativas consideradas

| Alternativa | Motivo para no elegirla |
|---|---|
| Datos solo en memoria | Se pierden al reiniciar la aplicación. |
| Preferencias o archivos JSON | Requieren implementar manualmente relaciones, migraciones y escrituras atómicas de varias entidades. |
| Base remota con sincronización | Añade infraestructura, cuentas y resolución de conflictos fuera del alcance actual. |

## Consecuencias

- Las operaciones principales pueden realizarse sin conexión a un servidor.
- Las migraciones y transacciones requieren pruebas para conservar los datos y el saldo.
- Los datos pertenecen a la instalación; en web dependen del origen y perfil del navegador.
- No existe sincronización ni exportación/restauración propia. Borrar los datos
  de la app o del sitio puede eliminar la información.
- La web debe publicar también `sqlite3.wasm` y `sqflite_sw.js`.

## Evidencia de implementación y verificación

- [Base de datos y migraciones](../../caja-segura/lib/data/base_datos/base_datos_local.dart).
- [Conexión nativa](../../caja-segura/lib/data/base_datos/conexion_nativa.dart)
  y [conexión web](../../caja-segura/lib/data/base_datos/conexion_web.dart).
- [Pruebas de persistencia](../../caja-segura/test/base_datos_test.dart)
  y [operaciones de caja](../../caja-segura/test/operaciones_caja_test.dart).

Desde la carpeta de la app: `flutter test test/base_datos_test.dart test/operaciones_caja_test.dart`.
Estas pruebas son evidencia técnica; no sustituyen una sesión con usuarios.
