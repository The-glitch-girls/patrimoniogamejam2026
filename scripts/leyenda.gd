extends Control

const FUENTE := preload("res://assets/fonts/chelsea-market/ChelseaMarket-Regular.ttf")
const TEXTURA_ZORRO: Texture2D = preload("res://assets/tiles/Zorro.png")
const COLOR_TEXTO := Color("f4e9ff")
const COLOR_MARCO := Color("c1a4ea")
const ESCENA_MAIN := "res://scenes/Main.tscn"
const COLOR_LUZ := Color("b9a2ff")

@onready var sombra: ColorRect = $Sombra
@onready var panel: PanelContainer = $PanelRelato
@onready var titulo: Label = $PanelRelato/Margen/Columna/Titulo
@onready var texto: Label = $PanelRelato/Margen/Columna/Texto
@onready var continuar: Button = $Continuar
@onready var narracion: AudioStreamPlayer = $Narracion
@onready var fundido: ColorRect = $Fundido

var transicionando := false
var tiempo_efectos := 0.0
var progreso_grupo := 0.0
var salto_rapido := false
var tiempo_relatado := 0.0
var duracion_relatado := 0.0
var seguir_relatado := false
var foco_inicio := Vector2.ZERO
var foco_destino := Vector2.ZERO
var particulas: Array[Dictionary] = []
var rectangulos_grupos: Array[Rect2] = []
var limites_tiempo_grupos: Array[float] = []
var zorro: AnimatedSprite2D
var material_revelado: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	titulo.text = Traducciones.obtener("legend_title")
	texto.text = Traducciones.obtener("legend_text")
	texto.visible_characters = -1
	continuar.text = Traducciones.obtener("continue")
	continuar.visible = false
	continuar.disabled = true
	continuar.pressed.connect(_continuar)
	_estilizar()
	_poner_zorro_en_primer_plano()
	_crear_luces_errantes()
	_preparar_revelado_por_luz()
	move_child(zorro, fundido.get_index())
	await _animar_entrada()
	await _relatar()
	continuar.visible = true
	var tween_boton := create_tween()
	tween_boton.tween_property(continuar, "modulate:a", 1.0, 0.3)


func _process(delta: float) -> void:
	tiempo_efectos += delta
	if seguir_relatado:
		if narracion.playing:
			tiempo_relatado = minf(narracion.get_playback_position(), duracion_relatado)
		else:
			tiempo_relatado = minf(tiempo_relatado + delta, duracion_relatado)
		_actualizar_enfoque_luces()
	for particula in particulas:
		var desplazamiento: Vector2 = particula.desplazamiento
		var inicio := foco_inicio + desplazamiento
		var final := foco_destino + desplazamiento
		var progreso := clampf(progreso_grupo, 0.0, 1.0)
		var posicion: Vector2
		if salto_rapido:
			posicion = inicio.lerp(final, progreso)
		else:
			var control := (foco_inicio + foco_destino) * 0.5 + desplazamiento + Vector2(0.0, -18.0)
			posicion = _punto_curvo(inicio, control, final, progreso)
		var parpadeo := 0.5 + 0.5 * sin(tiempo_efectos * particula.parpadeo + particula.fase * TAU)
		var intensidad := 0.42 + parpadeo * 0.58
		var resplandor: TextureRect = particula.resplandor
		var estrella: Polygon2D = particula.estrella
		resplandor.position = posicion - resplandor.size * 0.5
		resplandor.modulate.a = intensidad * 0.78
		estrella.position = posicion
		estrella.modulate.a = intensidad * 0.95
		estrella.scale = Vector2.ONE * (0.7 + parpadeo * 0.45)
		if material_revelado != null:
			material_revelado.set_shader_parameter("luz_%s" % particula.indice, posicion / get_viewport_rect().size)
			material_revelado.set_shader_parameter("intensidad_%s" % particula.indice, intensidad)
	if is_instance_valid(zorro):
		var pulso_zorro := 0.5 + 0.5 * sin(tiempo_efectos * 0.72)
		zorro.modulate.a = 0.82 + pulso_zorro * 0.14
		zorro.position.y = 570.0 + sin(tiempo_efectos * 0.55) * 2.5


func _poner_zorro_en_primer_plano() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("quieto")
	frames.set_animation_loop("quieto", true)
	frames.set_animation_speed("quieto", 1.0)
	var marco := AtlasTexture.new()
	marco.atlas = TEXTURA_ZORRO
	marco.region = Rect2(256, 1450, 2200, 2200)
	marco.filter_clip = true
	frames.add_frame("quieto", marco)
	zorro = AnimatedSprite2D.new()
	zorro.name = "ZorroEnLaSombra"
	zorro.sprite_frames = frames
	zorro.position = Vector2(1150.0, 570.0)
	zorro.scale = Vector2(0.06, 0.06)
	zorro.flip_h = true
	zorro.modulate = Color(0.68, 0.48, 0.82, 0.9)
	add_child(zorro)
	move_child(zorro, panel.get_index() + 1)
	zorro.play("quieto")


