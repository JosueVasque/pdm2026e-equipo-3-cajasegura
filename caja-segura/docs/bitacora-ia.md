# Bitácora de uso de Inteligencia Artificial

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
