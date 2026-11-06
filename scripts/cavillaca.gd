extends CharacterBody2D

const LIMITE_ARRIBA_JUGADOR := 180.0
const LIMITE_ABAJO_JUGADOR := 180.0
const VELOCIDAD_CAMINAR := 225.0
const VELOCIDAD_CORRER := 300.0
const VELOCIDAD_CON_BEBE := 180.0
const VELOCIDAD_SIN_ENERGIA := 100.0
# Velocidad de la animación de caminata sin bebé
const ESCALA_ANIM_CAMINAR := 1.7
# Al correr, la animación acelera en la misma proporción que la velocidad
# (300/225 ≈ 1.33) para que los pies no patinen. Falta arte propio de correr (#11).
const ESCALA_ANIM_CORRER := ESCALA_ANIM_CAMINAR * VELOCIDAD_CORRER / VELOCIDAD_CAMINAR
const DISTANCIA_RECOGER := 56.0
const DISTANCIA_DEJAR := 40.0
const ACELERACION := 900.0
const FRENADO := 1200.0
const ACELERACION_CON_BEBE := 420.0
const LOCK_TRAS_DEJAR := 0.35
const COOLDOWN_ARROJAR := 0.35
const ORIGEN_CAVILLACA := Vector2(13, 11)

const PIEDRA_ESCENA := preload("res://scenes/Piedra.tscn")
const PASOS := [
	preload("res://sfx/paso_0.ogg"),
	preload("res://sfx/paso_1.ogg"),
	preload("res://sfx/paso_2.ogg"),
]
const ATAQUE := preload("res://sfx/combate/piedra_lanzada.ogg")

var FRAMES_LADO: Array[Texture2D]

var animaciones_cavillaca: SpriteFrames
var sheet_lado := preload("res://assets/person/cavillaca_lateral2.png")

var energia_temporizador := 0.0
var facing := Vector2.RIGHT
var lock_interaccion := 0.0
var lock_arrojar := 0.0
var paso_acum := 0.0
var mar_t := 0.0
var cam: Camera2D
var suelo_tiles: TileMapLayer
var sfx_paso: AudioStreamPlayer
var sfx_ataque: AudioStreamPlayer
var ataques_combate := 0
var preparando_caminata_mar := false
var caminata_mar_preparada := false

func _ready():
	_asegurar_tecla_dialogo_zorro()
	FRAMES_LADO = _crear_frames_sheet(sheet_lado, 6, 512)
	animaciones_cavillaca = $Sprite.sprite_frames
	
	add_to_group("cavillaca")
	motion_mode = MOTION_MODE_FLOATING
	_armar_sfx()
	_armar_sprite()
	_aplicar_animaciones_cargadas()

	$Sprite.scale = Vector2(0.215, 0.215)
	$Sprite.position.y = 0
	$CollisionShape2D.position.y = 60
	suelo_tiles = get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	
	cam = Camera2D.new()
	cam.zoom = Vector2(1.0, 1.0)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	_configurar_limites_camara()
	cam.make_current()


func _configurar_limites_camara() -> void:
	var suelo := get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	if suelo == null or suelo.tile_set == null:
		return

	var celdas := suelo.get_used_rect()
	if celdas.size == Vector2i.ZERO:
		return
	_rellenar_huecos.call_deferred(suelo, celdas)

	var tamano_celda := Vector2(suelo.tile_set.tile_size)
	var esquina_superior_izquierda := suelo.to_global(
		suelo.map_to_local(celdas.position) - tamano_celda * 0.5
	)
	var esquina_inferior_derecha := suelo.to_global(
		suelo.map_to_local(celdas.end - Vector2i.ONE) + tamano_celda * 0.5
	)
	cam.limit_left = floori(esquina_superior_izquierda.x)
	cam.limit_top = floori(esquina_superior_izquierda.y)
	cam.limit_right = ceili(esquina_inferior_derecha.x)
	cam.limit_bottom = ceili(esquina_inferior_derecha.y)



