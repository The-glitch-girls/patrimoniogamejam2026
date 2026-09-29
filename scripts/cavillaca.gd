extends CharacterBody2D

const VELOCIDAD_CAMINAR := 100.0
const VELOCIDAD_CORRER := 180.0
const VELOCIDAD_CON_BEBE := 70.0
const VELOCIDAD_SIN_ENERGIA := 55.0
const DISTANCIA_RECOGER := 56.0
const DISTANCIA_DEJAR := 40.0
const ACELERACION := 900.0
const FRENADO := 1200.0
const ACELERACION_CON_BEBE := 420.0
const LOCK_TRAS_DEJAR := 0.35
const COOLDOWN_ARROJAR := 0.35

const PIEDRA_ESCENA := preload("res://scenes/Piedra.tscn")
const PASOS := [
	preload("res://sfx/paso_0.ogg"),
	preload("res://sfx/paso_1.ogg"),
	preload("res://sfx/paso_2.ogg"),
]
const ATAQUE := preload("res://sfx/ataque.ogg")

var FRAMES_FRENTE: Array[Texture2D]
var FRAMES_ESPALDA: Array[Texture2D]
var FRAMES_LADO: Array[Texture2D]

var sheet_frente := preload("res://assets/person/cavillaca_frente.png")
var sheet_espalda := preload("res://assets/person/cavillaca_espalda.png")
var sheet_lado := preload("res://assets/person/cavillaca_lateral.png")

var energia_temporizador := 0.0
var facing := Vector2.RIGHT
var lock_interaccion := 0.0
var lock_arrojar := 0.0
var paso_acum := 0.0
var mar_t := 0.0
var cam: Camera2D
var sfx_paso: AudioStreamPlayer
var sfx_ataque: AudioStreamPlayer

func _ready():
	FRAMES_FRENTE = _crear_frames_sheet(sheet_frente, 3)
	FRAMES_ESPALDA = _crear_frames_sheet(sheet_espalda, 3)
	FRAMES_LADO = _crear_frames_sheet(sheet_lado, 5, 2360 )
	
	add_to_group("cavillaca")
	motion_mode = MOTION_MODE_FLOATING
	_armar_sfx()
	_armar_sprite()
	$Sprite.scale = Vector2(0.052, 0.052)
	$Sprite.position.y = -100
	
	cam = Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
	# Camara
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = 4096
	cam.limit_bottom = 3072

	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	add_child(cam)
	cam.make_current()
	$Sombra.pivot_offset = Vector2(16, 4)
	


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
	_poner_anim(hojas, "idle_frente", [FRAMES_FRENTE[2]], 1.0)
	_poner_anim(hojas, "walk_frente", [
		FRAMES_FRENTE[0],
		FRAMES_FRENTE[2],
		FRAMES_FRENTE[1],
		FRAMES_FRENTE[2]
	], 6.0)
	_poner_anim(hojas, "idle_espalda", [FRAMES_ESPALDA[1]], 1.0)
	_poner_anim(hojas, "walk_espalda", [
		FRAMES_ESPALDA[0],
		FRAMES_ESPALDA[1],
		FRAMES_ESPALDA[2],
		FRAMES_ESPALDA[1]
	], 6.0)
	_poner_anim(hojas, "idle_lado", [FRAMES_LADO[0]], 1.0)
	_poner_anim(hojas, "walk_lado", FRAMES_LADO, 8.0)
	$Sprite.sprite_frames = hojas
	$Sprite.play("idle_frente")


func _poner_anim(hojas: SpriteFrames, nombre: String, texturas: Array, velocidad: float) -> void:
	hojas.add_animation(nombre)
	hojas.set_animation_speed(nombre, velocidad)
	hojas.set_animation_loop(nombre, true)
	for textura in texturas:
		hojas.add_frame(nombre, textura)


func _physics_process(delta):
	if Global.hacia_el_mar:
		_caminar_al_mar(delta)
		return

	if lock_interaccion > 0.0:
		lock_interaccion = max(lock_interaccion - delta, 0.0)

	if lock_arrojar > 0.0:
		lock_arrojar = max(lock_arrojar - delta, 0.0)

	if Input.is_action_just_pressed("interactuar") and lock_interaccion <= 0.0:
		var cueva := get_tree().get_first_node_in_group("zona_segura")
		var en_cueva := cueva != null and global_position.distance_to(cueva.global_position) < 50.0
		
		if en_cueva and Global.cuidado_bebe_desbloqueado:
			if Global.lleva_bebe:
				cueva.dejar_bebe_con_zorro()
			else:
				cueva.recoger_bebe_del_zorro()
		elif Global.lleva_bebe:
			_dejar_bebe()
		elif Global.zorro_cerca and Global.recuerdos_obtenidos == 0:
			_seguir_zorro()
		else:
			_recoger_bebe()

	if Input.is_action_just_pressed("atacar"):
		_arrojar()

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
	move_and_slide()

	if get_slide_collision_count() > 0:
		var colision := get_slide_collision(0)
		print("CHOCA CON: ", colision.get_collider().name)

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


