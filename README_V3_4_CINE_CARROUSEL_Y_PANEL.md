# FICOESA Creative Hub V3.4 — Caja compacta y carrusel editorial

**Base:** V3.3.1 con iconos oscuros. Actualización visual y de navegación, sin cambios de esquema SQL.

## Archivos modificados

- `index.html` (raíz): portada de inicio más contenida, carrusel de las 3 últimas publicaciones centrado, formato Instagram 4:5 sin recorte; menú izquierdo plegable en escritorio con botón ‹ / ›, iconos y nombres accesibles al pasar el cursor. Se recuerda la preferencia en localStorage.
- `herramientas/index.html`: fichas individuales de recursos más compactas, portada y carrusel visibles junto a descripción, hipervínculos y descargas; visor de fotografías en **modo cine** al pulsar cualquier imagen de la galería, flechas izquierda/derecha, botón Cerrar, Escape y contador; archivos secundarios en panel desplegable.
- `service-worker.js`: cambia el nombre de caché de iconos a v3-4. El SW sigue sin guardar HTML privado ni datos de Supabase.

## Principios de diseño

En pantallas de escritorio de al menos 880px de ancho y 620px de alto, la ficha se dimensiona con unidades de altura de pantalla. Se evita desplazar toda la página para avanzar imágenes; cuando haya muchas descargas/enlaces o textos extensos, **solo la columna derecha** se desplaza para mantener la imagen a la vista. En móviles se apila el contenido, ya que no cabe físicamente una galería 4:5 y toda la información en una sola pantalla sin sacrificar legibilidad.

La galería pública de portada usa las mismas imágenes y rutas existentes; se solicitan URL firmadas a Supabase Storage según la lógica anterior. El visor no cambia los permisos ni hace públicas las imágenes.

## Cómo instalar

1. Guardar una copia de la web desplegada en GitHub.
2. Extraer el ZIP manteniendo exactamente las carpetas. Si se usan los HTML sueltos, el de Creative Hub se debe renombrar a **`index.html` en la raíz** y el de la Caja a **`herramientas/index.html`**.
3. Subir los archivos a la rama de pruebas de GitHub Pages. No reemplazar `herramientas/index.html` por el archivo de la raíz ni a la inversa.
4. Limpiar la caché del navegador con Ctrl+F5 y probar con una sesión autorizada:
   - Caja: abrir un recurso con 3 o más imágenes, recorrerlas sin hacer scroll de página; pulsar la imagen, navegar con ← / → y salir con Esc.
   - Caja: verificar los enlaces, descargas y que el editor administrativo sigue funcionando.
   - Creative Hub: comprobar las tres publicaciones recientes y el cambio automático cada 8 segundos; plegar y desplegar el panel lateral. En móvil el panel de navegación sigue como menú lateral accesible con el botón superior.
   - Turista: comprobar acceso limitado a Creative Hub y solo campañas publicadas.
5. Una vez validada en pruebas, actualizar la rama publicada.

## Qué no cambia

No se modifican datos de campañas ni recursos, permisos RLS, tablas, buckets, autenticación, formularios, rutas administrativas, FICOESA Connect o calendarios. No es necesario ejecutar SQL adicional.

## Validación realizada

Comprobación de sintaxis JavaScript, renderizado en Chromium de escritorio y móvil con **datos de simulación**, apertura del modo cine y navegación de imágenes con flechas y Esc, alternancia del menú y verificación de imágenes sin recorte (`object-fit: contain`). Pendiente validar contra datos y usuarios del Supabase real del equipo.
