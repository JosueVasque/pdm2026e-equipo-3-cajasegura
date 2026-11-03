# Bitácora de uso de Inteligencia Artificial

## 2026-11-03 — Protección de cierres y trazabilidad

- Se implementó pertenencia explícita de movimientos a cierres e instantáneas
  inmutables, sin depender de la fecha declarada. Bloqueo de actualización y
  eliminación en repositorios y SQLite, incluidos cambios de categoría.
- Correcciones previas al cierre con motivo, control de versión del original,
  ajuste transaccional del saldo y conservación de datos anteriores y nuevos.
- Después del cierre se permiten ajustes o aclaraciones nuevos vinculados al
  original. No se reescriben ni el movimiento ni el cierre y no se mezclan con
  ventas, gastos o retiros nuevos. Se valida saldo y uso de reserva.
- Se agregó consulta de trazabilidad, movimientos protegidos de cada cierre y
  registro de cambios manuales de caja con motivo obligatorio en la interfaz.
- Migración v6: si existían cierres sin pertenencia documentada, protege los
  movimientos actuales de forma conservadora. Las copias quedan marcadas como
  capturadas en migración; no se presentan como reconstrucción histórica exacta.
- Pruebas de SQLite y de interfaz para inmutabilidad, atomicidad, correcciones,
  bloqueo concurrente, ajustes, deshacer, datos antiguos, motivos y migración.
- Verificación final: formato sin cambios pendientes, análisis sin advertencias
  y las 63 pruebas de la suite aprobadas.
- Límite: trazabilidad local sin cuentas de autor, sin garantía frente a edición
  externa del archivo SQLite ni reconstrucción de modificaciones anteriores.
- Sin commits, push ni PR realizados por IA.

## 2026-11-03 — Origen fijo para desarrollo web

- Se agregó `web_dev_config.yaml` con host localhost y puerto 7357 para mantener
  el origen de IndexedDB al iniciar Flutter sin argumentos de puerto.
- Se contrastó la configuración con el SDK local y la documentación oficial de
  Flutter. No se modificó la base de datos ni se trasladaron datos entre orígenes.
- El README explica el uso del mismo perfil del navegador, la alternativa
  web-server y las condiciones de conservación o pérdida de datos en móviles.

## 2026-11-03 — Fechas en el historial

- Se agregó selección de Hoy, semana, mes, todo el historial y rango personalizado
  inclusivo, combinada con tipo y ámbito. Todo el historial es la opción inicial.
- Los filtros se aplican en memoria; no vuelven a consultar SQLite. Se muestran
  las fechas activas, se conservan los controles sin resultados y se pueden
  limpiar los tres filtros. Cancelar el calendario conserva el período anterior.
- Se reutilizaron las reglas de fechas del dominio, con estado independiente de
  Reportes. No hay cambios de base de datos ni dependencias nuevas.
- Pruebas nuevas para límites de fecha, filtros combinados, cancelación y limpieza;
  se adaptaron las pruebas de movimientos para desplazarse hasta las filas.

## 2026-11-03 — Frecuentes, conciliación y retiros de sueldo

- Se implementaron plantillas persistentes con creación, edición, eliminación y
  reutilización mediante el formulario existente, sin movimientos automáticos.
- La conciliación conserva cierres auditables y actualiza efectivo de manera
  atómica, con explicación obligatoria para diferencias y detección de saldo
  obsoleto. La reserva se conserva y el cierre no bloquea operaciones posteriores.
- Reportes incorpora total y detalle de retiros por período, usando una marca
  explícita de salida de sueldo para evitar duplicar ingresos personales.
- Migración v5: tablas de frecuentes y cierres, marca de retiro y reconocimiento
  de los conceptos de sueldo conocidos de la versión anterior. Sin cambios de saldo.
- Validación: análisis sin advertencias, formato correcto y 47 pruebas aprobadas.
  Se verifican persistencia, migración, atomicidad, saldo obsoleto, duplicados,
  cancelación de cierre, reutilización editable de plantillas y resumen de retiros.
- No se realizaron commits, push ni PR.

## 2026-11-03 — Alertas de reserva y reportes

- Solicitud: alertas de reserva, reportes por categoría y por período.
- Se implementaron alertas de caja insuficiente o al límite y confirmación
  explícita antes de registrar un gasto que utilice la reserva. La comprobación
  se realiza con el saldo vigente dentro de la transacción; cancelar no escribe.
- Reportes agrega filtros independientes de fecha y ámbito, totales en centavos,
  desglose y barras de gastos por categoría, incluyendo archivadas y sin categoría.
- Decisiones: semana desde lunes, mes desde el día 1, períodos hasta hoy y rangos
  personalizados con ambos extremos incluidos. Se distingue balance de
  movimientos de ganancia o saldo. No se añadieron dependencias ni migraciones.
- Validación: 37 pruebas aprobadas y análisis estático sin advertencias. Las
  pruebas cubren límites de fechas, ámbito, centavos, filtros sin consultas
  adicionales, recarga, errores, alertas y cancelación/confirmación del gasto.

