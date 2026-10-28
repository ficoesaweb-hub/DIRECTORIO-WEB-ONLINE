# FICOESA CREATIVE HUB — WEB APP V3.0
## Rol TURISTA · Carrusel de novedades · Tablón informativo

Esta entrega modifica **el proyecto que suministraste**, no crea otra web. Conserva el directorio, calendario, catálogo, administración, caja de herramientas, FICOESA Connect, intro, configuración Supabase, iconos y PWA existentes.

## 1. Qué cambia

### TURISTA — «ESTOY DE VISITA»

- Botón en el inicio de sesión, debajo de correo y contraseña.
- No exige registrar cuenta ni iniciar sesión. Es **un modo de acceso anónimo de Supabase**, no un nuevo miembro de `ficoesa_allowed_users`.
- Al visitante se le muestra exclusivamente **FICOESA Creative Hub** (inicio, directorio, calendario, catálogo derivado de campañas y fichas de las **publicadas y no archivadas**). Ni la barra lateral ni la app turística enlazan a **Caja de Herramientas**, **FICOESA Connect**, `Próximamente` ni `Administración`.
- Los datos del visitante llegan de `ficoesa_tourist_feed()`, una función SQL que **no devuelve** campañas pendientes, archivadas, ni campos privados de gestión o revisión.
- Las imágenes privadas se pueden firmar anónimamente **solo cuando pertenecen a una campaña publicada**; el bucket no se hace público.
- Al salir se limpia el estado turístico. El navegador recuerda que esa pestaña está de visita durante la sesión de pestaña, para permitir recargar sin volver a pulsar el botón.

> **Importante**: dar acceso sin login a las publicaciones significa que esas publicaciones y sus fotos autorizadas pasan a ser visibles para cualquiera que acceda a la URL. No es una cuenta interna de solo lectura: es acceso público limitado.

### Novedades

- Carrusel en la portada con las nueve campañas publicadas más recientes, ordenadas por fecha de publicación.
- Tres tarjetas en escritorio, una en móvil. Flechas, puntos de navegación y apertura de la ficha original.
- Si no hay campañas publicadas, se muestra un estado vacío.

### Tablón del Hub

- Sección informativa debajo de las novedades con los últimos cuatro avisos publicados, incluidos los fijados.
- Administrador: **Administración → Tablón de avisos** para publicar, editar, fijar, ocultar como borrador y borrar avisos.
- Título 1-100 caracteres y texto 1-1.200 caracteres. Sin archivos, HTML ni enlaces automáticos (para no introducir contenido ejecutable).
- Los demás usuarios y turistas leen únicamente los avisos marcados como publicados. No pueden editarlos ni publicar comentarios.
- Los datos se almacenan en la tabla `public.ficoesa_hub_notes` con RLS.

## 2. Activar en Supabase (obligatorio)

1. Haz una copia del repositorio GitHub publicado y, desde Administración, una exportación de los registros. Conserva una copia de las políticas RLS actuales de Supabase.
2. Abre el **Supabase correspondiente al DIRECTORIO WORKO/FORLI**, no el segundo proyecto de FICOESA Connect.
3. En **SQL Editor**, revisa y ejecuta el archivo `sql/INSTALAR_TURISTA_Y_AVISOS_V3.sql` con permisos adecuados.
4. Comprueba que la tabla `public.campaigns` y el bucket privado `campaign-images` coinciden con los nombres del proyecto (son los usados actualmente en `supabase-adapter.js`). La migración crea `ficoesa_tourist_feed`, la política de imágenes publicadas y `ficoesa_hub_notes` con sus permisos.
5. **Revisa todas las políticas existentes** de `campaigns`, `storage.objects`, `marketing_toolbox_*`, `connect_*`: una política permisiva preexistente puede abrir más datos de los deseados. No dar acceso `anon` general a `campaigns`, ni convertir `campaign-images` en bucket público.
6. Publica los archivos de la nueva versión en **GitHub Pages**, conservando las rutas y `supabase-config.js` del paquete. Idealmente prueba primero desde una rama o entorno de pruebas.
7. Si el navegador conserva una versión antigua, recarga completamente; se ha actualizado la versión del service worker.

**Si no ejecutas el SQL, «Estoy de visita» mostrará error al cargar publicaciones y/o imágenes y el tablón no podrá publicar avisos.** Esto es intencionado: no se relajan permisos para ocultar el fallo.

## 3. Pruebas antes de publicar en producción

| Perfil | Debe poder hacer | NO debe poder hacer |
|---|---|---|
| Turista / incógnito | Entrar con «Estoy de visita», ver campañas publicadas, galería y avisos | Ver pendientes, acceder a Administración, Caja o Connect, crear avisos |
| Admin | Todo lo existente + gestionar avisos | — |
| Viewer / visitante autenticado | Sus funcionalidades previas + leer avisos | Publicar o editar avisos |
| No autorizado | Solo el botón de visita pública o su error de acceso normal | Acceder a datos privados |

Prueba la **URL directa** a `/herramientas/` y `/connect/` sin login; ambas ya tienen autenticación independiente. No basta con esconder enlaces de un menú. Prueba también con un `anon` real, desde el cliente Supabase, que no puede consultar una campaña pendiente ni crear un URL firmada para su imagen.

## 4. Qué se ha validado aquí

- Comprobación de sintaxis JS de `index.html` y `supabase-adapter.js` con Node.
- Prueba de interfaz en Chromium con **datos simulados** (sin tocar vuestra base de datos): entrada turista, mostrar novedades, navegar carrusel, ocultación de campaña pendiente, ausencia de enlaces a Caja/Connect, acceso a sección administrativa por rol, formulario y creación simulada de un aviso.
- **No se ha ejecutado la migración SQL contra vuestro Supabase real ni probado sus políticas RLS en un proyecto de producción.** Esa comprobación es obligatoria antes de abrir el acceso a terceros.

## 5. Archivos clave

- `index.html`: pantalla de acceso y novedades, tablón, administración.
- `supabase-adapter.js`: añade la lectura turística mediante `ficoesa_tourist_feed()`.
- `sql/INSTALAR_TURISTA_Y_AVISOS_V3.sql`: seguridad, acceso público limitado y tabla de avisos.
- `README_V3_TURISTA_NOVEDADES.md`: este manual.
- El resto de ficheros originales se mantiene.

**Seguridad:** los enlaces firmados de las imágenes autorizadas pueden compartirse durante su tiempo de validez (aproximadamente 1 hora). No publiques imágenes o campañas sensibles si no quieres que el público las vea.
