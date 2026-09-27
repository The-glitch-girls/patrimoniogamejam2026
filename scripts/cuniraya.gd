extends CharacterBody2D

var bebe: Area2D
var direcciones = [
			Vector2.UP,
			Vector2.DOWN,
			Vector2.LEFT,
			Vector2.RIGHT
		]
var direccion := Vector2.ZERO
var tiempo_cambio := 0.0
const VELOCIDAD := 40.0
const RANGO_PRESENCIA := 120.0
const TIEMPO_CAMBIO := 2.5
const CUEVA := Rect2(-80, 160, 160, 280)
const MAR := Rect2(160, 740, 520, 180)

func _ready():
	print("Cuniraya está en el mapa")

	bebe = get_tree().get_first_node_in_group("bebe") as Area2D

	call_deferred("_colocar_cuniraya")

func _colocar_cuniraya():
	var suelo = get_tree().current_scene
	global_position = suelo.obtener_punto_cuniraya()	
	print("Posición inicial Cuniraya: ", global_position)

func _process(delta):
	# Movimiento autónomo
	tiempo_cambio -= delta
	
	if tiempo_cambio <= 0.0:
		direccion = direcciones.pick_random()
		tiempo_cambio = TIEMPO_CAMBIO
	
	# Presencia y acercamiento al bebé
	if bebe != null and not Global.lleva_bebe:
		var distancia := global_position.distance_to(bebe.global_position)

		if distancia <= RANGO_PRESENCIA:
			Global.presencia_activa = true
			Global.aumentar_presencia(delta)

			# Acercarse al bebé usando solo 4 direcciones
			var diferencia := bebe.global_position - global_position

			if abs(diferencia.x) > abs(diferencia.y):
				direccion = Vector2.RIGHT if diferencia.x > 0 else Vector2.LEFT
			else:
				direccion = Vector2.DOWN if diferencia.y > 0 else Vector2.UP

			tiempo_cambio = TIEMPO_CAMBIO
		else:
			Global.presencia_activa = false
	else:
		Global.presencia_activa = false
	
	var siguiente_posicion : Vector2 = global_position + direccion * VELOCIDAD * delta

	if CUEVA.has_point(siguiente_posicion) or MAR.has_point(siguiente_posicion):
		direccion = -direccion
	
	velocity = direccion * VELOCIDAD
	move_and_slide()
	
	# Si choca contra una pared, cambia inmediatamente de dirección
	if get_slide_collision_count() > 0:
		direccion = direcciones.pick_random()
		tiempo_cambio = TIEMPO_CAMBIO

func _draw():
	draw_circle(Vector2.ZERO, 10.0, Color(1, 0, 0))
