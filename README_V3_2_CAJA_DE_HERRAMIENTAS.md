# FICOESA CREATIVE HUB — Caja de Herramientas V3.2

## Actualización centrada en el módulo de herramientas

Esta entrega se ha creado a partir de la versión completa facilitada por el usuario el 29/10/2026. El módulo del directorio de campañas de Creative Hub, la intro, FICOESA Connect y los archivos de configuración de Supabase se conservan. Se ha modificado el diseño y navegación de `herramientas/index.html`; se actualiza la versión de caché de iconos en `service-worker.js`.

## Qué cambia

- Página de inicio de la Caja de Herramientas renovada con bloques visuales más claros, iconografía, contador de recursos y sección de materiales recientes.
- **PLV** pasa a llamarse **PLV Y MOBILIARIO**. Se conserva internamente la categoría `plv` y, por tanto, su histórico.
- Se añade **FERIAS Y EXPOSICIONES**, categoría interna `ferias`, visible también en el formulario de alta.
- Se eliminan de la **navegación** las páginas intermedias `WORKO`, `FORLI` y `GENERAL` en todas las categorías.
- **Catálogos y folletos**: Categoría → Año → Galería → Recurso. Los años se generan automáticamente desde los registros existentes.
- **Merchandising, PLV y mobiliario, Recursos, Ferias y exposiciones, Novedades**: Categoría → Año → Galería → Recurso.
- **Fichas**: Fichas → Tipo de ficha → Año → Galería → Recurso. Conserva los cuatro tipos históricos: técnicas, comerciales, argumentarios, clientes.
- El selector de marca y la subdivisión por línea han desaparecido del **formulario visible**. Las filas existentes mantienen `brand` y `subcategory` en Supabase, sin cambios destructivos. Los contenidos nuevos usan `GENERAL` como valor interno de compatibilidad. Esto no genera una navegación por marcas.
- Tarjetas mejoradas para las galerías, buscador ampliado a títulos, descripción, año y categoría, ficha editorial con secciones, enlaces con dominio y llamadas a la acción; descargas con nombre/tamaño; botón **Volver** y migas de pan.
- La navegación actualiza el historial del navegador; se conservan los accesos profundos actuales `#ruta`, con reconocimiento básico de antiguas rutas con marca.
- El orden de categorías configurado por administradores sigue funcionando; el apartado nuevo se incorpora al final de una ordenación anterior hasta que se reordene manualmente.

## Instalación en GitHub Pages

1. Conserva una copia de seguridad del repositorio actualmente publicado, y preferentemente prueba en una rama o entorno separado.
2. Copia los archivos del ZIP manteniendo exactamente sus rutas y estructura, incluido `herramientas/index.html` y `service-worker.js`.
3. Publica en GitHub Pages y haz una recarga forzada (`Ctrl + F5`). La versión PWA conserva el acceso autenticado a las secciones internas.
4. Entra con una cuenta ADMIN o BOSS y comprueba que la nueva portada tenga siete categorías.
5. Comprueba un recurso histórico registrado bajo WORKO y otro bajo FORLI: ambos deben aparecer juntos cuando tengan la misma categoría y año.
6. Comprueba `Catálogos y folletos → Año → Galería`, y `Fichas → Tipo → Año → Galería`.
7. Desde ADMIN, crea un recurso de prueba en **FERIAS Y EXPOSICIONES**, adjunta un enlace y un archivo pequeño, publícalo, visualízalo y elimina solo el recurso de prueba al terminar.
8. Repite la comprobación desde móvil.

## Consideración de Supabase para FERIAS Y EXPOSICIONES

La interfaz envía `category = 'ferias'` a la tabla existente `public.marketing_toolbox_items`. **No conocemos directamente la definición actual de sus restricciones de base de datos.** Si `category` es texto libre, no hace falta ninguna migración. Si Supabase impone una restricción CHECK o enum con los seis valores antiguos, será necesario permitir el nuevo valor antes de guardar el primer material de Ferias.

Ejecuta en Supabase SQL Editor **solo la consulta de diagnóstico** que encontrarás en `sql/DIAGNOSTICO_CATEGORIA_FERIAS.sql`, y revisa su resultado antes de modificar restricciones. No debes eliminar políticas RLS, reconstruir la tabla ni alterar datos para realizar esta actualización visual.

## Rol y acceso

Se conservan sin ampliar sus permisos existentes: ADMIN gestiona, WORKER aporta borradores y BOSS consulta conforme al código actual. Esta actualización no activa la Caja de Herramientas para el rol Turista y no modifica los módulos de Creative Hub o Connect.

## Seguridad de los enlaces

Los enlaces externos se abren en pestaña independiente con `noopener noreferrer` y únicamente admiten URL `https://` o `http://`. Los documentos siguen utilizando las descargas autorizadas de Supabase Storage con permisos de la cuenta autenticada.

## Reversión

Restaurar `herramientas/index.html` y `service-worker.js` desde la copia anterior. **No se migran ni eliminan datos históricos** con este ZIP.

## Validación realizada

Sintaxis JavaScript comprobada. Prueba de navegación y render con datos simulados en Chromium: 7 categorías, años automáticos, fichas por tipo, nueva categoría en el formulario, eliminación del selector visible de marcas, entrada a ficha, enlaces, descargas y retorno al listado. No se han ejecutado pruebas contra la base Supabase de FICOESA ni se ha desplegado en vuestro GitHub.
