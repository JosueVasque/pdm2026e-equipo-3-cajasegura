# CajaSegura

## Equipo 3 - Sección E

Ayudamos a pequeños comerciantes como Maria a separar su sueldo del capital 
de su negocio sin descapitalizarlo, mediante una app que verifica en tiempo 
real si el retiro es seguro.

## Problema

Maria mezcla el efectivo de sus gastos personales con el capital del negocio. 
Cuando retira dinero para su sueldo, no tiene forma clara de saber si eso 
deja suficiente para comprar los insumos de la semana, lo que le genera 
culpa y riesgo de descapitalizar el negocio.

## Usuario primario

Maria Yax, dueña de una purificadora de agua.

## Evidencia disponible

Respuestas obtenidas en entrevista directa con Maria Yax sobre su manejo 
de caja y retiros personales.

## Flujo principal (MVP)

Inicio: Maria abre la app y ve su caja disponible → acción: ingresa el 
monto que quiere retirar como sueldo → resultado: la app confirma si el 
retiro es seguro y protege la reserva de insumos.

### Sí entra al MVP
1. Ver caja disponible y reserva protegida para insumos.
2. Ingresar el monto a retirar como sueldo.
3. Confirmación de si el retiro es seguro / impacto en caja.

### No entra todavía
1. Pantalla de "Retiro exitoso".
2. Pantalla de ajuste ante riesgo de descapitalización.
3. Sincronización con un servidor o base de datos remota.

La persistencia local con SQLite ya está integrada para la caja y el historial.

### Suposición más riesgosa

Que Maria realmente confíe en la cifra que le muestra la app (en vez de su 
propio cálculo mental o el "sentir" del efectivo en caja) al momento de 
decidir cuánto retirar. Si no confía en el número, seguirá usando su método 
actual y la app no cambiará su comportamiento real.

## Integrantes

| Integrante | Carné |
|---|---|
| @JosueVasque | 202308030 |
| @JohanRRod | 202308046 |
| @Sebasorozc0 | 202308067 |
| @MarioFernandoGuzman | 202308049 |
| @ethanrestrada | 202308079 |
| @FMarvin | 202308032 |

## Roles (Semana 2)

| Rol | Responsabilidad | Integrante |
|---|---|---|
| Arquitectura | Repositorio, ramas e integración | @ethanrestrada |
| Producto / PM | Alcance, prioridad y criterios | @JosueVasque |
| UX | Interfaz y flujo de las pantallas | @JohanRRod |
| Investigación | Validación directa con el usuario (Maria) | @FMarvin |
| QA | Revisión de código contra criterios de aceptación | @Sebasorozc0 |
| Release | Evidencia, merge y cierre de issues | @MarioFernandoGuzman |

Los roles rotan semanalmente. Todos los integrantes programan, independientemente del rol asignado.

### Detalle de tareas por integrante (implementación de la arquitectura)

