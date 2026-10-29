# FICOESA Creative Hub V3.3 — Inicio no bloqueante + Caja de Herramientas editable

Fecha: 29/10/2026. Base: ZIP V3.2 proporcionado en la conversación anterior.

## Resumen de cambios

**Creative Hub (index.html)**
- Primero se cargan las campañas desde Supabase y se renderizan sus metadatos. Las URLs temporales de las imágenes se solicitan **después y en segundo plano**, sin bloquear la navegación.
- Durante la primera consulta de campañas, las secciones y el menú ya se pueden usar. No se muestra una página completa de «Cargando campañas»; las secciones vacías transitorias se actualizan al recibir datos.
- Si falta una imagen, su ubicación muestra una ilustración neutra en los colores de la marca y se sustituye por la imagen real cuando Storage responde.
- Los errores reales de consulta a la base de datos siguen mostrándose; esta mejora no elimina las comprobaciones de autenticación ni hace públicas campañas privadas.

**Caja de Herramientas (herramientas/index.html)**
- Menú principal centrado en 3+3+1 tarjetas para escritorio; ajuste automático 2/1 columnas para tablet y móvil.
- Siete iconos SVG distintos, dibujados localmente y acordes con los colores corporativos. No se necesitan fuentes de iconos ni dependencias externas.
- Las siete categorías principales permanecen **fijas**: Fichas, Merchandising, PLV y mobiliario, Recursos, Catálogos y folletos, Ferias y exposiciones, Novedades.
- Administración > **Administrar subdivisiones**: crear, renombrar y eliminar una subdivisión; la eliminación se bloquea si contiene recursos. La información se comparte entre usuarios mediante Supabase.
- El selector de subdivisiones del formulario de alta/edición se completa automáticamente según la categoría elegida. «Sin subdivisión» es válido y conserva el histórico anterior.
- Navegación: Categoría → Subdivisión → Año → Material, si la categoría tiene alguna subdivisión; Categoría → Año → Material, si no la tiene. En Fichas se mantiene además el paso de Tipo de ficha antes de la subdivisión.
- Los materiales históricos sin subdivisión permanecen accesibles en «Sin subdivisión», no se migran ni se borran.
- Roles actuales y las restricciones de Turista, Connect y Caja no han cambiado.

## Instalación — orden IMPORTANTE

1. Guarda una copia del repositorio y de la base de datos. Prueba primero en un entorno o rama de pruebas.
2. En Supabase, abre el proyecto **que contiene `public.marketing_toolbox_items`** y ejecuta desde SQL Editor el archivo `sql/INSTALAR_SUBDIVISIONES_V3_3.sql` completo. El script crea la tabla `marketing_toolbox_sections`, agrega el campo `section_id` a los recursos y configura sus políticas RLS. No elimina filas existentes.
3. Comprueba en Table Editor que existe `public.marketing_toolbox_sections` y que `marketing_toolbox_items` contiene `section_id`.
4. Sube los archivos del proyecto a GitHub Pages conservando rutas originales; se recomienda publicar primero en entorno de prueba. La nueva versión actualiza la clave del caché estático de la PWA a V3.3.
5. Abre la Caja como Admin > Gestionar recursos > Administrar subdivisiones. Crea «Presentaciones» dentro de Recursos.
6. Abre «Nuevo contenido» > categoría Recursos: el selector debe ofrecer «Presentaciones». Selecciónala, rellena año y título, guarda un recurso de prueba.
7. Comprueba Recursos > Presentaciones > Año > recurso; comprueba además que los recursos antiguos están en «Sin subdivisión».
8. Comprueba que Fichas conserva los cuatro tipos de ficha y que los siete iconos aparecen correctamente en escritorio y móvil.
9. Comprueba en el Creative Hub que el calendario, directorio y menú se pueden abrir aunque aún no aparezcan las portadas; con Internet lento o fallos puntuales de Storage, no debe quedar bloqueada la interfaz.

## SQL y seguridad

El nuevo campo `section_id` contiene una referencia opcional a `marketing_toolbox_sections.id`. Una función trigger impide asociar una subdivisión de otra categoría. Las políticas RLS permiten leer subdivisiones solo a los perfiles existentes `admin`, `worker`, `boss`, y escribirlas solo a `admin`, usando el rol que ya usa la aplicación, `ficoesa_my_role()`.

El SQL requiere las tablas y roles existentes del proyecto. **No** lo ejecutes en FICOESA Connect ni en un Supabase diferente. Si una consulta devuelve un error, detente y revisa la definición real de la tabla antes de modificar restricciones.

## Pruebas realizadas

Se ha comprobado con Chromium/Playwright en un entorno local y datos simulados: 7 categorías, iconos, navegación con/sin subdivisiones, acceso a materiales históricos, botón Volver, creación de subdivisiones, propagación al formulario, adaptación a móvil y ausencia de errores JavaScript. En el Creative Hub se comprobó que su menú permanece navegable mientras `dbState` está en `loading`.

**No se ha realizado una instalación ni prueba de integración sobre el Supabase real o el GitHub publicado.** Debes validar las reglas SQL y los permisos con vuestra cuenta Admin en el despliegue de pruebas.

## Reversión

Si se desea volver al aspecto V3.2, restaura `index.html`, `herramientas/index.html` y `service-worker.js` de la versión anterior. Mantener la tabla y columna nuevas en Supabase no obliga a utilizarlas y no elimina contenidos existentes. No borres la columna si ya has clasificado recursos en subdivisiones.