## 2026-11-03 — Operaciones diarias de caja

### Diseño visual

- Mejora de fluidez: la lectura SQLite del historial se separó del provider
  síncrono de filtros. Cambiar tipo o ámbito conserva los controles y filtra en
  memoria; registrar, borrar, deshacer y Reintentar siguen recargando los datos.
  Una prueba bloquea posibles lecturas nuevas para detectar regresiones de carga.

- Se adaptó la interfaz a la referencia compartida: encabezados oscuros,
  superficies claras redondeadas, acentos menta, importes destacados y controles
  consistentes en Inicio, Historial, Categorías, retiros y formularios.
- La identidad visual está centralizada en `lib/presentation/tema/caja_estilo.dart`.
- La barra de reserva representa datos reales; no se añadieron gráficas ni
  indicadores ficticios. Los formularios y el historial permiten desplazamiento.
- Se corrigieron los identificadores de los botones flotantes para evitar
  conflictos de animación al abrir formularios desde las pestañas.

- Solicitud: confirmar retiros, registrar movimientos, editar caja/reserva y
  asignar categorías desde la interfaz. Sin commits, push ni PR realizados por IA.
- Implementación: formularios con validación de importes, confirmación de retiro,
  saldo e historial transaccionales, categorías visibles y editables en historial.
- Decisión: un retiro es un único gasto de empresa; los movimientos personales
  no cambian la caja. Los gastos de empresa pueden usar la reserva; los retiros
  de sueldo deben protegerla. Editar caja es una corrección directa.
- Migración v4: conserva el saldo y registra efecto cero para el historial previo;
  los nuevos movimientos guardan su efecto para borrar y deshacer sin desajustes.
- Validación añadida: pruebas SQLite de atomicidad, reserva, duplicados,
  categorías, persistencia, reversión y migración; pruebas de interfaz de los
  formularios, confirmación y reclasificación de movimientos.

## Proyecto: CajaSegura

**Laboratorio:** CRUD completo y migración probada  
**Entidad trabajada:** Categorías  
**Tecnologías:** Flutter, Dart, Riverpod y SQLite

## 1. Objetivo

Implementar un CRUD completo para categorías de movimientos, utilizando la arquitectura existente del proyecto CajaSegura.

También se buscó implementar migraciones de base de datos que conservaran la información registrada por los usuarios.

## 2. Uso de inteligencia artificial

Se utilizó ChatGPT como herramienta de apoyo durante el desarrollo del laboratorio.

La IA ayudó a:

- Analizar la estructura del proyecto Flutter.
- Diseñar el modelo `Categoria`.
- Implementar el repositorio de categorías.
- Preparar migraciones SQLite.
- Integrar categorías con movimientos.
- Crear providers utilizando Riverpod.
- Construir pantallas de listado y formulario.
- Preparar pruebas automatizadas.
- Identificar errores de compilación y ejecución.

## 3. Errores detectados y correcciones

### Error 1: Sintaxis SQL incorrecta

**Problema:** La IA proporcionó una definición de tabla donde faltaba una coma antes de `categoria_id`.

**Resultado:** Cinco pruebas fallaron porque SQLite no podía crear la tabla `movimientos`.

**Corrección:** Se agregó la coma después de `fecha INTEGER NOT NULL`.

### Error 2: Variable sin utilizar

**Problema:** El método `eliminar()` declaraba una variable `db` que todavía no utilizaba.

**Resultado:** `flutter analyze` mostró una advertencia.

**Corrección:** Se eliminó la variable innecesaria y posteriormente se implementó el borrado seguro.

### Error 3: Prueba de navegación desactualizada

**Problema:** Una prueba buscaba la pestaña «Ajustes», pero esta había sido reemplazada por «Categorías».

**Resultado:** Falló una prueba de widget.

**Corrección:** Se actualizaron las expectativas para verificar la navegación hacia Categorías.

## 4. Decisiones técnicas

Se decidió utilizar una entidad independiente llamada `Categoria`.

Se implementó un formulario compartido para crear y editar categorías, evitando duplicar código.

Se utilizó Riverpod para actualizar automáticamente el listado después de las operaciones CRUD.

Para proteger la información existente, se definieron migraciones incrementales de SQLite y se mantuvo la compatibilidad con movimientos sin categoría asignada.

## 5. Validación

Se utilizaron los siguientes comandos:

```bash
dart format lib test
flutter analyze
flutter test
```

Las pruebas contempladas incluyen:

- Persistencia de datos.
- Migración desde una base de datos antigua.
- Edición de categorías desde la interfaz.
- Conservación del identificador de una categoría editada.
- Protección contra eliminación de categorías utilizadas.

**Nota:** Registrar los resultados finales de estas pruebas después de ejecutarlas.

## 6. Conclusión

La inteligencia artificial permitió acelerar el desarrollo y facilitar la identificación de errores.

Sin embargo, las sugerencias generadas necesitaron revisión, corrección y validación mediante herramientas de análisis y pruebas automatizadas.

La responsabilidad de comprobar el funcionamiento del proyecto corresponde al equipo de desarrollo.