func _crear_luces_errantes() -> void:
	var gradiente := Gradient.new()
	gradiente.colors = [Color(COLOR_LUZ.r, COLOR_LUZ.g, COLOR_LUZ.b, 0.5), Color(COLOR_LUZ.r, COLOR_LUZ.g, COLOR_LUZ.b, 0.0)]
	gradiente.offsets = [0.0, 1.0]
	var textura_luz := GradientTexture2D.new()
	textura_luz.gradient = gradiente
	textura_luz.width = 128
	textura_luz.height = 128
	textura_luz.fill = GradientTexture2D.FILL_RADIAL
	textura_luz.fill_from = Vector2(0.5, 0.5)
	textura_luz.fill_to = Vector2(0.5, 0.0)
	var material_aditivo := CanvasItemMaterial.new()
	material_aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var capa_efectos := Node2D.new()
	capa_efectos.name = "LucesErrantes"
	add_child(capa_efectos)
	move_child(capa_efectos, continuar.get_index())
	var desplazamientos := [Vector2(-19.0, -5.0), Vector2.ZERO, Vector2(19.0, 4.0)]
	var parpadeos := [5.1, 4.2, 6.0]
	var fases := [0.02, 0.39, 0.68]
	for indice in range(desplazamientos.size()):
		var resplandor := TextureRect.new()
		resplandor.name = "ResplandorEstrella"
		resplandor.texture = textura_luz
		resplandor.size = Vector2(164, 164)
		resplandor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resplandor.modulate.a = 0.0
		resplandor.hide()
		resplandor.material = material_aditivo
		capa_efectos.add_child(resplandor)
		var estrella := Polygon2D.new()
		estrella.name = "Destello"
		estrella.polygon = PackedVector2Array([
			Vector2(0, -7), Vector2(2, -2), Vector2(7, 0), Vector2(2, 2),
			Vector2(0, 7), Vector2(-2, 2), Vector2(-7, 0), Vector2(-2, -2),
		])
		estrella.color = Color("eee2ff")
		estrella.modulate.a = 0.0
		estrella.hide()
		estrella.material = material_aditivo
		capa_efectos.add_child(estrella)
		particulas.append({
			"desplazamiento": desplazamientos[indice],
			"fase": fases[indice],
			"parpadeo": parpadeos[indice],
			"indice": particulas.size(),
			"resplandor": resplandor,
			"estrella": estrella,
		})


func _punto_curvo(inicio: Vector2, control: Vector2, final: Vector2, t: float) -> Vector2:
	return inicio * pow(1.0 - t, 2.0) + control * 2.0 * (1.0 - t) * t + final * pow(t, 2.0)


