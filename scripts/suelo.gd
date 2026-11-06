extends Node2D

const RUTA_COMBATE_HALCON := "res://scenes/CombateHalcon.tscn"
const MURO := Color(0.08, 0.06, 0.05, 1)
const GROSOR_MURO := 18.0

var zonas: Array[Dictionary] = []
var combate_halcon: CanvasLayer

func _ready():
	zonas.append({ "nombre": "Mar", "rect": Rect2(500, 820, 400, 220) })

func _process(_delta):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if cavillaca == null:
		return
	Global.zona_actual = _zona_en(cavillaca.global_position)

func _zona_en(punto: Vector2) -> String:
	for zona in zonas:
		if zona.rect.has_point(punto):
			return zona.nombre
	return "Huaca"

func configurar_navegacion():
	var navigation_region := get_tree().current_scene.get_node("NavigationRegion2D")
	var navigation_polygon : NavigationPolygon = navigation_region.navigation_polygon

	navigation_polygon.clear()

	var areas_caminables = [
		Rect2(240, -80, 360, 120), # Jardin
		Rect2(370, 40, 100, 140),  # Conexion Jardin-Plaza
		Rect2(280, 180, 280, 240), # Plaza
		Rect2(370, 420, 100, 160), # Conexion Plaza-Costa
		Rect2(200, 580, 440, 160)  # Costa
	]

	for rect in areas_caminables:
		var vertices := PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		])

		navigation_polygon.add_outline(vertices)

	navigation_polygon.make_polygons_from_outlines()
	
func obtener_punto_cuniraya() -> Vector2:
	var zonas_validas := []

	for zona in zonas:
		if zona.nombre != "Huaca" and zona.nombre != "Cueva" and zona.nombre != "Mar":
			zonas_validas.append(zona.rect)

	if zonas_validas.is_empty():
		return global_position

	var rect: Rect2 = zonas_validas.pick_random()

	# Margen para no generar el punto sobre los muros
	var margen := 30.0
	var rect_seguro := rect.grow(-margen)
	
	var punto_local := Vector2(
		randf_range(rect_seguro.position.x, rect_seguro.end.x),
		randf_range(rect_seguro.position.y, rect_seguro.end.y)
	)

	return to_global(punto_local)
	
func obtener_combate_halcon() -> CanvasLayer:
	if is_instance_valid(combate_halcon):
		return combate_halcon

	var escena := load(RUTA_COMBATE_HALCON) as PackedScene
	if escena == null:
		push_error("No se pudo cargar CombateHalcon.tscn")
		return null

	combate_halcon = escena.instantiate() as CanvasLayer
	if combate_halcon == null:
		push_error("CombateHalcon.tscn no contiene un CanvasLayer")
		return null

	combate_halcon.name = "CombateHalcon"
	add_child(combate_halcon)
	combate_halcon.hide()
	return combate_halcon


func mostrar_combate_halcon() -> void:
	var combate := obtener_combate_halcon()
	if combate != null:
		combate.show()


func liberar_combate_halcon(combate: CanvasLayer) -> void:
	if not is_instance_valid(combate):
		combate_halcon = null
		return
	if combate != combate_halcon:
		push_warning("Se intentó liberar una instancia de combate que no pertenece a este suelo")
		return
	combate_halcon = null
	combate.queue_free()
