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
1. Pantalla independiente de "Retiro exitoso" (la confirmación ya muestra un aviso).
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
su uso. La conexión compartida y la versión del esquema (actualmente 6) están en
`lib/data/base_datos/base_datos_local.dart`. Los cambios futuros de esquema deben
incrementar esa versión y agregar una migración `onUpgrade` que conserve los datos.

### Datos almacenados

| Tabla | Contenido |
|---|---|
| `caja` | Un registro con efectivo total y reserva de insumos. |
| `movimientos` | ID, descripción, monto, tipo (ingreso/gasto), ámbito (empresa/personal) y fecha. |
| `categorias` | Nombre único e indicador de archivo; los movimientos pueden tener una categoría opcional. |

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
  `registrarMovimiento(movimiento)` registra y actualiza el saldo en una única
  transacción. Los ingresos de empresa suman y los gastos de empresa restan;
  los personales no afectan la caja. No se permite saldo negativo. Un ID
  duplicado revierte toda la operación.
- Las operaciones retornan `Future`. Caja e Historial muestran estados de carga
  y error con reintento, manteniendo los filtros existentes.
- Verificar un retiro es una simulación; **Confirmar retiro** consulta de nuevo
  el saldo y la reserva y registra un único gasto de empresa junto con el
  descuento. Si afecta la reserva, se rechaza sin guardar cambios.
- En Inicio, el lápiz permite editar efectivo y reserva, incluso con caja vacía.
  Es una corrección directa del saldo, sin movimiento automático. La reserva
  puede superar al efectivo: es una meta y lo disponible para sueldo será cero.
- En Historial, **Registrar movimiento** pide descripción, monto positivo con
  hasta dos decimales (punto o coma), tipo, ámbito, fecha y categoría opcional.
  Los gastos normales de empresa pueden utilizar la reserva para insumos.
- Tocar un movimiento permite asignar, cambiar o quitar su categoría. Las
  archivadas se conservan en el historial pero no se asignan a otros movimientos.
- Borrar un movimiento no conciliado revierte su efecto sobre la caja; Deshacer lo vuelve a aplicar.
  Ambas operaciones son transaccionales. Si revertir un ingreso deja saldo
  negativo, se conserva el movimiento y se informa el error.
- La migración a v4 añade `impacto_caja_centavos` con valor cero para todos los
  movimientos existentes. No recalcula ni modifica el saldo previo: el historial
  de demostración siempre fue independiente de la caja inicial. Los movimientos
  nuevos guardan su efecto real para poder borrarlos o restaurarlos correctamente.

### Alertas de reserva y reportes

- Inicio muestra **Reserva sin cubrir** con el faltante cuando el efectivo es
  menor que la reserva, incluso con caja vacía. Si ambos importes son iguales y
  la reserva es positiva, muestra **Sin margen para retiros**.
- Al registrar un gasto de empresa, `registrarMovimientoConReserva` consulta el
  saldo vigente dentro de la transacción. Si utiliza la reserva, solicita
  confirmación antes de guardar. Cancelar no cambia los datos; confirmar permite
  el gasto sin permitir saldo negativo. Los movimientos personales no disparan
  esta advertencia. Son alertas dentro de la app, sin notificaciones del sistema.
- La pestaña **Reportes** permite elegir Hoy, Esta semana (lunes a hoy), Este mes
  (día 1 a hoy), Todo el historial o fechas personalizadas inclusivas. Usa la
  fecha local del dispositivo. Empresa es el ámbito inicial; también permite
  Personal o Empresa + personal.
- Muestra ingresos, gastos, balance de movimientos y desglose por categoría.
  Las barras y porcentajes representan la proporción de los gastos. Incluye
  categorías archivadas y un grupo Sin categoría; no modifica datos ni saldos.
- Los cálculos agregan centavos enteros. El balance no es ganancia ni saldo de
  caja: incluye retiros como gastos y no incluye saldo inicial ni ajustes directos.
