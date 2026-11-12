# Creative Hub · GIF animados en la Caja de Herramientas

Actualización de 12/11/2026 sobre el proyecto original facilitado.

## Alcance (deliberadamente limitado)

**Únicamente se modifica `herramientas/index.html`.** La pantalla de subida de imágenes de portada y su galería admiten ahora JPG, PNG y GIF, también cuando se arrastran archivos sobre el formulario. No se modifica la subida de campañas, el Calendario, Catálogo, la Intro ni FICOESA Connect.

- JPG y PNG: límite anterior de **5 MB** por imagen.
- GIF: hasta **20 MB** por archivo desde la interfaz.
- Se pueden seleccionar varias imágenes y mezclar GIF y fotografías.
- El GIF se previsualiza y se envía **sin convertirlo a JPG ni extraer un fotograma**; se almacena con el tipo MIME `image/gif` y se visualiza con `<img>` para mantener la animación en la portada, el carrusel y el modo cine.
- Se mantiene el selector de **Portada principal**, el orden de galería y la eliminación de imágenes.

## Cómo usarlo

1. Entra en **Caja de herramientas → Gestionar recursos → Nuevo contenido** o edita un recurso existente.
2. En **Galería de imágenes y portada**, selecciona o arrastra un `.gif` (puedes mezclarlo con JPG y PNG).
3. Si quieres que aparezca como imagen de portada de la tarjeta, pulsa **Elegir portada** en el GIF y comprueba que indique **PORTADA PRINCIPAL**.
4. Pulsa **Guardar cambios** o **Crear contenido**. Revisa la miniatura y el detalle del recurso.

## Publicación

1. Conserva una copia del proyecto actualmente publicado.
2. Sustituye `herramientas/index.html` por el incluido en esta entrega. También puedes subir el ZIP completo manteniendo las rutas, ya que el resto de archivos se ha conservado.
3. Publica en GitHub Pages y recarga la Caja de herramientas con **Ctrl+F5**.
4. Prueba primero con un GIF pequeño en un recurso de pruebas y confirma que está animado en la tarjeta y en el detalle.

No hay cambios de tablas ni migraciones SQL en esta versión. El bucket privado de Supabase Storage **`marketing-toolbox` debe permitir `image/gif`**, y debe admitir el tamaño que se vaya a utilizar (hasta 20 MB si quieres aprovechar el límite de la interfaz). Si Supabase devuelve un error de archivo demasiado grande o tipo MIME no permitido, revisa **Storage → Buckets → marketing-toolbox → ajustes** en tu propio proyecto. No hace falta hacer público el bucket ni modificar sus políticas RLS.

## Comprobación y limitaciones

Se ha probado la interfaz localmente en Chromium con Supabase simulado: selector GIF, animación en vista previa, subida del archivo original con MIME `image/gif`, guardado como portada principal, previsualización administrativa y rechazo de formatos no admitidos. Esta prueba no verifica el límite real ni los permisos del bucket conectado a la instancia de FICOESA. No se ha desplegado en GitHub ni modificado el servidor Supabase.
