extends CharacterBody2D

var bebe: Area2D
const RANGO_PRESENCIA := 120.0

func _ready():
	print("Cuniraya está en el mapa")	
	bebe = get_tree().get_first_node_in_group("bebe") as Area2D
	
func _process(delta):
	if bebe == null:
		return
		
	if Global.lleva_bebe:
		return

	var distancia = global_position.distance_to(bebe.global_position)

	if distancia <= RANGO_PRESENCIA:
		Global.aumentar_presencia(delta)
