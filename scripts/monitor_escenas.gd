extends Node

# Registro temporal para localizar cierres por memoria en escritorio y navegador.
const INTERVALO := 2.0
const UMBRAL_CAMBIO_TEXTURA_MIB := 1.0
const RUTA_LOG := "user://diagnostico/navegador_memoria.jsonl"
const CLAVE_LOG_NAVEGADOR := "manchari_diagnostico_v1"

var _acumulado := 0.0
var _archivo: FileAccess
var _ultima_escena := ""
var _ultima_textura_mib := -1.0
var _activo := false
var _inicio_msec := 0
var _rutas_candidatas_textura := PackedStringArray()
var _actualizacion_panel := 0.0
var _boton_panel: Button
var _panel: PanelContainer
var _texto_panel: Label


func _ready() -> void:
	_activo = OS.has_feature("web") or OS.is_debug_build()
	if not _activo:
		set_process(false)
		return
	_inicio_msec = Time.get_ticks_msec()
	_listar_texturas_del_proyecto("res://assets")
	_listar_texturas_del_proyecto("res://resources")
	_crear_interfaz_diagnostico()
	if not OS.has_feature("web"):
		var carpeta := ProjectSettings.globalize_path("user://diagnostico")
		DirAccess.make_dir_recursive_absolute(carpeta)
		_archivo = FileAccess.open(RUTA_LOG, FileAccess.READ_WRITE if FileAccess.file_exists(RUTA_LOG) else FileAccess.WRITE_READ)
		if _archivo == null:
			push_warning("MonitorEscenas: no se pudo crear %s" % RUTA_LOG)
		else:
			_archivo.seek_end()
	else:
		_iniciar_log_navegador()
	_registrar("inicio", true)
	_ultima_escena = _ruta_escena_actual()


func _process(delta: float) -> void:
	_actualizacion_panel += delta
	if _actualizacion_panel >= 1.0:
		_actualizacion_panel = 0.0
		_actualizar_panel_diagnostico()
	var escena_actual := _ruta_escena_actual()
	if not escena_actual.is_empty() and escena_actual != _ultima_escena:
		_ultima_escena = escena_actual
		_acumulado = 0.0
		_registrar("cambio_escena", true)
		return
	_acumulado += delta
	if _acumulado < INTERVALO:
		return
	_acumulado = 0.0
	var textura_mib := _memoria_mib(Performance.RENDER_TEXTURE_MEM_USED)
	var hubo_cambio := _ultima_textura_mib >= 0.0 and absf(textura_mib - _ultima_textura_mib) >= UMBRAL_CAMBIO_TEXTURA_MIB
	_registrar("cambio_memoria" if hubo_cambio else "muestra", hubo_cambio)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.has_feature("web"):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		JavaScriptBridge.eval("window.__manchariDescargarDiagnostico && window.__manchariDescargarDiagnostico()", true)
		print("MonitorEscenas: descarga del diagnóstico solicitada con F10")
		get_viewport().set_input_as_handled()


func _ruta_escena_actual() -> String:
	var escena := get_tree().current_scene
	return "" if escena == null else escena.scene_file_path


func _registrar(motivo: String, incluir_detalle: bool) -> void:
	var arbol := get_tree()
	var escena := arbol.current_scene
	var lista_escenas := PackedStringArray()
	var lista_texturas := PackedStringArray()
	var texturas_cacheadas := PackedStringArray()
	if incluir_detalle:
		_resumir_escenas(arbol.root, lista_escenas)
		if escena != null:
			var texturas: Dictionary = {}
			_reunir_texturas(escena, texturas)
			for ruta in texturas.keys():
				lista_texturas.append("%s[%s]" % [ruta, texturas[ruta]])
			lista_texturas.sort()
		_reunir_texturas_cacheadas(texturas_cacheadas)
	var textura_mib := _memoria_mib(Performance.RENDER_TEXTURE_MEM_USED)
	_ultima_textura_mib = textura_mib
	var evento := {
		"tipo": motivo,
		"fecha": Time.get_datetime_string_from_system(true),
		"segundos_sesion": snappedf(float(Time.get_ticks_msec() - _inicio_msec) / 1000.0, 0.1),
		"escena": _ruta_escena_actual(),
		"nodos_escena": 0 if escena == null else _contar_nodos(escena),
		"nodos_totales": _contar_nodos(arbol.root),
		"objetos": Performance.get_monitor(Performance.OBJECT_COUNT),
		"recursos": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"huerfanos": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"memoria_estatica_mib": _memoria_mib(Performance.MEMORY_STATIC),
		"memoria_estatica_max_mib": _memoria_mib(Performance.MEMORY_STATIC_MAX),
		"video_mib": _memoria_mib(Performance.RENDER_VIDEO_MEM_USED),
		"texturas_mib": textura_mib,
		"buffers_mib": _memoria_mib(Performance.RENDER_BUFFER_MEM_USED),
		"fps": Engine.get_frames_per_second(),
		"proceso_ms": snappedf(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0, 0.1),
		"fisica_ms": snappedf(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0, 0.1),
		"escenas_instanciadas": ";".join(lista_escenas),
		"detalle_escenas_activas": _detalle_escenas_activas() if incluir_detalle else "",
		"texturas_referenciadas": ";".join(lista_texturas),
		"texturas_cacheadas": ";".join(texturas_cacheadas),
		"navegador": _metricas_navegador()
	}
	var linea := JSON.stringify(evento)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__manchariGuardarDiagnostico && window.__manchariGuardarDiagnostico(%s)" % JSON.stringify(linea), true)
	else:
		if _archivo != null:
			_archivo.store_line(linea)
			_archivo.flush()
	print("[MonitorEscenas] ", linea)


