# FICOESA Creative Hub - actualización Web App (28/10/2026)

Este paquete parte del repositorio `DIRECTORIO-WEB-ONLINE-main` suministrado por el equipo WORKO/FORLI. **No es un proyecto nuevo ni una copia con datos inventados**: conserva su aplicación, módulos, tablas y conexiones actuales.

## Qué existe en esta base

- **Intro animada**: `/intro/`, accesos al directorio, caja de herramientas y FICOESA Connect.
- **Directorio y calendario**: campañas, carruseles, fechas previstas/publicadas, redes sociales y filtros.
- **Próximamente**: seguimiento y correcciones sobre campañas pendientes (según el rol).
- **Catálogo**: navegación por marcas, líneas, gamas y modelos relacionados con campañas.
- **Administración**: alta, edición, duplicado, archivo, borrado, imágenes JPG, gestión de roles y usuarios.
- **Caja de Herramientas**: `/herramientas/`, material compartido, fichas y archivos según permisos.
- **FICOESA Connect**: `/connect/`, canales y conversaciones privadas con una segunda instancia de Supabase.

## Novedades de esta entrega

1. **Web app instalable (PWA)**: `manifest.webmanifest`, iconos de 192 y 512 px, `service-worker.js`, pantalla informativa sin conexión y botón **Instalar como aplicación** en el directorio.
2. **Búsqueda rápida**: `Ctrl+K` (Windows) / `Cmd+K` (Mac) enfoca el buscador de campañas desde el directorio.
3. **Exportación admin**: en **Administración → Resumen general** aparecen botones para descargar **JSON** y **CSV** con los registros de campañas, categorías, fechas, imágenes referenciadas y descripciones. Se mantiene la exportación local, sin alterar registros ni permisos.
4. **Indicador de almacenamiento corregido**: ya no confunde el límite por JPG (20 MB) con una cuota total de Supabase.
5. **Accesibilidad**: la animación de nueva página respeta las preferencias de movimiento reducido.

## Cómo publicar sin romper lo que hay

1. Guarda una copia del repositorio publicado en GitHub y exporta las campañas desde Administración, si ya hay contenido real.
2. Descomprime este ZIP. Mantén **exacta** la estructura de directorios. Sube todos los archivos al repositorio de GitHub Pages sustituyendo la versión anterior, idealmente desde una rama de pruebas.
3. Comprueba que las rutas `/intro/`, `/`, `/herramientas/` y `/connect/` siguen funcionando. Desde `index.html` se usa Supabase para acceso privado: no funcionará solo con doble clic en un archivo local.
4. En Chrome/Edge, visita el sitio HTTPS publicado e instala desde el menú del navegador, o desde el botón en la navegación lateral tras autenticarte.
5. Prueba los perfiles **admin**, **viewer** y **no autorizado**; revisa crear/editar campañas, imágenes, calendario, catálogo, la caja y Connect.

### Despliegue GitHub Pages

- Compatible con un repositorio alojado en una **subruta** de GitHub Pages. Manifest, service worker, imágenes e iconos usan URLs relativas.
- La instalación PWA requiere **HTTPS o localhost** y un navegador compatible.
- La aplicación **no funciona sin conexión a los datos de Supabase**. El modo desconectado muestra información de que se requiere Internet: deliberadamente no se almacenan campañas privadas en la caché del navegador.
- Si GitHub Pages sirve una versión antigua, realiza una recarga completa y espera la actualización del service worker. La caché incluye solo iconos y la pantalla sin conexión, no campañas ni sesiones.

## Seguridad y bases de datos

- `supabase-config.js` y `connect/supabase-config.js` contienen **claves públicas** para el navegador. Nunca subas claves `service_role`, contraseñas o tokens privados al repositorio.
- Esta versión **no añade ni modifica tablas SQL ni políticas RLS**. Se apoya en las políticas, funciones RPC y buckets que ya deben existir en los dos proyectos de Supabase.
- Una clave pública por sí sola **no protege los datos**: las políticas RLS de Supabase son la barrera de seguridad real. Antes de abrir acceso a nuevos usuarios, revisa políticas para `campaigns`, `ficoesa_allowed_users`, `ficoesa_forli_catalog`, comentarios, herramientas, Connect y Storage.
- Connect está configurado en **otro proyecto Supabase**. Los permisos para este módulo son independientes y necesitan revisión específica.
- **Exportación JSON/CSV**: contiene metadatos internos de campañas. Guardar las descargas de forma segura y no compartirlas en repositorios públicos.
- La exportación **NO descarga las fotografías**: incluye solo las referencias y metadatos. Para una copia completa es necesario respaldar también el bucket de Supabase Storage por una vía autorizada.
- La exportación es **unidireccional** en esta versión. No existe importación ni restauración automática para evitar sobrescrituras accidentales.

## Funciones dependientes de Supabase no comprobadas desde esta entrega

Las pruebas realizadas aquí son estáticas y de sintaxis de JavaScript, **no son pruebas end-to-end de autenticación o permisos reales**. El entorno de compilación bloquea la apertura de sitios locales desde Chromium, así que es imprescindible probar en GitHub Pages con cuentas de prueba.

No se han recibido migraciones SQL, definiciones RLS ni credenciales de acceso de prueba al proyecto. No se han cambiado ni inventado.

## Archivos principales

| Archivo | Propósito |
|---|---|
| `index.html` | Directorio, calendario, catálogo, administración |
| `supabase-adapter.js` | Adaptador de datos y almacenamiento privado |
| `intro/index.html` | Portada animada |
| `herramientas/index.html` | Caja de herramientas |
| `connect/index.html` | FICOESA Connect |
| `manifest.webmanifest` | Instalación de la web app |
| `pwa-register.js` | Registro del service worker |
| `service-worker.js` | Caché exclusivamente de interfaz pública |
| `offline.html` | Pantalla sin conexión |
| `icons/` | Iconos de la web app |

### Checklist de validación en Windows

- [ ] Admin inicia sesión y ve campañas reales.
- [ ] Viewer entra, pero no tiene botones ni permisos de edición.
- [ ] Usuario no autorizado no accede al directorio privado.
- [ ] Calendario, directorio y buscador muestran información coherente.
- [ ] `Ctrl+K` enfoca el buscador.
- [ ] La exportación CSV se abre en Excel y la JSON descarga los metadatos.
- [ ] El icono de Creative Hub se instala y abre la aplicación.
- [ ] Las fotos privadas no se muestran tras cerrar sesión.
- [ ] Caja de Herramientas y Connect mantienen su acceso y sus datos.

**Recomendación:** publicar primero en una rama o despliegue de pruebas antes de sustituir el sitio que utiliza el equipo.
