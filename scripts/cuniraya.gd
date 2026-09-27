extends CharacterBody2D

var bebe: Area2D

const VELOCIDAD := 40.0
const RANGO_PRESENCIA := 120.0

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
	var direccion = Vector2.RIGHT
	velocity = direccion * VELOCIDAD
	move_and_slide()

	# Presencia
	if bebe == null:
		return

	if Global.lleva_bebe:
		return

	var distancia = global_position.distance_to(bebe.global_position)

	if distancia <= RANGO_PRESENCIA:
		Global.aumentar_presencia(delta)


func _draw():
	draw_circle(Vector2.ZERO, 10.0, Color(1, 0, 0))
