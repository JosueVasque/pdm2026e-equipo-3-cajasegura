# Bitácora de uso de IA

Cada uso de IA que termina en el repo se registra aquí (el más reciente arriba).
El objetivo no es justificar el uso, sino demostrar **criterio**:
qué especificaste, qué revisaste y qué rechazaste.

| Campo | Qué escribir |
|---|---|
| Fecha / autor | `2026-10-15 · @usuario` |
| Herramienta | Claude, Copilot, ChatGPT… |
| Especificación | Qué pediste y con qué restricciones (pegar el prompt o resumirlo) |
| Resultado | Qué devolvió, en una frase |
| Aceptado | Qué quedó en el código y por qué |
| Rechazado / corregido | Qué cambiaste y por qué. **Esta es la columna más importante.** |
| Verificación | Cómo comprobaste que funciona (pruebas, dispositivo) |
| Commit / PR | Enlace |

---

## 2026-10-15 · @JosueVasque y @ethanrestrada — estados de la pantalla Historial

- **Herramienta:** Claude.
- **Especificación:** "Pasar la pantalla Historial a Riverpod: repositorio y lectura como providers,
  `AsyncValue.when` con los 4 estados (cargando, error con Reintentar, vacío con una acción y datos),
  sin reintento automático de Riverpod 3 y con una prueba de widget del estado de error."
- **Resultado:** `historial_provider.dart`, la pantalla con los 4 estados y `historial_screen_test.dart`.
- **Aceptado:** el repositorio como `Provider` para poder sobrescribirlo en las pruebas, y
  `ref.invalidate(historialProvider)` en el botón Reintentar.
- **Rechazado / corregido:**
  - La acción del estado vacío no abre un formulario nuevo (el lab no permite agregar funciones):
    solo regresa a la caja.
  - Se usó `skipLoadingOnRefresh: false` para que al reintentar se vea otra vez la carga y no se
    quede el error en pantalla mientras llega la respuesta.
  - La prueba de filtros que estaba en `widget_test.dart` se movió a `historial_screen_test.dart`,
    porque la pantalla ya no recibe el repositorio por constructor sino por `overrides`.
- **Verificación:** <!-- completar: flutter test en local, prueba en emulador y check del PR -->
- **Commit / PR:** <!-- completar con el enlace al PR -->

---

## 2026-10-15 · @JosueVasque — archivos de CI (rama `chore/ci`)

- **Herramienta:** Claude.
- **Especificación:** "Copiar de `saulecch/inkash` (tag `s14-06-ci`) el `ci.yml`, la plantilla de PR,
  `CODEOWNERS` y el formato de la bitácora, adaptados a CajaSegura con Flutter 3.44.8 y los
  usuarios del equipo."
- **Resultado:** los cuatro archivos adaptados.
- **Aceptado:** el `ci.yml` igual al de referencia (misma versión de Flutter, mismo nombre del
  job "Formato, análisis y pruebas" para usarlo como check requerido), con el nombre del APK cambiado.
- **Rechazado / corregido:**
  - El `ci.yml` de inkash corre en la raíz del repo, pero aquí el proyecto Flutter está en
    `caja-segura/`. Se agregó `defaults.run.working-directory: caja-segura` y se corrigió la ruta del APK.
  - Se quitaron de la plantilla de PR los puntos propios de inkash (dinero en centavos y ADRs),
    que no aplican a este proyecto.
  - Se quitó la entrada del docente de la bitácora; solo se conservó el formato.
- **Verificación:** <!-- completar: dart format / flutter analyze / flutter test en local y check del PR -->
- **Commit / PR:** <!-- completar con el enlace al PR chore/ci -->