func _memoria_mib(monitor: int) -> float:
	return snappedf(float(Performance.get_monitor(monitor)) / 1048576.0, 0.1)


func _metricas_navegador() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var resultado: Variant = JavaScriptBridge.eval("window.__manchariMetricas ? window.__manchariMetricas() : '{}'", true)
	if resultado is String:
		var parseado: Variant = JSON.parse_string(resultado)
		if parseado is Dictionary:
			return parseado
	return {}


func _iniciar_log_navegador() -> void:
	var clave := JSON.stringify(CLAVE_LOG_NAVEGADOR)
	var script := """
	(() => {
		const key = %s;
		let fallbackData = '';
		const append = (line) => {
			try {
				let data = localStorage.getItem(key) || '';
				if (data.length > 3800000) {
					const cut = data.indexOf('\\n', data.length - 2800000);
					data = cut >= 0 ? data.slice(cut + 1) : data.slice(-2800000);
				}
				localStorage.setItem(key, data + line + '\\n');
			} catch (error) {
				fallbackData += line + '\\n';
				console.warn('Manchari diagnostic log storage failed', error);
			}
		};
		window.__manchariGuardarDiagnostico = append;
		window.__manchariMetricas = () => {
			const memory = performance.memory || {};
			return JSON.stringify({
				user_agent: navigator.userAgent,
					device_memory_gb: navigator.deviceMemory || null,
					js_heap_used_mib: memory.usedJSHeapSize ? Math.round(memory.usedJSHeapSize / 1048576 * 10) / 10 : null,
					js_heap_total_mib: memory.totalJSHeapSize ? Math.round(memory.totalJSHeapSize / 1048576 * 10) / 10 : null,
					js_heap_limit_mib: memory.jsHeapSizeLimit ? Math.round(memory.jsHeapSizeLimit / 1048576 * 10) / 10 : null,
					visibility: document.visibilityState
				});
		};
		window.__manchariDescargarDiagnostico = () => {
			let data = fallbackData;
			try { data = localStorage.getItem(key) || data; } catch (error) {}
			if (!data) return false;
			const url = URL.createObjectURL(new Blob([data], { type: 'application/x-ndjson' }));
			const link = document.createElement('a');
			link.href = url;
			link.download = 'manchari-diagnostico-navegador.jsonl';
			link.click();
			setTimeout(() => URL.revokeObjectURL(url), 1000);
			return true;
		};
		if (!document.getElementById('manchari-diagnostic-download')) {
			const button = document.createElement('button');
			button.id = 'manchari-diagnostic-download';
			button.type = 'button';
			button.textContent = 'Descargar log';
			button.setAttribute('aria-label', 'Descargar registro de diagnóstico');
			button.style.cssText = 'position:fixed;top:10px;right:10px;z-index:2147483647;padding:9px 13px;border:2px solid #e8d3ff;border-radius:9px;background:#21183b;color:#fff;font:600 14px system-ui,sans-serif;cursor:pointer;box-shadow:0 2px 8px #0008';
			button.addEventListener('click', () => {
				if (!window.__manchariDescargarDiagnostico()) {
					button.textContent = 'Log vacío';
					setTimeout(() => button.textContent = 'Descargar log', 1800);
				}
			});
			document.body.appendChild(button);
		}
		window.addEventListener('error', (event) => append(JSON.stringify({
			tipo: 'error_navegador', fecha: new Date().toISOString(), mensaje: event.message,
			archivo: event.filename, linea: event.lineno, columna: event.colno
		})));
		window.addEventListener('unhandledrejection', (event) => append(JSON.stringify({
			tipo: 'promesa_rechazada', fecha: new Date().toISOString(), mensaje: String(event.reason)
		})));
		return true;
	})()
	""" % clave
	JavaScriptBridge.eval(script, true)