# Pinta los huecos del rectángulo con suelo y árboles en capas decorativas,
# para que la cámara no muestre vacío. No toca SueloTiles: no se pueden pisar.
func _rellenar_huecos(suelo: TileMapLayer, r: Rect2i) -> void:
	var escena := get_tree().current_scene
	var copa := escena.get_node_or_null("DecoracionTop") as TileMapLayer
	if copa == null:
		return
	var fondo := TileMapLayer.new()
	fondo.name = "RellenoSuelo"
	fondo.tile_set = suelo.tile_set
	fondo.transform = suelo.transform
	fondo.z_index = -10
	var arboles := TileMapLayer.new()
	arboles.name = "RellenoArboles"
	arboles.tile_set = copa.tile_set
	arboles.transform = copa.transform
	arboles.z_index = -1
	escena.add_child(fondo)
	escena.move_child(fondo, suelo.get_index())
	escena.add_child(arboles)
	escena.move_child(arboles, suelo.get_index() + 1)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if suelo.get_cell_source_id(Vector2i(x, y)) == -1:
				fondo.set_cell(Vector2i(x, y), 2, Vector2i(0, 0))
	# Árbol completo del tileset: copa 3x2 (filas 14-15) y tronco (1,16)-(1,17).
	for y in range(r.position.y, r.end.y - 3, 4):
		for x in range(r.position.x, r.end.x - 2, 3):
			if _bloque_libre(suelo, Vector2i(x, y)):
				for dy in 2:
					for dx in 3:
						arboles.set_cell(Vector2i(x + dx, y + dy), 2, Vector2i(dx, 14 + dy))
				arboles.set_cell(Vector2i(x + 1, y + 2), 2, Vector2i(1, 16))
				arboles.set_cell(Vector2i(x + 1, y + 3), 2, Vector2i(1, 17))


func _bloque_libre(suelo: TileMapLayer, origen: Vector2i) -> bool:
	for dy in range(-1, 5):
		for dx in range(-1, 4):
			var c := origen + Vector2i(dx, dy)
			if suelo.get_used_rect().has_point(c) and suelo.get_cell_source_id(c) != -1:
				return false
	return true


func _asegurar_tecla_dialogo_zorro() -> void:
	# En algunos proyectos F quedó agregada también a "atacar".
	# Se reserva F para hablar y se evita que abra el combate por accidente.
	if not InputMap.has_action("hablar_zorro"):
		InputMap.add_action("hablar_zorro")

	var tecla_f := InputEventKey.new()
	tecla_f.physical_keycode = KEY_F
	var f_asignada_a_hablar := false
	for evento in InputMap.action_get_events("hablar_zorro"):
		if evento is InputEventKey:
			var tecla := evento as InputEventKey
			if tecla.physical_keycode == KEY_F or tecla.keycode == KEY_F:
				f_asignada_a_hablar = true
				break
	if not f_asignada_a_hablar:
		InputMap.action_add_event("hablar_zorro", tecla_f)

	for evento in InputMap.action_get_events("atacar"):
		if evento is InputEventKey:
			var tecla := evento as InputEventKey
			if tecla.physical_keycode == KEY_F or tecla.keycode == KEY_F:
				InputMap.action_erase_event("atacar", evento)


func _aplicar_animaciones_cargadas() -> void:
	if animaciones_cavillaca == null:
		return
	for nombre in [&"espalda", &"frente", &"espalda_bebe", &"frente_bebe", &"lado_bebe"]:
		_copiar_animacion($Sprite.sprite_frames, nombre)

func _armar_sfx() -> void:
	sfx_paso = AudioStreamPlayer.new()
	sfx_paso.bus = "SFX"
	sfx_paso.volume_db = -6.0
	add_child(sfx_paso)
	sfx_ataque = AudioStreamPlayer.new()
	sfx_ataque.bus = "SFX"
	sfx_ataque.stream = ATAQUE
	sfx_ataque.volume_db = -8.0
	add_child(sfx_ataque)


