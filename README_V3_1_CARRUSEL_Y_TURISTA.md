# FICOESA CREATIVE HUB · V3.1

## Qué incluye

Partimos de la versión V3.0 entregada y conservamos todas sus funciones: inicio de sesión, usuarios, directorio, calendario, catálogo, campañas, caja de herramientas, FICOESA Connect, entrada TURISTA, tablón de avisos e instalación PWA.

### Carrusel de novedades

- Aparece en la portada de Creative Hub tanto para usuarios autenticados como TURISTA.
- Muestra **solo las 3 campañas más recientes marcadas `publicada` y no archivadas**, ordenadas por fecha real de publicación; si no existe, toma la fecha publicada en una red social, y después fecha prevista o de alta. No se muestran borradores.
- Una campaña por diapositiva, con animación horizontal continua, avance automático **cada 8 segundos** (de 3 a 1 sin salto), flechas y 3 indicadores.
- Permite **Pausar/Reanudar**. Se pausa al pasar el ratón, enfocar un elemento, minimizar pestaña o activar en el sistema `prefers-reduced-motion`.
- Si el equipo marca una campaña nueva como `publicada`, se añade al carrusel cuando el sistema actualiza los datos. En TURISTA la consulta se actualiza cada ~90 segundos mientras la pestaña está visible; los usuarios autenticados usan las notificaciones del directorio.
- **Las campañas antiguas NO desaparecen.** Todas las publicadas y no archivadas siguen en Directorio, Calendario, Catálogo y fichas accesibles para TURISTA.

### Turista: solución de la pantalla "No se han podido cargar las campañas"

Si al pulsar «ESTOY DE VISITA» aparece el error, la V3.1 muestra el motivo de Supabase cuando esté disponible y un botón **Reintentar carga**. El error de lectura no se resuelve haciendo públicas todas las tablas: para ello debes activar la RPC segura `public.ficoesa_tourist_feed()` del SQL incluido en el ZIP.

**Cómo activarlo sin abrir datos internos:**
1. Haz una copia de seguridad de la web y de las políticas RLS actuales.
2. Abre el SQL Editor de **Supabase del Directorio Creative Hub**, no el de FICOESA Connect.
3. Ejecuta `sql/INSTALAR_TURISTA_Y_AVISOS_V3.sql` si todavía no lo aplicaste; revísalo con los nombres de bucket y tablas del proyecto.
4. Ejecuta `sql/COMPROBAR_ACCESO_TURISTA.sql`. Verifica que la RPC existe, que `anon` tiene ejecución y cuántas campañas publicadas y no archivadas hay. El test no modifica ninguna tabla.
5. Prueba en incógnito: `ESTOY DE VISITA` muestra esas campañas; no se ven pendientes, archivadas, Caja de Herramientas ni FICOESA Connect; las imágenes de las publicadas cargan.

**Seguridad:** el modo TURISTA es acceso **público** sin credenciales a campañas publicadas, no una nueva cuenta de Supabase. La RPC devuelve solo campos editoriales y la política de Storage debe firmar exclusivamente imágenes de campañas publicadas. No concedas `SELECT` general a `anon` sobre `campaigns`, no hagas público el bucket y comprueba el resto de políticas. Tampoco actualices las aplicaciones Caja y Connect.

## Cómo desplegar

1. Guarda el ZIP actualmente desplegado como copia de seguridad.
2. Sube **todos** los archivos de la carpeta `DIRECTORIO-WEB-ONLINE-main/` a la raíz que utiliza GitHub Pages. No subas la carpeta contenedora si antes `index.html` estaba directamente en la raíz.
3. Conserva configuración Supabase y otras carpetas existentes; este paquete incluye la versión usada como base y no altera los datos almacenados.
4. Comprueba en una ventana de incógnito que aparece la V3.1. Usa Ctrl+F5 o Ctrl+R si la pestaña conserva una versión de caché.
5. Comprueba la navegación, la pausa y que los puntos del carrusel cambian cada ocho segundos sin mantener el ratón sobre él.

## Comprobaciones realizadas

- Sintaxis de los scripts principales en Node.js.
- Prueba con navegador Chromium de datos simulados: 5 campañas publicadas; el carrusel muestra únicamente 3; el avance ocurre a los 8 segundos, pausa y reinicia, vuelve de la 3 a la 1; el Turista puede entrar al directorio y consultar las 5, sin enlaces a Caja o FICOESA Connect.
- NO se han probado directamente vuestro GitHub Pages ni vuestro Supabase de producción. La conexión, políticas RLS y datos reales deben revisarse en vuestro entorno antes de sustituir la web.
