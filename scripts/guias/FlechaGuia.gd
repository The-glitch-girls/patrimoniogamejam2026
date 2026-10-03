class_name FlechaGuia
extends Control

func _draw() -> void:
	var medio := size.y * 0.5

	draw_rect(
		Rect2(0, medio - 2.5, size.x * 0.46, 5),
		Color.WHITE,
		true
	)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(size.x * 0.34, medio - 7),
			Vector2(size.x - 1, medio),
			Vector2(size.x * 0.34, medio + 7),
		]),
		Color.WHITE
	)