func _armar_sprite() -> void:
	var hojas := SpriteFrames.new()
	_poner_anim(hojas, "idle_lado", [FRAMES_LADO[0]], 1.0)
	_poner_anim(hojas, "walk_lado", FRAMES_LADO, 8.0)
	$Sprite.sprite_frames = hojas
	$Sprite.play("idle_lado")


func _copiar_animacion(destino: SpriteFrames, nombre: StringName) -> void:
	destino.add_animation(nombre)
	destino.set_animation_speed(nombre, animaciones_cavillaca.get_animation_speed(nombre))
	destino.set_animation_loop(nombre, animaciones_cavillaca.get_animation_loop(nombre))
	for indice in range(animaciones_cavillaca.get_frame_count(nombre)):
		var textura := animaciones_cavillaca.get_frame_texture(nombre, indice)
		destino.add_frame(
			nombre,
			textura,
			animaciones_cavillaca.get_frame_duration(nombre, indice)
		)


func _poner_anim(hojas: SpriteFrames, nombre: String, texturas: Array, velocidad: float) -> void:
	hojas.add_animation(nombre)
	hojas.set_animation_speed(nombre, velocidad)
	hojas.set_animation_loop(nombre, true)
	for textura in texturas:
		hojas.add_frame(nombre, textura)


func _physics_process(delta):
	if lock_arrojar > 0.0:
		lock_arrojar = max(lock_arrojar - delta, 0.0)
	_reproducir_clic_accion_teclado()
	if _controlar_ataque():
		return
		
	if Global.hacia_el_mar:
		if not caminata_mar_preparada:
			if not preparando_caminata_mar:
				_transicionar_al_origen_mar()
			return
		_caminar_al_mar(delta)
		return

	if lock_interaccion > 0.0:
		lock_interaccion = max(lock_interaccion - delta, 0.0)

	if Input.is_action_just_pressed("interactuar") and lock_interaccion <= 0.0:
		var cueva := get_tree().get_first_node_in_group("zona_segura")
		var bebe_con_zorro: bool = cueva != null and bool(cueva.get("bebe_con_zorro"))

		if Global.zorro_cerca and Global.cuidado_bebe_desbloqueado and cueva != null:
			if Global.lleva_bebe:
				cueva.dejar_bebe_con_zorro()
			elif bebe_con_zorro:
				cueva.recoger_bebe_del_zorro()
		elif Global.lleva_bebe:
			_dejar_bebe()
		elif Global.zorro_cerca and Global.recuerdos_obtenidos == 0:
			pass # Hablar con el zorro se activa únicamente con F.
		else:
			_recoger_bebe()

	if Input.is_action_just_pressed("hablar_zorro") and Global.zorro_cerca:
		var zorro := get_tree().get_first_node_in_group("zorro")
		if zorro != null:
			zorro.hablar()
	elif Input.is_action_just_pressed("hablar_zorro") and Global.loro_cerca:
		var loro := get_tree().get_first_node_in_group("loro")
		if loro != null:
			loro.hablar()

	if Input.is_action_just_pressed("descansar"):
		var cueva_descanso := get_tree().get_first_node_in_group("zona_segura")
		if cueva_descanso != null:
			cueva_descanso.descansar()

	var direccion := _direccion_cuatro()
	if direccion != Vector2.ZERO:
		facing = direccion

	var esta_corriendo: bool = (
		not Global.lleva_bebe
		and Global.energia > 0.0
		and Input.is_action_pressed("correr")
	)

	var velocidad_objetivo := VELOCIDAD_CAMINAR
	if Global.lleva_bebe:
		velocidad_objetivo = VELOCIDAD_CON_BEBE
	elif esta_corriendo:
		velocidad_objetivo = VELOCIDAD_CORRER

	if Global.energia <= 0.0:
		velocidad_objetivo = min(velocidad_objetivo, VELOCIDAD_SIN_ENERGIA)

	var aceleracion := FRENADO if direccion == Vector2.ZERO else ACELERACION
	if Global.lleva_bebe:
		aceleracion = ACELERACION_CON_BEBE

	velocity = velocity.move_toward(direccion * velocidad_objetivo, aceleracion * delta)
	_limitar_movimiento_al_suelo(delta)
	move_and_slide()
	
	# El suelo vive en z negativo. La Y del mapa tambien, asi que no se puede usar como z.
	z_index = 1

	if cam.global_position.y <= cam.limit_top:
		global_position.y = min(global_position.y, cam.global_position.y)

	global_position.x = clamp(
		global_position.x,
		Global.LIMITE_MAPA.position.x + 20.0,
		Global.LIMITE_MAPA.end.x - 20.0
	)

	global_position.y = clamp(
		global_position.y,
		Global.LIMITE_MAPA.position.y + LIMITE_ARRIBA_JUGADOR,
		Global.LIMITE_MAPA.end.y - LIMITE_ABAJO_JUGADOR
	)

	var esta_caminando := velocity.length() > 12.0
	_animar_caminata(delta, esta_caminando, esta_corriendo)
	_actualizar_camara(delta)
	_actualizar_prompt()
	_actualizar_carga_visual()

	if direccion == Vector2.ZERO:
		return

	energia_temporizador += delta
	if energia_temporizador < 1.0:
		return

	energia_temporizador = 0.0
	if Global.lleva_bebe:
		Global.perder_energia(Global.COSTO_CARGAR_BEBE)
	elif esta_corriendo:
		Global.perder_energia(Global.COSTO_CORRER)
	else:
		Global.perder_energia(Global.COSTO_CAMINAR)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not (event is InputEventKey):
		return
	var tecla := event as InputEventKey
	# Probar halcon
	if tecla.pressed and not tecla.echo and (tecla.keycode == KEY_F8 or tecla.physical_keycode == KEY_F8):
		var halcon := get_tree().get_first_node_in_group("halcon")
		if halcon != null and halcon.has_method("debug_aparecer_al_lado"):
			halcon.debug_aparecer_al_lado(global_position + Vector2(180.0, 0.0))
	elif tecla.pressed and not tecla.echo and (tecla.keycode == KEY_F9 or tecla.physical_keycode == KEY_F9):
		var cuniraya := get_parent().get_node_or_null("Cuniraya")
		if cuniraya != null and cuniraya.has_method("debug_acercar_a_bebe"):
			cuniraya.debug_acercar_a_bebe()


