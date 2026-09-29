extends Area2D

const VIDA_MAX := 3
const RANGO_DETECCION := 120.0
const RANGO_CORTE := 220.0
const RANGO_GOLPE := 24.0
const VELOCIDAD_PERSEGUIR := 58.0
const VELOCIDAD_PATRULLA := 36.0
const VELOCIDAD_RETIRADA := 110.0
const TIEMPO_PERSECUCION := 1.5
const DESCANSO_PERSECUCION := 2.8
const LOCK_GOLPE := 1.1
const TIEMPO_RESPAWN := 8.0
const TIEMPO_EN_ZONA := 10.0
const DISTANCIA_RESPAWN := 640.0

var vida := VIDA_MAX
var origen := Vector2.ZERO
var puntos_respawn: Array[Vector2] = []
var patrol_dir := Vector2.RIGHT
var patrol_t := 0.0
var vuelo_t := 0.0
var lock_golpe := 0.0
var persecucion_t := 0.0
var descanso_t := 0.0
var zona_t := 0.0
var flash_t := 0.0
var derrotado := false
var respawn_t := 0.0

const FLASHBACK_ESCENA := preload("res://scenes/Flashback.tscn")

func _ready():
	add_to_group("halcon")
	origen = global_position
	puntos_respawn = _recoger_puntos_abiertos()
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
	#if flash_t > 0.0:
		#flash_t = max(flash_t - delta, 0.0)
		#$Cuerpo.modulate = Color(1.4, 0.7, 0.5)
	#else:
		#$Cuerpo.modulate = Color.WHITE

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
		if persecucion_t > 0.0 or distancia <= RANGO_DETECCION:
			if persecucion_t <= 0.0:
				persecucion_t = TIEMPO_PERSECUCION
				zona_t = 0.0
			persecucion_t = max(persecucion_t - delta, 0.0)
			if distancia > RANGO_CORTE or persecucion_t <= 0.0:
				_empezar_descanso()
			else:
				cerca = true
				if distancia > RANGO_GOLPE:
					var hacia := (cavillaca.global_position - global_position).normalized()
					global_position += hacia * VELOCIDAD_PERSEGUIR * delta
				elif lock_golpe <= 0.0:
					_golpear()
		else:
			_patrullar(delta)

	Global.halcon_cerca = cerca

func recibir_golpe(direccion: Vector2):
	if derrotado:
		return
	vida -= 1
	flash_t = 0.12
	global_position += direccion.normalized() * 20.0
	if vida <= 0:
		_victoria()


func _golpear():
	$AnimatedSprite2D.play("frente")
	lock_golpe = LOCK_GOLPE
	Global.perder_energia(Global.DANIO_ENERGIA_DERROTA)
	Global.aumentar_presencia()
	Global.mostrar_aviso("¡Halcón ha golpeado!")	

func _victoria():
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
	persecucion_t = 0.0
	descanso_t = 0.0
	$AnimatedSprite2D.play("lado")
	show()
	monitoring = true
	monitorable = true


func _recoger_puntos_abiertos() -> Array[Vector2]:
	var puntos: Array[Vector2] = []
	var suelo := get_tree().current_scene.get_node_or_null("SueloTiles") as TileMapLayer
	if suelo == null:
		return puntos

	var bordes := get_tree().current_scene.get_node_or_null("Bordes") as TileMapLayer
	for celda in suelo.get_used_cells():
		if bordes != null and bordes.get_cell_source_id(celda) != -1:
			continue
		puntos.append(suelo.to_global(suelo.map_to_local(celda)))
	return puntos


func _elegir_punto_respawn() -> Vector2:
	if puntos_respawn.is_empty():
		return origen

	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var cueva := get_tree().get_first_node_in_group("zona_segura") as Node2D
	var lejos: Array[Vector2] = []
	for punto in puntos_respawn:
		if punto.distance_to(origen) < DISTANCIA_RESPAWN:
			continue
		if cavillaca != null and punto.distance_to(cavillaca.global_position) < DISTANCIA_RESPAWN:
			continue
		if cueva != null and punto.distance_to(cueva.global_position) < 180.0:
			continue
		lejos.append(punto)

	if not lejos.is_empty():
		return lejos.pick_random()

	var fuera_del_jugador: Array[Vector2] = []
	for punto in puntos_respawn:
		if cavillaca != null and punto.distance_to(cavillaca.global_position) < RANGO_DETECCION:
			continue
		fuera_del_jugador.append(punto)
	if fuera_del_jugador.is_empty():
		return origen
	return fuera_del_jugador.pick_random()


func _aparecer_en_otro_lado() -> void:
	origen = _elegir_punto_respawn()
	global_position = origen
	patrol_t = 0.0
	zona_t = 0.0
	$AnimatedSprite2D.play("lado")


func _empezar_descanso() -> void:
	persecucion_t = 0.0
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
