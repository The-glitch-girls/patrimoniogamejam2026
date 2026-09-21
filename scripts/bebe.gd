extends Area2D

const OFFSET_CARGADO := Vector2(16, -12)
const SEGUIMIENTO := 14.0

var bob_t := 0.0

func _ready():
	add_to_group("bebe")


func _process(delta):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if Global.lleva_bebe:
		_seguir_carga(cavillaca, delta)
		return

	bob_t += delta
	$ColorRect.position = Vector2(-12, -14 + sin(bob_t * 3.2) * 2.0)
	$ColorRect.scale = Vector2.ONE
	z_index = 0

	if cavillaca != null and cavillaca.esta_cerca_del_bebe():
		$ColorRect.modulate = Color(1.18, 1.12, 0.95)
	else:
		$ColorRect.modulate = Color.WHITE


func recoger():
	Global.lleva_bebe = true
	$CollisionShape2D.set_deferred("disabled", true)


func dejar(posicion: Vector2):
	global_position = posicion
	Global.lleva_bebe = false
	$CollisionShape2D.set_deferred("disabled", false)
	$ColorRect.scale = Vector2.ONE
	$ColorRect.modulate = Color.WHITE
	z_index = 0


func _seguir_carga(cavillaca: Node2D, delta: float):
	if cavillaca == null:
		return

	var lado := 1.0
	if "facing" in cavillaca and cavillaca.facing.x < 0.0:
		lado = -1.0

	var destino := cavillaca.global_position + Vector2(OFFSET_CARGADO.x * lado, OFFSET_CARGADO.y)
	global_position = global_position.lerp(destino, 1.0 - exp(-SEGUIMIENTO * delta))
	$ColorRect.position = Vector2(-12, -12)
	$ColorRect.scale = Vector2(0.82, 0.82)
	$ColorRect.modulate = Color(1.05, 0.98, 0.9)
	z_index = 2