func _transicionar_al_origen_mar() -> void:
	preparando_caminata_mar = true
	velocity = Vector2.ZERO
	var capa_transicion := CanvasLayer.new()
	capa_transicion.layer = 20
	var fundido := ColorRect.new()
	fundido.color = Color("51438f")
	fundido.color.a = 0.0
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_transicion.add_child(fundido)
	get_tree().current_scene.add_child(capa_transicion)
	var fundir_a_violeta := create_tween()
	fundir_a_violeta.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fundir_a_violeta.tween_property(fundido, "color:a", 1.0, 1.25)
	await fundir_a_violeta.finished
	if not is_inside_tree():
		return
	Global.lleva_bebe = true
	_ocultar_sprite_bebe()
	if cam != null:
		cam.position_smoothing_enabled = false
	global_position = _posicion_celda_mapa(ORIGEN_CAVILLACA)
	velocity = Vector2.ZERO
	mar_t = 0.0
	facing = _cardinal(_posicion_celda_mapa(Global.DESTINO_MAR) - global_position)
	_animar_caminata(0.0, false, false)
	_actualizar_carga_visual()
	if cam != null:
		cam.reset_smoothing()
	await get_tree().create_timer(0.2).timeout
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if cam != null:
		cam.position_smoothing_enabled = true
	var revelar_mapa := create_tween()
	revelar_mapa.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	revelar_mapa.tween_property(fundido, "color:a", 0.0, 1.25)
	await revelar_mapa.finished
	if not is_inside_tree():
		return
	capa_transicion.queue_free()
	preparando_caminata_mar = false
	caminata_mar_preparada = true


