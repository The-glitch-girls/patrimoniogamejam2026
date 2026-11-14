# Monitor de escenas y memoria (Godot 4.x)

`monitor_escenas.gd` agrega un diagnóstico temporal para comparar escenas activas, nodos, memoria del renderer y texturas referenciadas. Es una herramienta de desarrollo: se elimina al iniciar una compilación/exportación Release (`OS.is_debug_build() == false`). Los exports Debug y la ejecución desde el editor sí lo muestran.

## Instalarlo en otro proyecto

1. Copia `scripts/monitor_escenas.gd` al proyecto.
2. En **Project > Project Settings > Globals > Autoload**, agrega el archivo con el nombre `MonitorEscenas`.
3. Ajusta las rutas de búsqueda `_listar_texturas_del_proyecto()` si el proyecto no organiza recursos en `res://assets` y `res://resources`.
4. Ejecuta con una compilación Debug. El botón **MEMORIA** aparece en juego; al abrirlo se actualiza el detalle de escenas. **Guardar / descargar** genera un reporte.

## Salidas

- Escritorio: `user://diagnostico/navegador_memoria.jsonl`.
- Web Debug: botón HTML **Descargar log** o F10; el registro se guarda primero en `localStorage`.
- El log registra cambios de escena, cambios relevantes de memoria y muestras periódicas. El detalle de recursos se calcula en cambios de escena y al pedir un reporte manual.

## Interpretación y costo

- `RENDER_VIDEO_MEM_USED` y `RENDER_TEXTURE_MEM_USED` son contadores globales del renderer; pueden incluir texturas compartidas y caché.
- El estimado por escena usa dimensiones × 4 (RGBA sin comprimir). Sirve para comparar recursos; no equivale al uso real de VRAM después de la compresión de importación.
- El muestreo periódico es cada 5 segundos. Los escaneos detallados y la actualización de la interfaz ocurren al cambiar escena, solicitar un reporte o mientras el panel está abierto. Mantén el panel cerrado al medir el movimiento normal: el diagnóstico también consume tiempo de CPU y puede producir tirones en equipos lentos.
- Las muestras normales no se imprimen en la consola y el log de escritorio se vacía a disco cada tres muestras (hasta 15 segundos) o inmediatamente ante eventos importantes.

## Publicación

Exporta con plantilla Release y **Export With Debug desactivado**. En Release el autoload se libera al iniciar y no crea botón, panel ni registros. Usa export Debug solo para probar; ahí el monitor sigue habilitado intencionalmente.
