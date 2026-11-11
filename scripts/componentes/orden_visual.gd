extends RefCounted
## Comparte la regla de profundidad visual entre Cavillaca y personajes interactuables.
## No modifica colisiones: solo el z_index del sprite.

const OFFSET_PIES_CAVILLACA_Y := 103.0
const RANGO_ORDEN_X := 90.0
const RANGO_ORDEN_Y := 120.0

static func actualizar_sprite(
	sprite: CanvasItem,
	entidad: Node2D,
	cavillaca: Node2D,
	offset_pies_entidad_y: float
) -> void:
	if sprite == null or entidad == null or cavillaca == null:
		if sprite != null:
			sprite.z_index = 0
		return

	var diferencia := cavillaca.global_position - entidad.global_position
	var se_solapan := (
		absf(diferencia.x) < RANGO_ORDEN_X
		and absf(diferencia.y) < RANGO_ORDEN_Y
	)
	if not se_solapan:
		sprite.z_index = 0
		return

	var pies_cavillaca_y := cavillaca.global_position.y + OFFSET_PIES_CAVILLACA_Y
	var pies_entidad_y := entidad.global_position.y + offset_pies_entidad_y
	# Un z_index mayor se dibuja delante. La comparación usa anclas de pies.
	sprite.z_index = 1 if pies_cavillaca_y < pies_entidad_y else -1