**@ethanrestrada — Arquitectura**
- Ejecuta `flutter create .` dentro del repositorio (issue #1).
- Crea las 3 carpetas base: `lib/presentation/`, `lib/domain/`, `lib/data/`.
- Abre la primera rama y PR de la semana, sentando la estructura para que el resto del equipo trabaje encima.
- Revisa que cada PR posterior respete los límites entre capas (por ejemplo, que `domain/` no importe nada de `package:flutter/material.dart`).

**@JosueVasque — Producto / PM**
- Decide el orden en que se implementan las 3 pantallas (issues #4, #5, #6), priorizando según lo que el equipo necesite mostrar primero.
- Da seguimiento al milestone M1, confirmando que cada issue cerrado corresponde a un criterio de aceptación cumplido.
- Redacta o ajusta la definición del modelo de datos (issue #2) en `domain/modelos/caja.dart`, en coordinación con Arquitectura.

**@JohanRRod — UX**
- Revisa cada pantalla implementada en `presentation/pantallas/` contra el prototipo en papel (Hojas 1, 2 y 3).
- Deja comentarios en las PRs de las pantallas señalando cualquier diferencia visual con el diseño original.
- No es el reviewer formal de las PRs, pero su visto bueno de fidelidad visual se registra como comentario antes del merge.

**@FMarvin — Investigación**
- Retoma el contacto con Maria para validar que el flujo de las 3 pantallas (una vez implementadas) tenga sentido para ella en la práctica.
- Documenta cualquier hallazgo nuevo de esa validación, siguiendo el mismo formato usado en el issue #8 (documentar hallazgos de la entrevista).
- Al ser integrante nuevo, no tiene tareas de código asignadas esta semana; se enfoca en evidencia de usuario.

**@Sebasorozc0 — QA**
- Revisa todas las PRs de la semana (issues #1, #2, #4, #5, #6, #7) comparándolas contra los criterios de aceptación de cada issue.
- Deja al menos un comentario por PR, aprobando o solicitando cambios según corresponda.
- No aprueba ninguna PR sin que su autor haya adjuntado la evidencia pedida (captura, video, etc.).

**@MarioFernandoGuzman — Release**
- Hace el merge de cada PR una vez que QA la aprueba.
- Cierra el issue correspondiente (verificando que el cierre automático por `Closes #N` haya funcionado).
- Actualiza el progreso del milestone M1 después de cada merge, y avisa al equipo cuando se alcancen hitos.

## Arquitectura

### Contexto

El proyecto necesita una estructura que permita escalar el MVP actual (3 
pantallas: Caja del Negocio, Retiro Personal, Impacto en Caja) hacia las 
funciones pendientes (Retiro Exitoso, Ajuste por riesgo y sincronización remota)
sin tener que reescribir código ya construido.

### Decisión

Se adopta **Clean Architecture** con 3 capas:

1. **Presentación (Presentation)**: pantallas, widgets y estado de UI. Es la única capa que conoce Flutter/Material.
2. **Dominio (Domain)**: reglas de negocio puras (ej. calcular si un retiro es seguro, proteger la reserva de insumos). No depende de Flutter ni de ninguna fuente de datos.
3. **Datos (Data)**: acceso a SQLite mediante `sqflite`. Administra la conexión, el esquema, los datos iniciales y los repositorios asíncronos, sin incorporar dependencias de persistencia en el dominio.

### Estructura de carpetas

```
lib/
├── presentation/
│   ├── pantallas/
│   │   ├── caja_negocio_screen.dart
│   │   ├── retiro_personal_screen.dart
│   │   ├── impacto_caja_screen.dart
│   │   └── historial_screen.dart
│   └── widgets/carga_datos.dart
├── domain/
│   ├── modelos/
│   │   ├── caja.dart
│   │   └── movimiento.dart
│   └── casos_uso/
│       └── verificar_retiro_seguro.dart
└── data/
    ├── base_datos/
    │   ├── base_datos_local.dart
    │   ├── datos_iniciales.dart
    │   └── mapeadores.dart
    └── repositorios/
        ├── caja_repositorio.dart
        └── movimiento_repositorio.dart
```

### Por qué esta decisión

- **Escalabilidad**: agregar las pantallas que quedaron fuera del MVP (Hojas 4 y 5) no debería requerir tocar la lógica de negocio ya construida.
- **Separación de responsabilidades**: cada capa tiene una única razón para cambiar (cambia el diseño → solo `presentation`; cambia la regla de negocio → solo `domain`; cambia la fuente de datos → solo `data`).
- **Persistencia local**: SQLite queda encapsulado en `data`; las pantallas esperan los resultados asíncronos y las reglas de negocio siguen siendo Dart puro.

### Consecuencias

- Mayor cantidad de archivos y carpetas desde el inicio, comparado con tener todo en un solo `main.dart`.
- Requiere que el equipo entienda y respete los límites entre capas al programar.
- Los widgets `Container`/`Column`/`Row` ya construidos en el prototipo se reubican dentro de `presentation/pantallas/`, sin cambios funcionales.

## Flujo de contribución

Nadie trabaja directamente en `main`. El flujo es:

`issue` → `rama` → `pull request` → `revisión` → `merge`

## Cómo correr el proyecto

```bash
flutter pub get
flutter run
```

## Persistencia local con SQLite

La aplicación crea automáticamente `caja_segura.db` al consultar los datos por
primera vez. No requiere servidor, credenciales ni conexión a Internet durante
su uso. La conexión compartida y la versión del esquema (actualmente 1) están en
`lib/data/base_datos/base_datos_local.dart`. Los cambios futuros de esquema deben
incrementar esa versión y agregar una migración `onUpgrade` que conserve los datos.

### Datos almacenados

| Tabla | Contenido |
|---|---|
| `caja` | Un registro con efectivo total y reserva de insumos. |
| `movimientos` | ID, descripción, monto, tipo (ingreso/gasto), ámbito (empresa/personal) y fecha. |

Los importes se almacenan como enteros en centavos y se convierten a los modelos
de dominio en `mapeadores.dart`. Las fechas se guardan como milisegundos desde
Unix epoch. El historial se consulta de más reciente a más antiguo.

`datos_iniciales.dart` conserva los datos de demostración originales: caja de
Q2500.00, reserva de Q1200.00 y ocho movimientos. Se insertan exclusivamente en
`onCreate`, dentro de la transacción de creación; reabrir la app no los duplica
ni sobrescribe los cambios. El saldo inicial es independiente del historial de
demostración y no se calcula sumando esos ocho movimientos.

### Repositorios y pantallas

- `CajaRepositorio.obtenerCaja()` consulta la caja y `guardarCaja(caja)` permite
  actualizar sus importes de manera persistente.
- `MovimientoRepositorio.obtenerHistorial()` consulta los movimientos y
  `registrarMovimiento(movimiento)` inserta un registro; un ID duplicado genera
  un error y no reemplaza el existente. Esta operación no modifica el saldo.
- Las operaciones retornan `Future`. Caja e Historial muestran estados de carga
  y error con reintento, manteniendo los filtros existentes.
- El flujo de retiro sigue siendo una **simulación**: verificar un monto no
  modifica la caja ni registra movimientos. Aún no existe confirmación de retiro
  ni formularios de edición de caja o alta de movimientos en la interfaz.

### Plataformas y validación

La app funciona en Android e iOS con `sqflite` y en Chrome con
`sqflite_common_ffi_web`. En móviles se usa `getDatabasesPath()`; en web se usa
SQLite compilado a WebAssembly y se persiste en IndexedDB del navegador.
La selección se realiza mediante imports condicionales en la capa de datos.
`sqflite_common_ffi` se mantiene solo como dependencia directa de desarrollo para
las pruebas locales, aunque la implementación web también lo usa internamente.

Los archivos `web/sqlite3.wasm` y `web/sqflite_sw.js` son necesarios y deben
publicarse junto con la app web. Ya están generados. Si actualizas SQLite o la
implementación web, regénéralos:

```bash
dart run sqflite_common_ffi_web:setup --force
```

Para ejecutar en Chrome utiliza siempre el mismo puerto:

```bash
flutter run -d chrome --web-port=7357
```

El almacenamiento está ligado al origen (protocolo, host y puerto) y al perfil
del navegador. Recargar conserva los datos; cambiar de puerto o borrar los datos
del sitio utiliza un almacenamiento distinto o elimina el existente. La base
web y la del teléfono son independientes: no hay sincronización entre ellas.
La implementación web está marcada como experimental por su mantenedor:
[documentación de sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web).

```bash
flutter analyze
flutter test
```

Las pruebas ejecutan SQLite real sobre archivos temporales para verificar la
creación, persistencia al reabrir, integridad y ausencia de duplicados en los
datos iniciales. También cubren carga, reintento, filtros y simulación de retiro
en las pantallas.

## Roles (Semana )

| Rol | Responsabilidad | Integrante |
|---|---|---|
| Arquitectura | Repositorio, ramas e integración | @Sebasorozc0 |
| Producto / PM | Alcance, prioridad y criterios | @JohanRRod |
| UX | Interfaz y flujo de las pantallas | @MarioFernandoGuzman |
| Investigación | Validación directa con el usuario (Maria) | @Ethan |
| QA | Revisión de código contra criterios de aceptación | @FMarvin |
| Release | Evidencia, merge y cierre de issues | @Yozue |


