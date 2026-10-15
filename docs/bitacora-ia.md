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
