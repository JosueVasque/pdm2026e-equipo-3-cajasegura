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

### Funciones implementadas

1. Consultar y editar efectivo y reserva de insumos, con alertas de reserva insuficiente.
2. Simular y confirmar retiros de sueldo, verificando el saldo vigente y protegiendo la reserva.
3. Registrar movimientos de empresa o personales; consultar el historial con filtros de fecha, tipo y ámbito.
4. Administrar categorías y plantillas de movimientos frecuentes.
5. Consultar reportes por período, ámbito y categoría, incluido el resumen de retiros de sueldo.
6. Realizar cierres de caja con efectivo contado, diferencias e historial de cierres.
7. Corregir movimientos no conciliados con motivo; proteger los conciliados y registrar aclaraciones o ajustes vinculados.
8. Conservar datos localmente en SQLite y consultar la trazabilidad de operaciones.

La navegación principal incluye **Inicio, Historial, Categorías y Reportes**.

### No entra todavía

1. Pantalla independiente de "Retiro exitoso"; la confirmación ya muestra un aviso.
2. Pantalla independiente de ajuste ante riesgo de descapitalización.
3. Sincronización con un servidor o entre dispositivos.
4. Exportación y restauración de respaldos desde la app.

La persistencia local está integrada en Android/iOS y en la versión web. Los datos
se guardan por instalación o por origen y perfil del navegador; no se sincronizan.

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

La aplicación separa **Presentación** (pantallas, widgets y providers de Riverpod),
**Dominio** (modelos y reglas en Dart puro) y **Datos** (SQLite, migraciones y
repositorios asíncronos). La navegación principal tiene cuatro pestañas: Inicio,
Historial, Categorías y Reportes.

El código Flutter está en `caja-segura/lib/`, con las carpetas `presentation/`,
`domain/` y `data/`. Las pruebas están en `caja-segura/test/`.

Consulta la [estructura y documentación técnica de la app](caja-segura/README.md#arquitectura)
para conocer los componentes, la persistencia, las migraciones y sus limitaciones.

## Decisiones y pruebas con usuarios

- [ADR 0001: persistencia local con SQLite](docs/adr/0001-persistencia-local-sqlite.md).
- [ADR 0002: navegación y filtros con Riverpod](docs/adr/0002-navegacion-y-filtros-riverpod.md).
- [Pruebas con usuarios y seguimiento de correcciones](docs/usuarios.md).
  Incluye tres hallazgos reportados por el equipo, sus PR correctivos y la validación posterior pendiente.

## Flujo de contribución

Nadie trabaja directamente en `main`. El flujo es:

`issue` → `rama` → `pull request` → `revisión` → `merge`

## Cómo correr el proyecto

### Requisitos

- Flutter en el `PATH`, con Dart compatible con `^3.12.2`. El archivo de dependencias resueltas actual requiere Flutter `>=3.44.0`.
- Chrome para ejecutar la versión web; no hace falta Android Studio para esta vista previa.
- Para Android o iOS se necesita además el entorno de desarrollo de la plataforma correspondiente; iOS requiere macOS y Xcode.

Desde la raíz del repositorio, entra en la carpeta que contiene `pubspec.yaml`:

```powershell
cd caja-segura
flutter --version
flutter doctor
flutter pub get
flutter run -d chrome
```

Si ya estás en la carpeta interna `caja-segura/`, omite `cd caja-segura`.
Para un dispositivo móvil configurado, usa `flutter devices` y luego
`flutter run -d ID_DEL_DISPOSITIVO`.

Si Windows muestra **Building with plugins requires symlink support**, abre
Configuración desde PowerShell:

```powershell
start ms-settings:developers
```

Activa **Modo de desarrollador**, acepta la confirmación y vuelve a ejecutar
`flutter pub get` y `flutter run -d chrome`.

### Vista de teléfono con Device Preview

El proyecto ya incluye `device_preview: ^1.3.1` y lo integra en `lib/main.dart`.
Se activa en modo **debug**, incluido `flutter run -d chrome`, y queda desactivado
en profile y release. No es necesario volver a instalar el paquete.

1. Ejecuta la app en Chrome. En una ventana amplia, el panel de Device Preview aparece a la derecha.
2. En **Device → Model**, selecciona el teléfono que quieres mostrar.
3. En **Frame visibility**, selecciona **Visible** para mostrar el marco.
4. Usa **Orientation** para alternar entre vertical y horizontal.

En ventanas estrechas, toca **Device Preview** en la barra inferior para abrir
el panel; si está apagado, activa su interruptor. Si la app ya estaba ejecutándose
antes del cambio en `main.dart`, detén la ejecución y vuelve a iniciarla.

Esta versión incluye los controles dentro de la página de la app. La integración
usa el widget `DevicePreview`, `DevicePreview.locale` y `DevicePreview.appBuilder`;
las instrucciones de la versión 3.x, como `DevicePreview.enable()`, no corresponden
a la dependencia instalada. Consulta la [documentación de Device Preview 1.3.1](https://pub.dev/packages/device_preview/versions/1.3.1).

La vista previa permite revisar tamaños, orientación y apariencia de teléfono;
las funciones nativas se deben comprobar también en un dispositivo o emulador.

## Datos locales y documentación técnica

SQLite conserva caja, movimientos, categorías, frecuentes, cierres y trazabilidad.
En web se utiliza WebAssembly e IndexedDB; el servidor de desarrollo está fijado
en `http://localhost:7357`. Para conservar datos entre sesiones en tu perfil
habitual, ejecuta `flutter run -d web-server` desde la carpeta interna y abre esa
dirección en el mismo perfil del navegador.

Los recursos `web/sqlite3.wasm` y `web/sqflite_sw.js` ya están incluidos y deben
publicarse junto con la app web. No hay sincronización ni respaldo propio: borrar
los datos de la app o del sitio puede eliminar la información guardada.

Consulta la [documentación técnica](caja-segura/README.md#persistencia-local-con-sqlite)
para las ocho tablas del esquema v6, migraciones, reglas de saldo, protección de
cierres y detalles de almacenamiento por plataforma.

## Validación

Desde la carpeta interna de la aplicación:

```powershell
flutter analyze
flutter test
```

La suite incluye reglas de retiros y reserva, persistencia con SQLite real,
migraciones y conservación de datos, categorías, historial y filtros, reportes,
movimientos frecuentes, cierres, correcciones y trazabilidad. Las pruebas de
widgets cubren navegación, formularios, carga, errores y reintentos, además de la
protección de movimientos conciliados.
