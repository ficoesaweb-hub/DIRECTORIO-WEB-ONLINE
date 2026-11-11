# FICOESA Creative Hub - V3.5 (11/11/2026)

Actualizacion del frontend de `DIRECTORIO-WEB-ONLINE-main` a partir del archivo original facilitado. No se incluyen migraciones de base de datos ni cambios en credenciales, permisos, tablas o politicas de Supabase.

## 1. Caja de herramientas - Año solo en Catálogos y folletos

Archivo: `herramientas/index.html`.

- `Catálogos y folletos`: sigue mostrando la selección de año (2026, 2027 y cualquier año existente en los contenidos). Si hay subdivisiones, primero se elige la subdivisión y después el año.
- `Fichas`, `Merchandising`, `PLV y mobiliario`, `Recursos`, `Ferias y exposiciones` y `Novedades`: muestran directamente sus contenidos al elegir la categoria o subdivisión, sin paso intermedio de año.
- Los materiales antiguos permanecen guardados y se muestran aunque su campo `year` contenga un año distinto.
- Se oculta el año en las tarjetas, detalles y listado de administración para categorías que no son Catálogos y folletos.
- El formulario de alta/edición solo pide Año si la categoría es Catálogos y folletos. En las demás categorías se conserva el año antiguo al editar y se asigna automáticamente el año actual a nuevas entradas para mantener compatibilidad con el esquema de datos existente.
- Se reconoce la navegación antigua (`#merchandising/2026`, por ejemplo) y se omite el tramo anual al entrar.

## 2. Menú principal del Marketing Hub por hover

Archivo: `index.html`.

- En escritorio (`>=961 px`) el lateral permanece siempre plegado (72 px).
- Al pasar el ratón por encima, se expande a 252 px con una transición suave. Al abandonarlo, se recoge sin recargar la página.
- La apertura también se activa con el foco del teclado (`focus-within`) por accesibilidad.
- El menú se expande sobre el contenido, sin desplazar el ancho de las páginas.
- Se mantiene el botón y el patrón de menú móvil existente en pantallas de hasta 960 px, con su cortina.
- Se elimina el sistema antiguo de preferencia persistente de menú abierto/cerrado para que nunca quede abierto al entrar.

## 3. Motion System de Caja de herramientas

Archivo: `herramientas/index.html`.

- Entrada escalonada de categorías, carpetas, materiales, hero y ruta de navegación.
- Elevación y sombras suaves en tarjetas, efecto de reacción sobre iconos, flechas y portadas.
- Búsqueda con feedback al recibir foco, microinteracciones en botones y accesos a descargas.
- Feedback de pulsación y mejoras de foco de teclado.
- Animaciones deshabilitadas automáticamente para usuarios con `prefers-reduced-motion: reduce`. En pantallas táctiles no se fuerza la elevación hover.

## 4. FICOESA Connect

Archivo: `connect/index.html`.

- Se mantiene la autenticación y backend independiente de Supabase.
- Se conserva la lógica de chats, canales, permisos, notificaciones, envío, adjuntos y borrado.
- Se rediseñan barra lateral, cabecera, tarjetas de canal, perfil, burbujas de chat, barra de escritura, botones, inicio de sesión y ventanas de administración.
- Se adopta la paleta visual del Marketing Hub/Caja de herramientas: antracita, superficies verdes oscuras, amarillo FICOESA, tipografía Montserrat y bordes suaves.
- Se conserva el diseño móvil y se añade respeto por reducción de movimiento.

## Publicación

1. Realiza una copia del repositorio o de la rama actual.
2. Copia **todo el contenido** del ZIP actualizado sobre el repositorio de GitHub Pages; conserva la estructura de carpetas y los archivos de configuración del proyecto que correspondan a tu entorno.
3. Publica como habitualmente y revisa el desplegable de la izquierda y la ruta `herramientas/`.
4. Comprueba en tu Supabase real un catálogo, un recurso de Merchandising y el envío/lectura de mensajes de Connect. Las pruebas automatizadas se han realizado con datos simulados y no sustituyen la validación en el entorno conectado.
5. Si ves aún el diseño antiguo, recarga forzando la caché (Ctrl + F5) y, en caso necesario, actualiza o invalida el service worker de la PWA.

## Verificación aplicada

- Sintaxis JavaScript de las páginas modificadas: correcta mediante Node `--check`.
- CSS sin errores de parseo en las páginas modificadas.
- Pruebas del navegador con datos de muestra: categorías principales 7/7, acceso directo a Merchandising (2 recursos de dos años), selección de Catálogos por 2026 y 2027, Año condicional en formulario, apertura/cierre hover del menú lateral (72 a 252 px), login y vista visual de Connect, y Caja de herramientas en móvil sin desbordamiento horizontal.
- No se ha validado un login ni el envío de mensajes con usuarios reales de Supabase desde esta sesión.
