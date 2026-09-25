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

var energia_temporizador := 0.0
var facing := Vector2.RIGHT
var lock_interaccion := 0.0
var lock_arrojar := 0.0
var paso_t := 0.0
var cam: Camera2D

func _ready():
	add_to_group("cavillaca")
	motion_mode = MOTION_MODE_FLOATING

	cam = Camera2D.new()
	cam.zoom = Vector2(3.2, 3.2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	add_child(cam)
	cam.make_current()
	$Sombra.pivot_offset = Vector2(12, 3)


func _physics_process(delta):
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

	var esta_corriendo := (
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
	var visual: Node2D = $Visual
	var pierna_izq: ColorRect = $Visual/PiernaIzq
	var pierna_der: ColorRect = $Visual/PiernaDer
	var cara: ColorRect = $Visual/Cara

	if esta_caminando:
		var ritmo := 16.0 if esta_corriendo else 10.0
		if Global.lleva_bebe:
			ritmo = 7.5
		paso_t += delta * ritmo
		var osc := sin(paso_t)
		visual.position.y = -abs(osc) * 2.2
		pierna_izq.position = Vector2(-8, 8 + osc * 3.5)
		pierna_der.position = Vector2(2, 8 - osc * 3.5)
		$Sombra.scale.x = 1.0 + abs(osc) * 0.12
	else:
		paso_t = 0.0
		visual.position.y = 0.0
		pierna_izq.position = Vector2(-8, 8)
		pierna_der.position = Vector2(2, 8)
		$Sombra.scale.x = 1.0

	if facing == Vector2.LEFT:
		cara.position = Vector2(-10, -12)
	elif facing == Vector2.UP:
		cara.position = Vector2(-4, -16)
	elif facing == Vector2.DOWN:
		cara.position = Vector2(2, -6)
	else:
		cara.position = Vector2(2, -12)


func _actualizar_camara(delta: float):
	if cam == null:
		return
	cam.offset = cam.offset.lerp(facing * 18.0, 1.0 - exp(-5.0 * delta))


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
	var cuerpo := $Visual/Cuerpo as ColorRect
	if cuerpo == null:
		return
	if Global.lleva_bebe:
		cuerpo.modulate = Color(1.08, 0.96, 0.88)
	else:
		cuerpo.modulate = Color.WHITE


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


func _seguir_zorro():
	var zorro := get_tree().get_first_node_in_group("zorro")
	if zorro != null:
		zorro.iniciar_guia()


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