func _contar_nodos(nodo: Node) -> int:
	var total := 1
	for hijo in nodo.get_children():
		total += _contar_nodos(hijo)
	return total


func _resumir_escenas(nodo: Node, resumen: PackedStringArray) -> void:
	if not nodo.scene_file_path.is_empty():
		resumen.append("%s#%d" % [nodo.scene_file_path, _contar_nodos(nodo)])
	for hijo in nodo.get_children():
		_resumir_escenas(hijo, resumen)


func _reunir_texturas(nodo: Node, texturas: Dictionary) -> void:
	var visitados: Dictionary = {}
	_recorrer_nodo(nodo, visitados, texturas)


func _recorrer_nodo(nodo: Node, visitados: Dictionary, texturas: Dictionary) -> void:
	for propiedad in nodo.get_property_list():
		if int(propiedad.usage) & PROPERTY_USAGE_STORAGE:
			_inspeccionar_valor(nodo.get(propiedad.name), visitados, texturas)
	for hijo in nodo.get_children():
		_recorrer_nodo(hijo, visitados, texturas)


func _inspeccionar_valor(valor: Variant, visitados: Dictionary, texturas: Dictionary) -> void:
	if valor is Texture2D:
		var textura := valor as Texture2D
		var ruta := textura.resource_path
		if ruta.is_empty():
			ruta = "subrecurso:%s" % textura.get_instance_id()
		texturas[ruta] = "%dx%d" % [textura.get_width(), textura.get_height()]
		_inspeccionar_recurso(textura, visitados, texturas)
	elif valor is Resource:
		_inspeccionar_recurso(valor as Resource, visitados, texturas)
	elif valor is Array:
		for elemento in valor:
			_inspeccionar_valor(elemento, visitados, texturas)
	elif valor is Dictionary:
		for elemento in valor.values():
			_inspeccionar_valor(elemento, visitados, texturas)


func _inspeccionar_recurso(recurso: Resource, visitados: Dictionary, texturas: Dictionary) -> void:
	var id := recurso.get_instance_id()
	if visitados.has(id):
		return
	visitados[id] = true
	for propiedad in recurso.get_property_list():
		if int(propiedad.usage) & PROPERTY_USAGE_STORAGE:
			_inspeccionar_valor(recurso.get(propiedad.name), visitados, texturas)


func _listar_texturas_del_proyecto(directorio: String) -> void:
	var acceso := DirAccess.open(directorio)
	if acceso == null:
		return
	for nombre in acceso.get_files():
		var extension := nombre.get_extension().to_lower()
		if extension in ["png", "jpg", "jpeg", "webp", "svg"]:
			_rutas_candidatas_textura.append(directorio.path_join(nombre))
	for nombre in acceso.get_directories():
		if nombre.begins_with("."):
			continue
		_listar_texturas_del_proyecto(directorio.path_join(nombre))


func _reunir_texturas_cacheadas(resumen: PackedStringArray) -> void:
	for ruta in _rutas_candidatas_textura:
		if not ResourceLoader.has_cached(ruta):
			continue
		var recurso := ResourceLoader.get_cached_ref(ruta)
		if recurso is Texture2D:
			var textura := recurso as Texture2D
			resumen.append("%s[%dx%d]" % [ruta, textura.get_width(), textura.get_height()])
	resumen.sort()


func _crear_interfaz_diagnostico() -> void:
	var capa := CanvasLayer.new()
	capa.name = "MonitorMemoriaUI"
	capa.layer = 128
	add_child(capa)

	_boton_panel = Button.new()
	_boton_panel.text = "MEMORIA"
	_boton_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_boton_panel.offset_left = -112
	_boton_panel.offset_top = -48
	_boton_panel.offset_right = -12
	_boton_panel.offset_bottom = -12
	_boton_panel.pressed.connect(_alternar_panel_diagnostico)
	capa.add_child(_boton_panel)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.offset_left = -570
	_panel.offset_top = 12
	_panel.offset_right = -12
	_panel.offset_bottom = 590
	_panel.visible = false
	capa.add_child(_panel)

	var columna := VBoxContainer.new()
	_panel.add_child(columna)
	var acciones := HBoxContainer.new()
	columna.add_child(acciones)
	var titulo := Label.new()
	titulo.text = "Diagnóstico de escenas y memoria"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acciones.add_child(titulo)
	var guardar := Button.new()
	guardar.text = "Guardar / descargar"
	guardar.pressed.connect(_guardar_diagnostico_manual)
	acciones.add_child(guardar)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(_alternar_panel_diagnostico)
	acciones.add_child(cerrar)

	var desplazamiento := ScrollContainer.new()
	desplazamiento.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(desplazamiento)
	_texto_panel = Label.new()
	_texto_panel.custom_minimum_size = Vector2(530, 1)
	_texto_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto_panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desplazamiento.add_child(_texto_panel)
	_actualizar_panel_diagnostico()


