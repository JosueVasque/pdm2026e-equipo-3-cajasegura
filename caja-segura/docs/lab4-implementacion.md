# Laboratorio 4: implementación y entrega

## Qué cambió

1. `navegacion_provider.dart`: guarda el índice de la pestaña en un Notifier.
2. `principal_screen.dart`: muestra las pantallas en IndexedStack. Al cambiar de pestaña los widgets siguen montados y conservan su scroll. Ajustes muestra Próximamente.
3. `main.dart`: abre PrincipalScreen. En Caja, Ver historial cambia el provider; en el historial vacío, Ir a mi caja hace lo mismo.
4. `historial_provider.dart`: FiltroHistorial contiene campos final (tipo y ámbito). Su Notifier reemplaza el objeto; historialProvider usa ref.watch para consultar de nuevo cuando cambia. Los resultados se filtran en Dart después de leer SQLite. Los totales representan los movimientos del filtro activo.
5. `historial_screen.dart`: conserva los controles existentes y los estados cargando, error con Reintentar, vacío y datos. Deslizar a la izquierda ejecuta confirmDismiss: primero borra en SQLite, después permite quitar la fila. Si falla, muestra un mensaje y la fila permanece. onDismissed invalida la lista. Deshacer registra el objeto original y vuelve a consultar.
6. `movimiento_repositorio.dart`: elimina por ID con un parámetro SQL. No cambia el saldo de caja.
7. `test/`: pruebas de filtros y vacío, navegación, borrar/deshacer, fallo al borrar y persistencia tras cerrar/reabrir SQLite.

## Probar manualmente

Desde caja-segura:

```sh
flutter run
```

- Inicio -> Ver historial: selecciona Historial en la barra.
- Cambiar Empresa/Personal e Ingresos/Gastos: la lista y los totales cambian solos. Personal + Ingresos puede quedar vacío según los datos.
- Desplazar el historial, ir a Ajustes y regresar: conserva la posición.
- Deslizar una fila a la izquierda y tocar Deshacer: vuelve con los mismos datos.
- Borrar sin deshacer y reiniciar: sigue borrada. Restaurar y reiniciar: sigue guardada.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Preparar commits y PR

El repositorio está en la carpeta superior, cajase. Estos comandos se ejecutan **desde cajase**, no desde caja-segura. Primero revisa `git status` y conserva cualquier cambio previo tuyo. No hay commits ni push realizados por la IA.

El PDF solicita un PR de navegación y otro de filtros/borrado. Puedes separar los archivos así:

```sh
git switch -c feat/navegacion
git add caja-segura/lib/main.dart caja-segura/lib/presentation/providers/navegacion_provider.dart caja-segura/lib/presentation/pantallas/principal_screen.dart caja-segura/lib/presentation/pantallas/caja_negocio_screen.dart caja-segura/test/widget_test.dart
git commit -m "feat: agregar navegacion con provider e IndexedStack"
git push -u origin feat/navegacion
```

Abre ese PR hacia main usando la plantilla existente. Quedarán cambios locales de historial sin incluir: consérvalos. Antes de la entrega final integra navegación, actualiza tu main y crea la rama de la pareja `feat/NUMERO-filtro` (reemplaza NUMERO por el issue real). Puedes crear temporalmente esa rama desde navegación y dirigir el segundo PR a navegación; después del merge cambia su base a main.

```sh
git switch -c feat/NUMERO-filtro
git add caja-segura/lib/presentation/providers/historial_provider.dart caja-segura/lib/presentation/pantallas/historial_screen.dart caja-segura/lib/data/repositorios/movimiento_repositorio.dart caja-segura/test/historial_screen_test.dart caja-segura/test/base_datos_test.dart caja-segura/docs
git commit -m "feat: filtrar historial y borrar con deshacer"
git push -u origin feat/NUMERO-filtro
```

La bitácora ya fue agregada en `docs/bitacora-ia.md` de la raíz del repositorio, conservando las entradas anteriores. Inclúyela con `git add docs/bitacora-ia.md` antes del commit. Hay una copia de esta entrada en `caja-segura/docs/bitacora-ia.md`.

## Texto para el PR de la pareja

**Qué cambia:** El historial observa un filtro inmutable en Riverpod. Permite borrar con SQLite y Deshacer conserva el registro original. Cierra #NUMERO (sustituir por issue real).

**Cómo probarlo:** Cambiar filtros, verificar el vacío, deslizar una fila, tocar Deshacer y reiniciar para comprobar persistencia. Ejecutar formato, análisis y pruebas.

**Por qué key = ID:** El ID identifica al movimiento aunque cambie su posición. Si se elimina la fila 2 de 5, las filas 3, 4 y 5 cambian de índice. Con índices como keys Flutter podría reutilizar el estado de una fila para otro movimiento, produciendo animaciones incorrectas o errores de Dismissible.

**Capturas:** Adjuntar las capturas reales de filtro, deslizamiento, Deshacer y navegación. No se generaron capturas ni una revisión ficticia.

**Checklist:** Marcar únicamente verificaciones realizadas. Pedir revisión a otra pareja, esperar el CI verde e integrar ambos PR en main. El CI existente está en ../.github/workflows/ci.yml y ya ejecuta formato, análisis, pruebas y APK. La plantilla conserva una nota antigua sobre Chrome; este proyecto ya tiene soporte SQLite web, pero para su casilla de dispositivo usa un teléfono o emulador.

## Resultado local

Formato correcto, flutter analyze sin advertencias y las 15 pruebas aprobadas. Se corrigió un desbordamiento de Inicio usando ListView. El CI de GitHub y la revisión de otra pareja quedan pendientes hasta abrir los PR.