- Los filtros operan en memoria, independientes de los del Historial. Registrar,
  borrar, restaurar o reclasificar actualiza también los reportes. Actualizar y
  Reintentar vuelven a consultar los datos. No se requiere migración adicional.

### Fechas en el historial

El Historial inicia en **Todo el historial**. El calendario permite elegir Hoy,
Esta semana (desde lunes), Este mes (desde el día 1) o Elegir fechas. Ambos días
del rango personalizado se incluyen completos, usando la fecha local. Los
filtros de fecha, tipo y ámbito se combinan; los totales corresponden a esa misma
selección. Limpiar filtros restablece los tres y muestra todos los movimientos.
Cancelar el calendario conserva la selección anterior. Los controles se mantienen
cuando el rango no tiene resultados. No se vuelve a consultar SQLite al filtrar.
Estos filtros son independientes de los períodos seleccionados en Reportes.

### Movimientos frecuentes, cierres y retiros de sueldo

- **Movimientos frecuentes** está en Inicio y en el botón de rayo de Historial.
  Permite crear, editar y eliminar plantillas con descripción, monto, tipo,
  ámbito y categoría. También puedes guardar un movimiento normal del historial
  como frecuente. Guardar la plantilla no mueve dinero; tocarla abre un registro
  nuevo con fecha de hoy y datos editables. Las alertas de reserva siguen activas.
- Si la categoría de una plantilla fue archivada, al usarla se muestra Sin
  categoría. Si se elimina una categoría sin movimientos asociados, la plantilla
  se conserva con categoría nula. Borrar una plantilla no borra movimientos.
- **Cierre de caja** está en Inicio y en su menú Más opciones, incluso con caja
  vacía. Ingresa el efectivo contado, revisa la diferencia y explica faltantes o
  sobrantes. Puedes registrar una operación olvidada antes de confirmar.
- Confirmar guarda fecha, saldo esperado, contado, reserva y explicación en
  `cierres`, y ajusta la caja en una sola transacción. Si el saldo esperado cambió,
  se pide revisar el nuevo saldo antes de confirmar otra vez. La reserva no cambia.
  Un cierre sin diferencia admite nota opcional. Puedes seguir operando después.
- Los cierres se consultan en un historial de solo lectura. Sus ajustes no crean
  ingresos, gastos o retiros, por lo que no alteran los reportes de movimientos.
- En **Reportes → Retiros de sueldo**, los mismos períodos permiten ver total,
  cantidad y detalle de salidas de sueldo. El ámbito Empresa/Personal no se
  aplica a este resumen: se cuentan solo salidas de empresa marcadas como retiro,
  sin duplicar el ingreso personal del mismo traslado.
- El esquema v5 añade `frecuentes`, `cierres` y `movimientos.es_retiro`. Los
  retiros nuevos se marcan al confirmarlos. Para los datos previos se reconoce
  el concepto exacto `Retiro de sueldo` como gasto de empresa, usado por el flujo
  anterior y la demostración; los demás movimientos conservan su clasificación.
  La migración no cambia saldos ni vuelve a insertar datos iniciales.

### Protección de cierres y correcciones

- Al confirmar un cierre, se conserva una copia de los movimientos existentes y
  se vinculan al cierre dentro de la misma transacción. La protección se basa en
  esa pertenencia, no en la fecha ingresada. Un registro creado posteriormente
  con fecha anterior sigue sin conciliar hasta incluirlo en un nuevo cierre.
- Los movimientos conciliados muestran un candado: no se pueden editar, cambiar
  de categoría ni borrar. Las comprobaciones se ejecutan en el repositorio y
  mediante restricciones en SQLite, incluso si el cierre ocurre mientras se
  tiene abierto un formulario de corrección.
