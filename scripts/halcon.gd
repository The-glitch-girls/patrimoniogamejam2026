extends Area2D

const VIDA_MAX := 3
const RANGO_DETECCION := 300.0
const RANGO_CORTE := 400.0
const RADIO_REVOLOTEO := 72.0
const AMPLITUD_REVOLOTEO := 36.0
const RANGO_GOLPE := 52.0
const VELOCIDAD_REVOLOTEO := 110.0
const VELOCIDAD_PATRULLA := 36.0
const VELOCIDAD_RETIRADA := 110.0
const DESCANSO_PERSECUCION := 1.4
const LOCK_GOLPE := 1.1
const TIEMPO_RESPAWN := 8.0
const TIEMPO_EN_ZONA := 10.0
const PASO_MIN := 600.0
const PASO_MAX := 1400.0
const SEPARACION := 480.0

var vida := VIDA_MAX
var origen := Vector2.ZERO
var inicio := Vector2.ZERO
var profundidad := 0.0
var puntos_abiertos: Array[Vector2] = []
var patrol_dir := Vector2.RIGHT
var patrol_t := 0.0
var vuelo_t := 0.0
var lock_golpe := 0.0
var descanso_t := 0.0
var rondando := false
var angulo := 0.0
var zona_t := 0.0
var flash_t := 0.0
var derrotado := false
var respawn_t := 0.0

const FLASHBACK_ESCENA := preload("res://scenes/Flashback.tscn")

func _ready():
	add_to_group("halcon")
	origen = global_position
	inicio = global_position
	call_deferred("_armar_puntos")
	body_entered.connect(_on_body_entered)

	$AnimatedSprite2D.play("lado")
	
func _process(delta):
	if Global.hacia_el_mar:
		Global.halcon_cerca = false
		return
	if derrotado:
		respawn_t -= delta
		Global.halcon_cerca = false
		if respawn_t <= 0.0 and Global.recuerdos_obtenidos < Global.RECUERDOS_TOTALES:
			_revivir()
		return

	vuelo_t += delta
	if lock_golpe > 0.0:
		lock_golpe = max(lock_golpe - delta, 0.0)

	if descanso_t > 0.0:
		descanso_t = max(descanso_t - delta, 0.0)
		_retirarse(delta)
		if descanso_t <= 0.0:
			_aparecer_en_otro_lado()
		Global.halcon_cerca = false
		return

	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var cerca := false
	if cavillaca != null:
		var distancia := global_position.distance_to(cavillaca.global_position)
		print("🦅 distancia Cavillaca-halcon: ", distancia)
		if rondando and distancia > RANGO_CORTE:
			rondando = false
			_empezar_descanso()
		elif rondando or distancia <= RANGO_DETECCION:
			rondando = true
			zona_t = 0.0
			cerca = true
			_revolotear(delta, cavillaca)
		else:
			_patrullar(delta)

	Global.halcon_cerca = cerca

func recibir_golpe(direccion: Vector2):
	if derrotado:
		return

	vida -= 1
	flash_t = 0.12

	print("🦅 HALCÓN RECIBIÓ GOLPE | vida = ", vida, " | posición = ", global_position)

	global_position += direccion.normalized() * 20.0

	if vida <= 0:
		print("🦅 HALCÓN VA A MORIR")
		_victoria()


func _golpear():
	$AnimatedSprite2D.play("frente")
	lock_golpe = LOCK_GOLPE
	Global.perder_energia(Global.DANIO_ENERGIA_DERROTA)
	Global.aumentar_presencia()
	Global.mostrar_aviso("¡Halcón ha golpeado!")	


func _victoria():
	print("🦅🦅🦅 VICTORIA HALCÓN | recuerdos = ", Global.recuerdos_obtenidos)

	derrotado = true
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if Global.recuerdos_obtenidos >= Global.RECUERDOS_TOTALES:
		Global.mostrar_aviso("Victoria")
		respawn_t = TIEMPO_RESPAWN
		return
	var indice := Global.obtener_recuerdo()
	respawn_t = 99999.0 if indice >= Global.RECUERDOS_TOTALES else TIEMPO_RESPAWN
	var flashback := FLASHBACK_ESCENA.instantiate()
	flashback.configurar(indice)
	var hud := get_tree().current_scene.get_node("HUD")
	hud.add_child(flashback)


func _revivir():
	derrotado = false
	vida = VIDA_MAX
	lock_golpe = 0.0
	_aparecer_en_otro_lado()
	descanso_t = 0.0
	$AnimatedSprite2D.play("lado")
	show()
	monitoring = true
	monitorable = true


