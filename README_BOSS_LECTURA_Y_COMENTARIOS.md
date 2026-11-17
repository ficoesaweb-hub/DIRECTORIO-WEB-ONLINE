# Creative Hub | Rol BOSS: vista global + correcciones

## Cambios realizados

- **Directorio**: BOSS puede ver calendario, directorio, buscador, Próximamente y fichas pendientes/publicadas.
- **Nueva opción «Vista global BOSS»** en el menú, con estadísticas y filtros por marca, estado y texto. Permite abrir **todas** las fichas, también las **archivadas**, en modo lectura. Las archivadas siguen excluidas del calendario y del directorio ordinario (conservamos el comportamiento anterior).
- **Correcciones**: BOSS dispone de las mismas acciones de `comenter` en campañas pendientes: nueva corrección, respuesta, marcar como resuelta / reabrir y borrar una corrección raíz resuelta con confirmación.
- **Caja de Herramientas**: BOSS tiene lectura de materiales de cualquier estado cargado (incluidos borradores y archivados), enlaces y adjuntos, sin botones de creación o edición.
- **Tablón informativo**: la vista global BOSS también muestra avisos publicados y borradores en lectura, sin controles de gestión.
- **Administración**: sigue siendo EXCLUSIVA de `admin`. BOSS no puede crear, modificar, publicar, archivar ni borrar campañas ni gestionar usuarios. `comenter`, `worker`, `viewer`, `visitante`, `turista` no cambian.
- **FICOESA Connect**: NO se modifican conversaciones privadas, roles, miembros ni políticas: es una segunda instancia independiente, con sus propios permisos de sala. El enlace a Connect ya estaba visible para BOSS, pero sus conversaciones solo se ven si están autorizadas en Connect.

## Instalación (dos pasos obligatorios)

1. Subir el contenido del ZIP al repositorio web del Directorio, respetando rutas y archivos. Se recomienda probar primero en una rama de test.
2. En **Supabase del Directorio** (NO el de Connect): entrar en **SQL Editor**, revisar y ejecutar `sql/ACTIVAR_BOSS_LECTURA_Y_COMENTARIOS.sql`. Este archivo añade políticas nuevas de lectura para BOSS y de participación en comentarios sin eliminar las políticas de los demás roles. No borra ni actualiza los datos existentes.

**El ZIP sin SQL puede mostrar los nuevos botones pero dar errores de permisos al escribir o consultar ciertos registros.** No se han ejecutado migraciones sobre vuestro servidor ni hay acceso directo desde este ZIP al esquema RLS instalado.

El usuario al que se otorgue este permiso debe existir en Supabase Authentication y tener `role='boss'` en `public.ficoesa_allowed_users`. Esta actualización **no cambia de rol a nadie automáticamente**.

## Verificación recomendada

1. Entrar como BOSS, comprobar «Vista global BOSS» y abrir una ficha publicada, una pendiente y una archivada.
2. En una pendiente, escribir una corrección, responder, marcar como realizada y reabrir. Borrar una corrección resuelta solo si es de prueba.
3. Abrir Caja de Herramientas y visualizar un recurso publicado, un borrador y uno archivado; descargar un archivo.
4. Intentar acceder directamente a `#admin-gestionar` con BOSS y verificar que la administración permanece restringida. Probar que solo ADMIN crea o elimina recursos.
5. Entrar como COMENTER, WORKER y VIEWER para comprobar que sus permisos anteriores siguen iguales.
6. Confirmar que Connect mantiene sus propios permisos de salas (no se ha abierto a BOSS el acceso a canales ajenos).
7. Si se conserva interfaz antigua tras desplegar, pulsar Ctrl+F5; en PWA también puede ser necesario actualizar el service worker.

## Limitaciones

Las comprobaciones automáticas sobre esta entrega son **locales y estáticas**; no es posible comprobar las políticas RLS reales, el contenido de Supabase ni permisos de una cuenta BOSS sin acceso a vuestra instalación. No confundir permisos del frontend con permisos de la base de datos. Antes de publicar en producción, ejecutar el SQL en el proyecto correcto y hacer las pruebas indicadas.
