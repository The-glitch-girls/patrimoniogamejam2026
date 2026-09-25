extends CharacterBody2D

var puntos_cuniraya: Array[Node] = []
var punto_actual: Vector2
var bebe: Area2D
const VELOCIDAD := 40.0
const DISTANCIA_MINIMA := 10.0
const RANGO_PRESENCIA := 120.0
const ZONAS_CUNIRAYA := [
	"Jardin",
	"Plaza",
	"Costa"
]

func _ready():
	print("Cuniraya está en el mapa")	
	bebe = get_tree().get_first_node_in_group("bebe") as Area2D
	var contenedor = get_tree().current_scene.get_node("PuntosCuniraya")
	puntos_cuniraya = contenedor.get_children()
	
	print("Puntos encontrados: ", puntos_cuniraya.size())
	elegir_punto()
	
func _process(delta):
	if punto_actual != null:
		var direccion = global_position.direction_to(punto_actual)
		velocity = direccion * VELOCIDAD
		move_and_slide()

		if global_position.distance_to(punto_actual) <= DISTANCIA_MINIMA:
			elegir_punto()

	if bebe == null:
		return
		
	if Global.lleva_bebe:
		return

	var distancia = global_position.distance_to(bebe.global_position)

	if distancia <= RANGO_PRESENCIA:
		Global.aumentar_presencia(delta)
		
func elegir_punto():
	var suelo = get_tree().current_scene
	punto_actual = suelo.obtener_punto_cuniraya()

	print("Nuevo punto: ", punto_actual)
	
func _draw():
	draw_circle(Vector2.ZERO, 10.0, Color(1, 0, 0))
