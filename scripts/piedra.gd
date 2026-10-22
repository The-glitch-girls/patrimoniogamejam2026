extends Area2D

const VELOCIDAD := 280.0
const VIDA := 0.85

var direccion := Vector2.RIGHT
var tiempo := 0.0
var combate := false

func _ready():
	area_entered.connect(_on_area_entered)

func _process(delta):
	global_position += direccion * VELOCIDAD * delta
	tiempo += delta
	if tiempo >= VIDA:
		queue_free()

func _on_area_entered(area: Area2D):
	if combate:
		return

	if area.is_in_group("halcon"):
		var halcon := area.get_parent()
		if halcon != null and halcon.has_method("recibir_golpe"):
			halcon.recibir_golpe(direccion)
		queue_free()
