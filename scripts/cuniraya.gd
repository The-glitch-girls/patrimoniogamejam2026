extends CharacterBody2D

const DIRECCIONES := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const VELOCIDAD_RONDA := 40.0
const VELOCIDAD_BUSQUEDA := 85.0
const RANGO_PRESENCIA := 240.0
const PASOS_MIN_APARICION := 3
const PASOS_MAX_APARICION := 6

var suelo: TileMapLayer
var celdas_suelo: Dictionary = {}
var celda_anterior := Vector2i.ZERO
var siguiente_celda := Vector2i.ZERO
var buscaba_bebe := false
var debug_seguir_bebe := false

@onready var bebe := get_tree().get_first_node_in_group("bebe") as StaticBody2D


func _ready() -> void:
	_preparar_recorrido.call_deferred()


func _preparar_recorrido() -> void:
	var escena := get_tree().current_scene
	suelo = escena.get_node_or_null("Capas/Suelo") as TileMapLayer
	if suelo == null:
		suelo = escena.get_node_or_null("SueloTiles") as TileMapLayer

	if suelo == null:
		return

	for celda in suelo.get_used_cells():
		celdas_suelo[celda] = true

	if celdas_suelo.is_empty():
		return

	var opciones: Array[Vector2i] = []
	if is_instance_valid(bebe):
		var celda_bebe := _celda_de(bebe.global_position)
		for celda: Vector2i in celdas_suelo:
			var diferencia := celda - celda_bebe
			var pasos := absi(diferencia.x) + absi(diferencia.y)
			if pasos >= PASOS_MIN_APARICION and pasos <= PASOS_MAX_APARICION:
				opciones.append(celda)

	siguiente_celda = opciones.pick_random() if not opciones.is_empty() else celdas_suelo.keys().pick_random()
	celda_anterior = siguiente_celda
	global_position = _centro_de(siguiente_celda)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(bebe) or Global.hacia_el_mar or Global.partida_terminada:
		Global.presencia_activa = false
		return

	var objetivo := (bebe.get_node("AnimatedSprite2D") as Node2D).global_position
	var bebe_protegido := Global.bebe_protegido()
	if debug_seguir_bebe and not bebe_protegido:
		global_position = objetivo + Vector2(120.0, 0.0)
	elif not bebe_protegido:
		global_position = global_position.move_toward(objetivo, VELOCIDAD_BUSQUEDA * delta)
	elif not celdas_suelo.is_empty():
		if buscaba_bebe:
			siguiente_celda = _celda_de_suelo_mas_cercana()
			celda_anterior = siguiente_celda
		_rondar(delta)
	buscaba_bebe = not bebe_protegido

	var cerca := not bebe_protegido and global_position.distance_to(objetivo) <= RANGO_PRESENCIA
	Global.presencia_activa = cerca
	if cerca:
		Global.aumentar_presencia_por_tiempo(delta)
	if bebe.get("llorando") != cerca:
		bebe.cambiar_llanto(cerca)


func _rondar(delta: float) -> void:
	var destino := _centro_de(siguiente_celda)
	if global_position.is_equal_approx(destino):
		var celda := siguiente_celda
		siguiente_celda = _elegir_vecina(celda)
		celda_anterior = celda
		destino = _centro_de(siguiente_celda)

	global_position = global_position.move_toward(destino, VELOCIDAD_RONDA * delta)


func _elegir_vecina(celda: Vector2i) -> Vector2i:
	var opciones: Array[Vector2i] = []
	for direccion: Vector2i in DIRECCIONES:
		var vecina := celda + direccion
		if celdas_suelo.has(vecina):
			opciones.append(vecina)

	if opciones.size() > 1:
		opciones.erase(celda_anterior)
	return opciones.pick_random() if not opciones.is_empty() else celda


func _celda_de_suelo_mas_cercana() -> Vector2i:
	var celda := _celda_de(global_position)
	if celdas_suelo.has(celda):
		return celda

	var distancia_minima := INF
	for candidata: Vector2i in celdas_suelo:
		var distancia := _centro_de(candidata).distance_squared_to(global_position)
		if distancia < distancia_minima:
			celda = candidata
			distancia_minima = distancia
	return celda


func _celda_de(punto: Vector2) -> Vector2i:
	return suelo.local_to_map(suelo.to_local(punto))


func _centro_de(celda: Vector2i) -> Vector2:
	return suelo.to_global(suelo.map_to_local(celda))


func debug_acercar_a_bebe() -> void:
	if not OS.is_debug_build() or not is_instance_valid(bebe) or Global.bebe_protegido():
		return

	debug_seguir_bebe = true
	var sprite_bebe := bebe.get_node("AnimatedSprite2D") as Node2D
	global_position = sprite_bebe.global_position + Vector2(120.0, 0.0)
	print("Depuración: Cuniraya apareció junto al bebé")