func _caminar_al_mar(delta: float) -> void:
	_cargar_bebe_forzado()
	mar_t += delta
	var destino := Global.DESTINO_MAR
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


func _cargar_bebe_forzado() -> void:
	if Global.lleva_bebe:
		return
	var cueva := get_tree().get_first_node_in_group("zona_segura")
	if cueva != null and cueva.get("bebe_con_zorro"):
		cueva.recoger_bebe_del_zorro()
		return
	var bebe := _obtener_bebe()
	if bebe != null:
		bebe.recoger()


func esta_cerca_del_bebe() -> bool:
	var bebe := _obtener_bebe()
	if bebe == null or Global.lleva_bebe:
		return false
	return global_position.distance_to(bebe.global_position) <= DISTANCIA_RECOGER


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
	var accion := "walk" if esta_caminando else "idle"
	var direccion := "lado"
	if facing == Vector2.UP:
		direccion = "espalda"
	elif facing == Vector2.DOWN:
		direccion = "frente"
	var anim := "%s_%s" % [accion, direccion]
	$Sprite.flip_h = facing == Vector2.LEFT
	$Sprite.speed_scale = 1.35 if esta_corriendo else 0.75 if Global.lleva_bebe else 1.0
	if $Sprite.animation != anim:
		$Sprite.play(anim)

	if esta_caminando:
		paso_acum += delta
		var intervalo := 0.24 if esta_corriendo else 0.5 if Global.lleva_bebe else 0.36
		if paso_acum >= intervalo:
			paso_acum = 0.0
			_sonar_paso()
		$Sombra.scale.x = 1.0 + sin(Time.get_ticks_msec() * 0.012) * 0.06
	else:
		paso_acum = 0.0
		$Sombra.scale.x = 1.0


func _actualizar_camara(delta: float):
	cam.offset = Vector2.ZERO


func _actualizar_prompt():
	var cueva := get_tree().get_first_node_in_group("zona_segura")
	var en_cueva := cueva != null and global_position.distance_to(cueva.global_position) < 50.0
	
	if en_cueva and Global.cuidado_bebe_desbloqueado:
		if Global.lleva_bebe:
			Global.prompt_interaccion = "E  Dejar con zorro"
		else:
			Global.prompt_interaccion = "E  Recoger del zorro"
	elif Global.lleva_bebe:
		Global.prompt_interaccion = "E  Dejar"
	elif esta_cerca_del_bebe():
		Global.prompt_interaccion = "E  Recoger"
	elif Global.halcon_cerca:
		Global.prompt_interaccion = "ESPACIO  Atacar"
	elif Global.zorro_cerca and Global.recuerdos_obtenidos == 0:
		Global.prompt_interaccion = "E  Seguir zorro"
	else:
		Global.prompt_interaccion = ""


func _actualizar_carga_visual():
	if Global.lleva_bebe:
		$Sprite.modulate = Color(1.04, 0.98, 0.94)
	else:
		$Sprite.modulate = Color.WHITE


func _seguir_zorro():
	var zorro := get_tree().get_first_node_in_group("zorro")
	if zorro != null:
		zorro.iniciar_guia()


func _obtener_bebe() -> Node2D:
	return get_tree().get_first_node_in_group("bebe") as Node2D


func _recoger_bebe():
	var bebe := _obtener_bebe()
	if bebe == null or not esta_cerca_del_bebe():
		return
	bebe.recoger()


func _dejar_bebe():
	var bebe := _obtener_bebe()
	if bebe == null:
		return
	bebe.dejar(global_position + facing * DISTANCIA_DEJAR)
	lock_interaccion = LOCK_TRAS_DEJAR


func _arrojar():
	if Global.lleva_bebe or lock_arrojar > 0.0 or Global.energia <= 0.0:
		return
	Global.perder_energia(Global.COSTO_ARROJAR)
	lock_arrojar = COOLDOWN_ARROJAR
	var piedra := PIEDRA_ESCENA.instantiate()
	piedra.global_position = global_position + facing * 18.0
	var halcon := get_tree().get_first_node_in_group("halcon") as Node2D
	if halcon != null and global_position.distance_to(halcon.global_position) <= 140.0:
		piedra.direccion = (halcon.global_position - global_position).normalized()
	else:
		piedra.direccion = facing
	
	get_parent().add_child(piedra)
	sfx_ataque.pitch_scale = randf_range(0.94, 1.08)
	sfx_ataque.play()


func _sonar_paso() -> void:
	sfx_paso.stream = PASOS[randi() % PASOS.size()]
	sfx_paso.pitch_scale = randf_range(0.92, 1.08)
	sfx_paso.play()

func _crear_frames_sheet(
	sheet: Texture2D,
	cantidad: int,
	ancho_personalizado: float = -1.0
) -> Array[Texture2D]:

	var frames: Array[Texture2D] = []

	var ancho_frame := sheet.get_width() / cantidad

	if ancho_personalizado > 0:
		ancho_frame = ancho_personalizado

	var alto_frame := sheet.get_height()

	for i in range(cantidad):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			i * ancho_frame,
			0,
			ancho_frame,
			alto_frame
		)
		frames.append(atlas)

	return frames