func _alternar_panel_diagnostico() -> void:
	_panel.visible = not _panel.visible
	_boton_panel.text = "CERRAR MEMORIA" if _panel.visible else "MEMORIA"
	if _panel.visible:
		_actualizar_panel_diagnostico()


func _guardar_diagnostico_manual() -> void:
	_registrar("reporte_manual", true)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__manchariDescargarDiagnostico && window.__manchariDescargarDiagnostico()", true)
	else:
		_texto_panel.text = _texto_panel.text + "\n\nRegistro guardado en:\n" + ProjectSettings.globalize_path(RUTA_LOG)


func _actualizar_panel_diagnostico() -> void:
	if not is_instance_valid(_texto_panel):
		return
	_texto_panel.text = "Video global: %.1f MiB | Texturas globales: %.1f MiB | Memoria estática: %.1f MiB\nFPS: %d | Nodos totales: %d\n\nESCENAS ACTIVAS (cada una con nodos, texturas directas y estimación RGBA):\n%s\n\nLa estimación por escena es ancho × alto × 4; el contador global de video lo informa el renderer y puede incluir recursos compartidos/caché." % [
		_memoria_mib(Performance.RENDER_VIDEO_MEM_USED),
		_memoria_mib(Performance.RENDER_TEXTURE_MEM_USED),
		_memoria_mib(Performance.MEMORY_STATIC),
		Engine.get_frames_per_second(),
		_contar_nodos(get_tree().root),
		_detalle_escenas_activas()
	]


func _detalle_escenas_activas() -> String:
	var filas := PackedStringArray()
	_recorrer_escenas_activas(get_tree().root, filas)
	return "\n".join(filas) if not filas.is_empty() else "No se encontraron escenas instanciadas."


func _recorrer_escenas_activas(nodo: Node, filas: PackedStringArray) -> void:
	if not nodo.scene_file_path.is_empty():
		var texturas: Dictionary = {}
		_reunir_texturas_escena(nodo, nodo, texturas)
		var estimado_bytes := 0
		var recursos := PackedStringArray()
		for ruta in texturas.keys():
			var dato: Dictionary = texturas[ruta]
			estimado_bytes += int(dato.bytes)
			recursos.append("%s %dx%d" % [ruta, dato.ancho, dato.alto])
		recursos.sort()
		var listado := "\n    " + "\n    ".join(recursos) if not recursos.is_empty() else "\n    (sin texturas directas detectadas)"
		filas.append("• %s | %d nodos | ~%.1f MiB texturas RGBA%s" % [nodo.scene_file_path, _contar_nodos(nodo), float(estimado_bytes) / 1048576.0, listado])
	for hijo in nodo.get_children():
		_recorrer_escenas_activas(hijo, filas)


func _reunir_texturas_escena(nodo: Node, raiz_escena: Node, texturas: Dictionary) -> void:
	if nodo != raiz_escena and not nodo.scene_file_path.is_empty():
		return
	var visitados: Dictionary = {}
	for propiedad in nodo.get_property_list():
		if int(propiedad.usage) & PROPERTY_USAGE_STORAGE:
			_inspeccionar_texturas_escena(nodo.get(propiedad.name), visitados, texturas)
	for hijo in nodo.get_children():
		_reunir_texturas_escena(hijo, raiz_escena, texturas)


func _inspeccionar_texturas_escena(valor: Variant, visitados: Dictionary, texturas: Dictionary) -> void:
	if valor is AtlasTexture:
		_inspeccionar_texturas_escena((valor as AtlasTexture).atlas, visitados, texturas)
	elif valor is Texture2D:
		var textura := valor as Texture2D
		var ruta := textura.resource_path
		if ruta.is_empty():
			ruta = "subrecurso:%d" % textura.get_instance_id()
		texturas[ruta] = {
			"ancho": textura.get_width(),
			"alto": textura.get_height(),
			"bytes": textura.get_width() * textura.get_height() * 4
		}
	elif valor is Resource:
		var recurso := valor as Resource
		if visitados.has(recurso.get_instance_id()):
			return
		visitados[recurso.get_instance_id()] = true
		for propiedad in recurso.get_property_list():
			if int(propiedad.usage) & PROPERTY_USAGE_STORAGE:
				_inspeccionar_texturas_escena(recurso.get(propiedad.name), visitados, texturas)
	elif valor is Array:
		for elemento in valor:
			_inspeccionar_texturas_escena(elemento, visitados, texturas)
	elif valor is Dictionary:
		for elemento in valor.values():
			_inspeccionar_texturas_escena(elemento, visitados, texturas)