func _armar_puntos() -> void:
	puntos_abiertos.clear()
	var suelo := get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	if suelo == null:
		return
	var bordes := get_tree().current_scene.get_node_or_null("Bordes") as TileMapLayer
	var cueva := get_tree().get_first_node_in_group("zona_segura") as Node2D
	for celda in suelo.get_used_cells():
		if bordes != null and bordes.get_cell_source_id(celda) != -1:
			continue
		var punto := suelo.to_global(suelo.map_to_local(celda))
		if cueva != null and punto.distance_to(cueva.global_position) < 180.0:
			continue
		puntos_abiertos.append(punto)


func _aparecer_en_otro_lado() -> void:
	if puntos_abiertos.is_empty():
		_armar_puntos()
	var punto := _elegir_mas_adelante()
	origen = punto
	global_position = punto
	profundidad = inicio.distance_to(punto)
	patrol_t = 0.0
	zona_t = 0.0
	rondando = false
	$AnimatedSprite2D.play("lado")
	print("🦅 SPAWN HALCÓN EN: ", punto)


func _elegir_mas_adelante() -> Vector2:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var banda: Array[Vector2] = []
	var mas_lejos: Array[Vector2] = []
	for punto in puntos_abiertos:
		if not _sirve(punto, cavillaca):
			continue
		var avance := inicio.distance_to(punto) - profundidad
		if avance >= PASO_MIN and avance <= PASO_MAX:
			banda.append(punto)
		elif avance > PASO_MAX:
			mas_lejos.append(punto)
	if not banda.is_empty():
		return banda.pick_random()
	if not mas_lejos.is_empty():
		return mas_lejos.pick_random()
	var fondo: Array[Vector2] = []
	for punto in puntos_abiertos:
		if not _sirve(punto, cavillaca):
			continue
		if inicio.distance_to(punto) > profundidad * 0.7:
			fondo.append(punto)
	if fondo.is_empty():
		return origen
	return fondo.pick_random()


func _sirve(punto: Vector2, cavillaca: Node2D) -> bool:
	if punto.distance_to(origen) < SEPARACION:
		return false
	if cavillaca != null and punto.distance_to(cavillaca.global_position) < SEPARACION:
		return false
	return true


func _revolotear(delta: float, cavillaca: Node2D) -> void:
	angulo += delta * 2.4
	var radio := RADIO_REVOLOTEO + sin(vuelo_t * 1.6) * AMPLITUD_REVOLOTEO
	var destino := cavillaca.global_position + Vector2.from_angle(angulo) * radio
	var antes := global_position
	global_position = global_position.move_toward(destino, VELOCIDAD_REVOLOTEO * delta)
	var hacia := global_position - antes
	if abs(hacia.x) > 0.2:
		$AnimatedSprite2D.flip_h = hacia.x < 0.0
	if lock_golpe <= 0.0 and global_position.distance_to(cavillaca.global_position) <= RANGO_GOLPE:
		_golpear()
	if lock_golpe <= 0.0 and $AnimatedSprite2D.animation != "lado":
		$AnimatedSprite2D.play("lado")


func _empezar_descanso() -> void:
	rondando = false
	descanso_t = DESCANSO_PERSECUCION
	$AnimatedSprite2D.play("lado")


func _retirarse(delta: float) -> void:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var hacia := Vector2.RIGHT
	if cavillaca != null:
		hacia = global_position - cavillaca.global_position
	if hacia.length_squared() < 16.0:
		hacia = Vector2.RIGHT
	global_position += hacia.normalized() * VELOCIDAD_RETIRADA * delta


func _patrullar(delta: float):
	zona_t += delta
	if zona_t >= TIEMPO_EN_ZONA:
		_aparecer_en_otro_lado()
		return

	patrol_t += delta
	if patrol_t > 1.6:
		patrol_t = 0.0
		patrol_dir *= -1.0
	global_position += patrol_dir * VELOCIDAD_PATRULLA * delta
	if global_position.distance_to(origen) > 70.0:
		global_position = global_position.move_toward(origen, 40.0 * delta)


func _on_body_entered(body: Node):
	if derrotado or lock_golpe > 0.0 or descanso_t > 0.0:
		return
	if body.is_in_group("cavillaca"):
		_golpear()


func _input(event):
	if event.is_action_pressed("debug_halcon"):
		var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
		if cavillaca != null:
			global_position = cavillaca.global_position + Vector2(100, 0)
			show()
			derrotado = false
			vida = VIDA_MAX
			monitoring = true
			monitorable = true
			$AnimatedSprite2D.play("lado")
