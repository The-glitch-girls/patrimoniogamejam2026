extends TileMapLayer

@onready var punto_pies: Marker2D = $"../Cavillaca/PuntoPies"


func _ready() -> void:
	notify_runtime_tile_data_update()


func _use_tile_data_runtime_update(_celda: Vector2i) -> bool:
	return is_instance_valid(punto_pies)


func _tile_data_runtime_update(_celda: Vector2i, tile_data: TileData) -> void:
	# Y-sort compara el origen de Cavillaca. Compensamos la distancia a los pies.
	tile_data.y_sort_origin -= roundi(punto_pies.position.y)
	# El contorno personalizado tiene prioridad sobre las formas de respaldo.
	if tile_data.get_collision_polygons_count(0) == 0:
		return

	for capa in range(1, tile_set.get_physics_layers_count()):
		tile_data.set_collision_polygons_count(capa, 0)