func _posicion_celda_mapa(coordenadas: Vector2) -> Vector2:
	var suelo := get_tree().current_scene.get_node("SueloTiles") as TileMapLayer
	return suelo.to_global(suelo.map_to_local(Vector2i(coordenadas)))


func _caminar_al_mar(delta: float) -> void:
	mar_t += delta
	var destino := _posicion_celda_mapa(Global.DESTINO_MAR)
	var hacia := destino - global_position
	if hacia.length() < 70.0 or mar_t > 8.0:
		Global.abrir_final("mar")
		return
	var direccion := _cardinal(hacia)
	facing = direccion
	velocity = velocity.move_toward(direccion * VELOCIDAD_CON_BEBE, ACELERACION_CON_BEBE * delta)
	move_and_slide()
	global_position.x = clamp(
		global_position.x,
		Global.LIMITE_MAPA.position.x + 20.0,
		Global.LIMITE_MAPA.end.x - 20.0
	)
	global_position.y = clamp(
		global_position.y,
		Global.LIMITE_MAPA.position.y + 20.0,
		Global.LIMITE_MAPA.end.y - 20.0
	)
	_animar_caminata(delta, velocity.length() > 12.0, false)
	_actualizar_camara(delta)
	_actualizar_carga_visual()
	Global.prompt_interaccion = ""


func _cardinal(hacia: Vector2) -> Vector2:
	if abs(hacia.x) > abs(hacia.y):
		return Vector2(sign(hacia.x), 0)
	return Vector2(0, sign(hacia.y))


func _ocultar_sprite_bebe() -> void:
	var bebe := _obtener_bebe()
	if bebe == null:
		return
	var sprite_bebe := bebe.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite_bebe != null:
		sprite_bebe.hide()


func esta_cerca_del_bebe() -> bool:
	var bebe := _obtener_bebe()
	if bebe == null or Global.lleva_bebe:
		return false

	var sprite_bebe := bebe.get_node("AnimatedSprite2D") as Node2D
	var diferencia := global_position - sprite_bebe.global_position

	# Zona de interacción alrededor de la imagen del bebé.
	return (
		diferencia.x >= -100.0 and
		diferencia.x <= 160.0 and
		diferencia.y >= -200.0 and
		diferencia.y <= 30.0
	)	
	
	
func _direccion_cuatro() -> Vector2:
	var horizontal := Input.get_axis("mover_izquierda", "mover_derecha")
	var vertical := Input.get_axis("mover_arriba", "mover_abajo")
	if horizontal == 0.0 and vertical == 0.0:
		horizontal = Input.get_axis("ui_left", "ui_right")
		vertical = Input.get_axis("ui_up", "ui_down")

	if abs(horizontal) > abs(vertical):
		return Vector2(sign(horizontal), 0)
	if vertical != 0.0:
		return Vector2(0, sign(vertical))
	return Vector2.ZERO


