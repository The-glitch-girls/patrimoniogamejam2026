extends TextureRect

@export var velocidad := 30.0

func _ready() -> void:
	await get_tree().process_frame
	pivot_offset = size / 2.0

func _process(delta: float) -> void:
	rotation_degrees += velocidad * delta