func _preparar_revelado_por_luz() -> void:
	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform vec2 luz_0 = vec2(0.25, 0.45);
	uniform vec2 luz_1 = vec2(0.50, 0.50);
	uniform vec2 luz_2 = vec2(0.75, 0.45);
	uniform float intensidad_0 = 0.0;
	uniform float intensidad_1 = 0.0;
	uniform float intensidad_2 = 0.0;
	void fragment() {
		vec4 glifo = texture(TEXTURE, UV) * COLOR;
		float d0 = distance(SCREEN_UV, luz_0);
		float d1 = distance(SCREEN_UV, luz_1);
		float d2 = distance(SCREEN_UV, luz_2);
		float r0 = (1.0 - smoothstep(0.015, 0.115, d0)) * intensidad_0;
		float r1 = (1.0 - smoothstep(0.015, 0.115, d1)) * intensidad_1;
		float r2 = (1.0 - smoothstep(0.015, 0.115, d2)) * intensidad_2;
		float revelar = max(r0, max(r1, r2));
		glifo.rgb = mix(glifo.rgb * 0.48, vec3(0.96, 0.90, 1.0), revelar);
		glifo.a *= mix(0.72, 1.0, revelar);
		COLOR = glifo;
	}
	"""
	material_revelado = ShaderMaterial.new()
	material_revelado.shader = shader
	texto.material = material_revelado


func _estilizar() -> void:
	for etiqueta in [titulo, texto]:
		etiqueta.add_theme_font_override("font", FUENTE)
		etiqueta.add_theme_color_override("font_color", COLOR_TEXTO)
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 20)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var panel_estilo := StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", panel_estilo)
	var boton_estilo := StyleBoxFlat.new()
	boton_estilo.bg_color = Color(0.22, 0.13, 0.42, 1.0)
	boton_estilo.set_corner_radius_all(18)
	boton_estilo.set_border_width_all(2)
	boton_estilo.border_color = COLOR_MARCO
	for estado in ["normal", "hover", "pressed", "disabled"]:
		continuar.add_theme_stylebox_override(estado, boton_estilo)
	continuar.add_theme_font_override("font", FUENTE)
	continuar.add_theme_font_size_override("font_size", 18)
	continuar.add_theme_color_override("font_color", COLOR_TEXTO)
	continuar.add_theme_color_override("font_hover_color", COLOR_TEXTO)
	continuar.modulate.a = 0.0


func _animar_entrada() -> void:
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.98, 0.98)
	sombra.color.a = 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sombra, "color:a", 0.74, 0.9)
	tween.tween_property(panel, "modulate:a", 1.0, 0.75)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.9)
	await tween.finished


func _relatar() -> void:
	await get_tree().process_frame
	var grupos := _obtener_grupos_de_palabras()
	if grupos.is_empty():
		var centro_respaldo := texto.get_global_transform_with_canvas() * (texto.size * 0.5)
		grupos.append({"rect": Rect2(centro_respaldo - Vector2.ONE, Vector2(2, 2)), "peso": 1.0})
	rectangulos_grupos.clear()
	var peso_total := 0.0
	for grupo in grupos:
		rectangulos_grupos.append(grupo.rect)
		peso_total += grupo.peso
	limites_tiempo_grupos.clear()
	var acumulado := 0.0
	for grupo in grupos:
		acumulado += grupo.peso / maxf(peso_total, 0.001)
		limites_tiempo_grupos.append(acumulado)
	foco_inicio = Vector2(rectangulos_grupos[0].position.x, rectangulos_grupos[0].get_center().y)
	foco_destino = Vector2(rectangulos_grupos[0].end.x, rectangulos_grupos[0].get_center().y)
	for particula in particulas:
		var resplandor: TextureRect = particula.resplandor
		var estrella: Polygon2D = particula.estrella
		resplandor.show()
		estrella.show()
	duracion_relatado = maxf(float(maxi(texto.text.length(), 1)) / 30.0, 1.0)
	if narracion.stream != null:
		duracion_relatado = maxf(narracion.stream.get_length(), 0.1)
		narracion.play()
	tiempo_relatado = 0.0
	seguir_relatado = true
	_actualizar_enfoque_luces()
	if narracion.playing:
		while narracion.playing:
			await get_tree().process_frame
	else:
		while tiempo_relatado < duracion_relatado:
			await get_tree().process_frame
	tiempo_relatado = duracion_relatado
	_actualizar_enfoque_luces()
	seguir_relatado = false
	continuar.disabled = false


func _actualizar_enfoque_luces() -> void:
	if rectangulos_grupos.is_empty() or limites_tiempo_grupos.is_empty():
		return
	var avance := clampf(tiempo_relatado / maxf(duracion_relatado, 0.001), 0.0, 1.0)
	var indice_grupo := limites_tiempo_grupos.size() - 1
	for indice in range(limites_tiempo_grupos.size()):
		if avance <= limites_tiempo_grupos[indice]:
			indice_grupo = indice
			break
	var inicio_intervalo := 0.0 if indice_grupo == 0 else limites_tiempo_grupos[indice_grupo - 1]
	var fin_intervalo: float = limites_tiempo_grupos[indice_grupo]
	var tramo := maxf(fin_intervalo - inicio_intervalo, 0.001)
	var avance_local := clampf((avance - inicio_intervalo) / tramo, 0.0, 1.0)
	var grupo_actual := rectangulos_grupos[indice_grupo]
	var y_actual := grupo_actual.get_center().y
	var inicio_x_actual := grupo_actual.position.x - 5.0
	var final_x_actual := grupo_actual.end.x + 5.0
	if indice_grupo == 0:
		salto_rapido = false
		foco_inicio = Vector2(inicio_x_actual, y_actual)
		foco_destino = Vector2(final_x_actual, y_actual)
		progreso_grupo = avance_local
		return
	var grupo_anterior := rectangulos_grupos[indice_grupo - 1]
	var y_anterior := grupo_anterior.get_center().y
	var salto_de_renglon := y_actual > y_anterior + float(texto.get_line_height()) * 0.5
	if salto_de_renglon:
		var duracion_tramo := tramo * duracion_relatado
		# El salto entre renglones es solo un cambio de posición; los '\n' no
		# reciben un tramo propio ni hacen que la luz se detenga en el centro.
		var fraccion_salto := minf(0.045, duracion_tramo * 0.08) / maxf(duracion_tramo, 0.001)
		if avance_local < fraccion_salto:
			salto_rapido = true
			foco_inicio = Vector2(grupo_anterior.end.x + 5.0, y_anterior)
			foco_destino = Vector2(inicio_x_actual, y_actual)
			progreso_grupo = avance_local / maxf(fraccion_salto, 0.001)
		else:
			salto_rapido = false
			foco_inicio = Vector2(inicio_x_actual, y_actual)
			foco_destino = Vector2(final_x_actual, y_actual)
			progreso_grupo = (avance_local - fraccion_salto) / maxf(1.0 - fraccion_salto, 0.001)
	else:
		salto_rapido = false
		foco_inicio = Vector2(grupo_anterior.end.x + 5.0, y_actual)
		foco_destino = Vector2(final_x_actual, y_actual)
		progreso_grupo = avance_local


func _obtener_grupos_de_palabras() -> Array[Dictionary]:
	var grupos: Array[Dictionary] = []
	var contenido := texto.text
	var indice := 0
	var palabras_en_grupo := 0
	var limites_grupo := Rect2()
	var peso_grupo := 0.0
	var linea_grupo_y := 0.0
	var cambio_linea := float(texto.get_line_height()) * 0.55
	while indice < contenido.length():
		while indice < contenido.length() and contenido.substr(indice, 1).strip_edges().is_empty():
			indice += 1
		if indice >= contenido.length():
			break
		var limites_palabra := Rect2()
		var tiene_limites := false
		while indice < contenido.length() and not contenido.substr(indice, 1).strip_edges().is_empty():
			var limites_caracter := texto.get_character_bounds(indice)
			if not limites_caracter.size.is_zero_approx():
				if tiene_limites:
					limites_palabra = limites_palabra.merge(limites_caracter)
				else:
					limites_palabra = limites_caracter
					tiene_limites = true
			indice += 1
		if tiene_limites:
			var centro_palabra_y := limites_palabra.get_center().y
			if palabras_en_grupo > 0 and absf(centro_palabra_y - linea_grupo_y) > cambio_linea:
				_guardar_grupo_de_palabras(grupos, limites_grupo, peso_grupo)
				palabras_en_grupo = 0
				peso_grupo = 0.0
			if palabras_en_grupo == 0:
				limites_grupo = limites_palabra
				linea_grupo_y = centro_palabra_y
			else:
				limites_grupo = limites_grupo.merge(limites_palabra)
			palabras_en_grupo += 1
			peso_grupo += _peso_palabra(contenido, indice)
			if palabras_en_grupo == 3:
				_guardar_grupo_de_palabras(grupos, limites_grupo, peso_grupo)
				palabras_en_grupo = 0
				peso_grupo = 0.0
	if palabras_en_grupo > 0 and not limites_grupo.size.is_zero_approx():
		_guardar_grupo_de_palabras(grupos, limites_grupo, peso_grupo)
	return grupos


func _guardar_grupo_de_palabras(grupos: Array[Dictionary], limites_locales: Rect2, peso: float) -> void:
	if limites_locales.size.is_zero_approx():
		return
	var transformacion := texto.get_global_transform_with_canvas()
	var esquina_inicio := transformacion * limites_locales.position
	var esquina_final := transformacion * limites_locales.end
	grupos.append({"rect": Rect2(esquina_inicio, esquina_final - esquina_inicio), "peso": peso})


func _peso_palabra(contenido: String, fin_palabra: int) -> float:
	var peso := 1.0
	var ultimo_caracter := contenido.substr(fin_palabra - 1, 1)
	if ultimo_caracter in [",", "，"]:
		peso += 0.45
	elif ultimo_caracter in [".", "!", "?", "…"]:
		peso += 0.9
	elif ultimo_caracter in [";", ":"]:
		peso += 0.6
	return peso


func _unhandled_input(event: InputEvent) -> void:
	if continuar.disabled or transicionando:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE, KEY_E]:
			_continuar()


func _continuar() -> void:
	if transicionando or continuar.disabled:
		return
	transicionando = true
	continuar.disabled = true
	if narracion.playing:
		narracion.stop()
	fundido.visible = true
	fundido.color.a = 0.0
	var tween := create_tween()
	tween.tween_property(fundido, "color:a", 1.0, 0.65)
	await tween.finished
	get_tree().change_scene_to_file(ESCENA_MAIN)