func _animar_caminata(delta: float, esta_caminando: bool, esta_corriendo: bool):

	# =========================
	# CON BEBÉ
	# =========================
	if Global.lleva_bebe:
		var anim_bebe: StringName
		if facing == Vector2.UP:
			anim_bebe = &"espalda_bebe"

		elif facing == Vector2.DOWN:
			anim_bebe = &"frente_bebe"

		else:
			anim_bebe = &"lado_bebe"

		if not $Sprite.sprite_frames.has_animation(anim_bebe):
			anim_bebe = &"walk_lado" if esta_caminando else &"idle_lado"
		var es_animacion_lateral := anim_bebe in [&"lado_bebe", &"walk_lado", &"idle_lado"]
		$Sprite.flip_h = es_animacion_lateral and facing == Vector2.LEFT

		_cambiar_animacion(anim_bebe, esta_caminando)

		if esta_caminando:
			if not $Sprite.is_playing():
				$Sprite.play()
			$Sprite.speed_scale = 1.0
		else:
			$Sprite.stop()
			$Sprite.frame = 0
			$Sprite.frame_progress = 0.0

		# SFX de pasos con bebé
		if esta_caminando:
			paso_acum += delta

			if paso_acum >= 0.5:
				paso_acum = 0.0
				_sonar_paso()
		else:
			paso_acum = 0.0

		return


	# =========================
	# SIN BEBÉ
	# =========================

	if facing == Vector2.UP or facing == Vector2.DOWN:
		var anim_vertical: StringName = &"espalda" if facing == Vector2.UP else &"frente"
		if not $Sprite.sprite_frames.has_animation(anim_vertical):
			anim_vertical = &"walk_lado" if esta_caminando else &"idle_lado"
		$Sprite.flip_h = anim_vertical in [&"walk_lado", &"idle_lado"] and facing.x < 0.0
		_cambiar_animacion(anim_vertical, esta_caminando)
		if esta_caminando:
			if not $Sprite.is_playing():
				$Sprite.play()
			$Sprite.speed_scale = ESCALA_ANIM_CORRER if esta_corriendo else ESCALA_ANIM_CAMINAR
		else:
			$Sprite.stop()
			$Sprite.frame = 0
			$Sprite.frame_progress = 0.0
	else:
		var anim_lado := "walk_lado" if esta_caminando else "idle_lado"
		$Sprite.flip_h = facing == Vector2.LEFT
		$Sprite.speed_scale = ESCALA_ANIM_CORRER if esta_corriendo else ESCALA_ANIM_CAMINAR
		_cambiar_animacion(StringName(anim_lado), esta_caminando)

	if esta_caminando:
		paso_acum += delta

		var intervalo := 0.16 if esta_corriendo else 0.22

		if paso_acum >= intervalo:
			paso_acum = 0.0
			_sonar_paso()
	else:
		paso_acum = 0.0


func _cambiar_animacion(nueva: StringName, conservar_fase: bool) -> void:
	if $Sprite.animation == nueva:
		return

	var fase: float = 0.0
	var frames_actuales: int = $Sprite.sprite_frames.get_frame_count($Sprite.animation)
	if conservar_fase and frames_actuales > 0:
		fase = (float($Sprite.frame) + $Sprite.frame_progress) / frames_actuales

	$Sprite.play(nueva)
	if not conservar_fase:
		return

	var frames_nuevos: int = $Sprite.sprite_frames.get_frame_count(nueva)
	if frames_nuevos <= 0:
		return
	var posicion: float = fase * float(frames_nuevos)
	var frame_nuevo: int = mini(floori(posicion), frames_nuevos - 1)
	$Sprite.frame = frame_nuevo
	$Sprite.frame_progress = posicion - frame_nuevo


func _actualizar_camara(_delta: float):
	cam.offset = Vector2.ZERO


func _limitar_movimiento_al_suelo(delta: float) -> void:
	if suelo_tiles == null or velocity == Vector2.ZERO:
		return

	var desplazamiento := velocity * delta
	if _hay_suelo_bajo_pies(global_position + desplazamiento):
		return

	var puede_mover_x := absf(desplazamiento.x) > 0.0 and _hay_suelo_bajo_pies(
		global_position + Vector2(desplazamiento.x, 0.0)
	)
	var puede_mover_y := absf(desplazamiento.y) > 0.0 and _hay_suelo_bajo_pies(
		global_position + Vector2(0.0, desplazamiento.y)
	)
	if puede_mover_x and puede_mover_y:
		if absf(desplazamiento.x) > absf(desplazamiento.y):
			velocity.y = 0.0
		else:
			velocity.x = 0.0
	elif puede_mover_x:
		velocity.y = 0.0
	elif puede_mover_y:
		velocity.x = 0.0
	else:
		velocity = Vector2.ZERO


