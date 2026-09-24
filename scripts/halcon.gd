extends Area2D

const VIDA_MAX := 3
const RANGO_DETECCION := 140.0
const RANGO_GOLPE := 24.0
const VELOCIDAD_PERSEGUIR := 72.0
const VELOCIDAD_PATRULLA := 36.0
const LOCK_GOLPE := 1.1
const TIEMPO_RESPAWN := 8.0
const RANGO_SEGURIDAD_CUEVA := 80.0

var vida := VIDA_MAX
var origen := Vector2.ZERO
var patrol_dir := Vector2.RIGHT
var patrol_t := 0.0
var vuelo_t := 0.0
var lock_golpe := 0.0
var flash_t := 0.0
var derrotado := false
var respawn_t := 0.0

const FLASHBACK_ESCENA := preload("res://scenes/Flashback.tscn")

func _ready():
	add_to_group("halcon")
	origen = global_position
	body_entered.connect(_on_body_entered)


func _process(delta):
	if derrotado:
		respawn_t -= delta
		Global.halcon_cerca = false
		if respawn_t <= 0.0:
			_revivir()
		return

	vuelo_t += delta
	if lock_golpe > 0.0:
		lock_golpe = max(lock_golpe - delta, 0.0)
	if flash_t > 0.0:
		flash_t = max(flash_t - delta, 0.0)
		$Cuerpo.modulate = Color(1.4, 0.7, 0.5)
	else:
		$Cuerpo.modulate = Color.WHITE

	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	var cueva := get_tree().get_first_node_in_group("zona_segura") as Node2D
	var cerca := false
	if cavillaca != null:
		var distancia := global_position.distance_to(cavillaca.global_position)
		var jugador_en_zona_segura := false
		
		if cueva != null:
			var distancia_cueva := cavillaca.global_position.distance_to(cueva.global_position)
			jugador_en_zona_segura = distancia_cueva < RANGO_SEGURIDAD_CUEVA
		
		if not jugador_en_zona_segura:
			cerca = distancia <= RANGO_DETECCION
			if cerca:
				if distancia > RANGO_GOLPE:
					var hacia := (cavillaca.global_position - global_position).normalized()
					global_position += hacia * VELOCIDAD_PERSEGUIR * delta
				elif lock_golpe <= 0.0:
					_golpear()
			else:
				_patrullar(delta)
		else:
			_patrullar(delta)

	Global.halcon_cerca = cerca
	$Cuerpo.position.y = -10 + sin(vuelo_t * 7.0) * 3.0
	$AlaIzq.position = Vector2(-16, -8 + sin(vuelo_t * 12.0) * 4.0)
	$AlaDer.position = Vector2(8, -8 + sin(vuelo_t * 12.0 + PI) * 4.0)


func recibir_golpe(direccion: Vector2):
	if derrotado:
		return
	vida -= 1
	flash_t = 0.12
	global_position += direccion.normalized() * 20.0
	if vida <= 0:
		_victoria()


func _golpear():
	lock_golpe = LOCK_GOLPE
	Global.perder_energia(Global.DANIO_ENERGIA_DERROTA)
	Global.aumentar_presencia()
	Global.mostrar_aviso("¡Halcón ha golpeado!")


func _victoria():
	derrotado = true
	respawn_t = TIEMPO_RESPAWN
	Global.mostrar_aviso("Victoria")
	Global.obtener_recuerdo()
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var flashback := FLASHBACK_ESCENA.instantiate()
	var hud := get_tree().current_scene.get_node("HUD")
	hud.add_child(flashback)


func _revivir():
	derrotado = false
	vida = VIDA_MAX
	global_position = origen
	show()
	monitoring = true
	monitorable = true


func _patrullar(delta: float):
	patrol_t += delta
	if patrol_t > 1.6:
		patrol_t = 0.0
		patrol_dir *= -1.0
	global_position += patrol_dir * VELOCIDAD_PATRULLA * delta
	if global_position.distance_to(origen) > 70.0:
		global_position = global_position.move_toward(origen, 40.0 * delta)


func _on_body_entered(body: Node):
	if derrotado or lock_golpe > 0.0:
		return
	if body.is_in_group("cavillaca"):
		_golpear()