- Antes de conciliar, se permite corregir monto, descripción, fecha, tipo, ámbito
  y categoría con motivo obligatorio. Se comprueba que el original no haya
  cambiado, se ajusta solo la diferencia de saldo y se guardan valores anteriores,
  nuevos, fecha y motivo de forma atómica. Los retiros conservan su naturaleza y
  no pueden corregirse aumentando el retiro por encima de la reserva disponible.
- Los registros históricos de empresa cuyo efecto sobre caja era cero
  conservan ese efecto cero al corregirse; no se recalcula el saldo inicial.
- Después de conciliar, se puede registrar una aclaración sin cambio de saldo o
  un ajuste nuevo de efectivo, siempre vinculado al original y con explicación.
  Solo los movimientos de empresa admiten ajustes de caja. No se permite saldo
  negativo y se solicita confirmación si se utiliza la reserva. El ajuste y su
  efecto en caja se guardan juntos y no reescriben el movimiento ni el cierre.
- Los ajustes de corrección se consultan en el detalle protegido y en Historial
  → Trazabilidad. No se cuentan como ventas, gastos o retiros nuevos en Reportes.
  El resumen de retiros conserva las salidas registradas, sin compensarlas ni
  ocultarlas por ajustes posteriores.
- Trazabilidad conserva también altas, retiros, borrados, Deshacer, cierres y
  cambios manuales de caja. Los cambios manuales requieren motivo en la interfaz.
  Los registros de auditoría, ajustes, cierres e instantáneas son de solo lectura.
- En Cierre de caja, **Ver movimientos protegidos** muestra las copias guardadas.
  La migración v6 no puede reconstruir qué incluían los cierres de versiones
  anteriores: si ya hay cierres, protege conservadoramente los movimientos
  existentes vinculándolos al último cierre y marca las copias como capturadas
  durante la actualización. La interfaz explica esa limitación. No cambia saldos.
- La auditoría empieza al activar esta versión; no reconstruye cambios anteriores.
  Es una protección local de la aplicación, sin identificación de autor por cuenta
  ni garantía frente a manipulación externa del archivo de base de datos.

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

El archivo `web_dev_config.yaml` fija el servidor de desarrollo en
`http://localhost:7357`. Flutter lo utiliza desde la carpeta interna del proyecto,
tanto al ejecutar desde terminal como al iniciar desde un IDE, sin repetir el
puerto en cada ejecución (requiere Flutter 3.38 o posterior).

```bash
flutter run -d chrome
```

Para usar tu perfil habitual del navegador, inicia el servidor y abre manualmente
`http://localhost:7357` en ese mismo perfil:

```bash
flutter run -d web-server
```

El almacenamiento está ligado al origen (protocolo, host y puerto) y al perfil
del navegador. Recargar conserva los datos; cambiar de puerto o borrar los datos
del sitio utiliza un almacenamiento distinto o elimina el existente. La base
web y la del teléfono son independientes: no hay sincronización entre ellas.
Cambiar de puerto u origen no traslada los datos existentes al nuevo. Si los
datos permanecen en el navegador, puedes volver al origen anterior para verlos.
El perfil de Chrome de depuración también depende de la caché de herramientas;
para pruebas de persistencia entre sesiones usa el servidor web y el mismo perfil
habitual. Borrar datos del sitio, usar modo privado, borrar ese perfil o perder el
equipo puede eliminar la base local. El puerto fijo no sustituye un respaldo.

En Android e iOS, `caja_segura.db` se guarda en el almacenamiento local de la app
mediante `getDatabasesPath()`. Cerrar la app o reiniciar el teléfono no borra la
base. Una actualización normal mantiene los datos si conserva la identidad de la
app y sus migraciones funcionan correctamente. Desinstalar, borrar los datos de
la aplicación (Android), restaurar el teléfono o borrar el emulador puede eliminar
la base. Los respaldos del sistema dependen de su configuración; la app no tiene
todavía exportación/restauración propia ni sincronización entre dispositivos.

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