func _hay_suelo_bajo_pies(posicion: Vector2) -> bool:
	if suelo_tiles == null:
		return true

	var ancho_pies := 16.0
	var centro_pies: Vector2 = posicion + $CollisionShape2D.position
	for desplazamiento_x in [-ancho_pies, 0.0, ancho_pies]:
		var punto_global: Vector2 = centro_pies + Vector2(desplazamiento_x, 0.0)
		var celda := suelo_tiles.local_to_map(suelo_tiles.to_local(punto_global))
		if suelo_tiles.get_cell_source_id(celda) == -1:
			return false
	return true


func _actualizar_prompt():
	var cueva := get_tree().get_first_node_in_group("zona_segura")
	var bebe_con_zorro: bool = cueva != null and bool(cueva.get("bebe_con_zorro"))
	var puede_descansar: bool = false
	if cueva != null:
		puede_descansar = bool(cueva.call("puede_descansar"))
	
	if puede_descansar:
		Global.prompt_interaccion = "R  Descansar"
	elif Global.zorro_cerca and Global.cuidado_bebe_desbloqueado and Global.lleva_bebe:
		Global.prompt_interaccion = "E  Dejar con zorro"
	elif Global.zorro_cerca and bebe_con_zorro:
		Global.prompt_interaccion = "E  Recoger del zorro"
	elif Global.zorro_cerca and Global.recuerdos_obtenidos > 0 and not Global.lleva_bebe:
		Global.prompt_interaccion = "F Hablar"
	elif Global.zorro_cerca and Global.recuerdos_obtenidos == 0:
		Global.prompt_interaccion = "F  Hablar con zorro"
	elif Global.halcon_cerca and Global.lleva_bebe:
		Global.prompt_interaccion = "E  Deja al bebé para luchar"
	elif Global.lleva_bebe:
		Global.prompt_interaccion = "E  Dejar"
	elif esta_cerca_del_bebe():
		Global.prompt_interaccion = "E  Recoger" #Aqui mostrar boton
	elif Global.halcon_cerca and not Global.lleva_bebe:
		Global.prompt_interaccion = "E  Atacar"
	elif Global.loro_cerca:
		Global.prompt_interaccion = "F  Hablar con loro"
	else:
		Global.prompt_interaccion = ""


func _actualizar_carga_visual():
	if Global.lleva_bebe:
		$Sprite.modulate = Color(1.04, 0.98, 0.94)
	else:
		$Sprite.modulate = Color.WHITE



func _obtener_bebe() -> Node2D:
	return get_tree().get_first_node_in_group("bebe") as Node2D


func _recoger_bebe():
	var bebe := _obtener_bebe()
	if bebe == null or not esta_cerca_del_bebe():
		return
	bebe.recoger()
	
	cambiar_sprite_bebe(true)
	var sprite_bebe := bebe.get_node("AnimatedSprite2D")
	sprite_bebe.hide()


func _dejar_bebe():
	var bebe := _obtener_bebe()
	if bebe == null:
		return
	bebe.dejar(global_position + facing * DISTANCIA_DEJAR)
	Global.lleva_bebe = false
	cambiar_sprite_bebe(false)
	
	var sprite_bebe := bebe.get_node("AnimatedSprite2D")
	sprite_bebe.show()
	
	lock_interaccion = LOCK_TRAS_DEJAR


func _sonar_paso() -> void:
	sfx_paso.stream = PASOS[randi() % PASOS.size()]
	sfx_paso.pitch_scale = randf_range(0.92, 1.08)
	sfx_paso.play()

func _crear_frames_sheet(
	sheet: Texture2D,
	cantidad: int,
	ancho_personalizado: float = -1.0,
	y_inicio: float = 0.0,
	alto_personalizado: float = -1.0
) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var paso_frame := floori(float(sheet.get_width()) / cantidad)
	var ancho_frame := paso_frame

	if ancho_personalizado > 0:
		ancho_frame = floori(ancho_personalizado)
	
	var alto_frame := sheet.get_height() - y_inicio
	if alto_personalizado > 0:
		alto_frame = alto_personalizado
		
	for i in range(cantidad):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			i * paso_frame,
			0,
			ancho_frame,
			alto_frame
		)
		frames.append(atlas)

	return frames

