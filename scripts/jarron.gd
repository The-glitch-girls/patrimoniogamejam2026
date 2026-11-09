@tool
extends StaticBody2D

@export var imagen: Texture2D:
	set(valor):
		imagen = valor
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite != null:
			sprite.texture = valor


func _ready() -> void:
	$Sprite2D.texture = imagen