func cambiar_sprite_bebe(cargado: bool) -> void:
	if cargado:
		_animar_caminata(0.0, velocity.length() > 12.0, false)
	else:
		_animar_caminata(0.0, false, false)

# Funciones en combate
func _arrojar_en_combate():
	var combate := get_tree().current_scene.get_node("CombateHalcon")
	var punto := combate.get_node("PuntoLanzamiento") as Node2D
	var halcon := get_tree().get_first_node_in_group("halcon") as Node2D
	
	if halcon == null:
		return
	
	var destino := halcon.global_position
	var piedra := PIEDRA_ESCENA.instantiate()
	combate.add_child(piedra)

	piedra.global_position = punto.global_position
	piedra.scale = Vector2(3.0, 3.0)
	piedra.combate = true
	
	sfx_ataque.pitch_scale = randf_range(0.94, 1.08)
	sfx_ataque.play()
	
	var tween := create_tween()
	tween.tween_property(
		piedra,
		"global_position",
		destino,
		0.3
	)
	
	# El halcón esquiva mientras la piedra está en el aire
	await get_tree().create_timer(0.08).timeout

	if randf() < 0.3:
		var izquierda := randf() < 0.5

		if izquierda:
			halcon.esquivar_hacia(
				combate.get_node("PuntoHalconIzquierda")
			)
		else:
			halcon.esquivar_hacia(
				combate.get_node("PuntoHalconDerecha")
			)
	
	await tween.finished

	if is_instance_valid(halcon):
		var distancia : float = piedra.global_position.distance_to(halcon.global_position)
		if distancia < 30.0:
			halcon.recibir_golpe(Vector2.UP)
			Global.perder_energia(2.0)
		else:
			Global.perder_energia(5.0)

	if is_instance_valid(piedra):
		piedra.queue_free()

# Funciones de input
func _controlar_ataque() -> bool:
	var combate := get_tree().current_scene.get_node_or_null("CombateHalcon")
	
	# Ataque: funciona tanto para entrar al combate
	# como para golpear al halcón dentro del combate.
	if Input.is_action_just_pressed("atacar") and not Input.is_physical_key_pressed(KEY_F):
		var halcon := get_tree().get_first_node_in_group("halcon")

		if halcon != null:
			if halcon.en_combate:
				if not halcon.derrotado and not halcon.en_muerte and lock_arrojar <= 0.0:
					lock_arrojar = COOLDOWN_ARROJAR
					ataques_combate += 1
					_arrojar_en_combate()
			elif Global.halcon_cerca and not Global.lleva_bebe:
				var escena_actual := get_tree().current_scene
				var combate_halcon := escena_actual.call("obtener_combate_halcon") as CanvasLayer
				if combate_halcon == null:
					return false
				combate_halcon.show()
				combate = combate_halcon
				ataques_combate = 0
				lock_arrojar = 0.0
				halcon.entrar_en_combate()
				
	# Mientras hay combate, Cavillaca no puede moverse.
	if combate != null and combate.visible:
		velocity = Vector2.ZERO
		return true
	
	return false


func _reproducir_clic_accion_teclado() -> void:
	var prompt := Global.prompt_interaccion
	if Input.is_action_just_pressed("hablar_zorro") and Global.zorro_cerca and prompt.begins_with("F "):
		Global.reproducir_clic()
	elif Input.is_action_just_pressed("descansar") and prompt.begins_with("R "):
		Global.reproducir_clic()
	elif (
		Input.is_action_just_pressed("interactuar")
		and prompt.begins_with("E ")
	) or (
		Input.is_action_just_pressed("atacar")
		and prompt.to_lower().contains("atacar")
	):
		Global.reproducir_clic()
