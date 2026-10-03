class_name GuiaNavegacion
extends Control

var flecha: FlechaGuia
var texto: Label
var alpha := 0.0
var colocada := false

func configurar(
	estilo: StyleBoxFlat,
	texto_inicial: String,
	tamano: Vector2,
	fuente: Font,
	color_texto: Color
) -> void:
	size = tamano
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fondo := Panel.new()
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_theme_stylebox_override("panel", estilo)
	add_child(fondo)

	flecha = FlechaGuia.new()
	flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flecha.size = Vector2(22, 22)
	flecha.pivot_offset = flecha.size * 0.5
	add_child(flecha)

	texto = Label.new()
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.offset_left = 42
	texto.offset_right = -14
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.text = texto_inicial

	texto.add_theme_font_override("font", fuente)
	texto.add_theme_font_size_override("font_size", 18)
	texto.add_theme_color_override("font_color", color_texto)

	add_child(texto)


func actualizar(
	objetivo: Node2D,
	origen: Node2D,
	vista: Rect2,
	delta: float,
	otra_guia: GuiaNavegacion = null
) -> void:
	if objetivo == null or origen == null:
		_ocultar(delta)
		return

	var pantalla := get_viewport().get_canvas_transform() * objetivo.global_position

	if vista.grow(-56).has_point(pantalla):
		_ocultar(delta)
		return

	var mostrar := true

	var metros := _metros_hasta(
		origen.global_position.distance_to(objetivo.global_position)
	)

	texto.text = "%d m" % metros

	var ancho := maxf(
		texto.get_minimum_size().x + 58.0,
		124.0
	)

	size = Vector2(ancho, 44)

	var mitad := size * 0.5

	var zona := Rect2(
		Vector2(16.0 + mitad.x, 84.0 + mitad.y),
		Vector2(
			vista.size.x - 32.0 - size.x,
			vista.size.y - 176.0 - size.y
		)
	)

	var borde := _borde_de(
		vista.get_center(),
		pantalla,
		zona
	)

	var destino := borde - mitad

	if otra_guia != null:
		destino = _separar(destino, zona, otra_guia)

	var direccion := pantalla - vista.get_center()

	_mostrar(destino, direccion, mostrar, delta)
	

func _mostrar(
	destino: Vector2,
	direccion: Vector2,
	_debe_mostrar: bool,
	delta: float
) -> void:
	alpha = move_toward(alpha, 1.0, delta * 6.0)

	modulate.a = alpha
	visible = alpha > 0.02

	if colocada:
		position = position.lerp(
			destino,
			1.0 - exp(-12.0 * delta)
		)
	else:
		position = destino
		colocada = true

	if direccion.length_squared() < 0.001:
		direccion = Vector2.RIGHT

	direccion = direccion.normalized()

	var empuje := sin(Time.get_ticks_msec() * 0.006) * 3.0
	var a_la_derecha := direccion.x >= 0.0
	var x_flecha := 24.0

	if a_la_derecha:
		texto.offset_left = 16
		texto.offset_right = -40
		x_flecha = size.x - 24.0
	else:
		texto.offset_left = 40
		texto.offset_right = -16

	var centro_flecha := Vector2(x_flecha, 22) + direccion * empuje

	flecha.position = centro_flecha - flecha.pivot_offset
	flecha.rotation = direccion.angle()


func _ocultar(delta: float) -> void:
	alpha = move_toward(alpha, 0.0, delta * 6.0)

	modulate.a = alpha
	visible = alpha > 0.02

	if alpha <= 0.02:
		colocada = false


func _metros_hasta(pixeles: float) -> int:
	var metros := pixeles / 2.2

	if metros < 15.0:
		return maxi(int(round(metros)), 1)

	return int(round(metros / 10.0) * 10.0)


func _borde_de(
	origen: Vector2,
	destino: Vector2,
	zona: Rect2
) -> Vector2:

	var dir := destino - origen
	var mejor := INF
	var punto := zona.get_center()

	if absf(dir.x) > 0.001:
		var tx := (
			(zona.position.x - origen.x) / dir.x
			if dir.x < 0.0
			else
			(zona.end.x - origen.x) / dir.x
		)

		if tx > 0.0:
			var y := origen.y + dir.y * tx

			if y >= zona.position.y and y <= zona.end.y and tx < mejor:
				mejor = tx
				punto = origen + dir * tx

	if absf(dir.y) > 0.001:
		var ty := (
			(zona.position.y - origen.y) / dir.y
			if dir.y < 0.0
			else
			(zona.end.y - origen.y) / dir.y
		)

		if ty > 0.0 and ty < mejor:
			var x := origen.x + dir.x * ty

			if x >= zona.position.x and x <= zona.end.x:
				punto = origen + dir * ty

	return punto

func _separar(
	destino: Vector2,
	zona: Rect2,
	otra_guia: GuiaNavegacion
) -> Vector2:
	if not otra_guia.visible:
		return destino

	var rect_otra := Rect2(
		otra_guia.position,
		otra_guia.size
	)

	if not Rect2(destino, size).intersects(rect_otra):
		return destino

	var desplazamientos: Array[Vector2] = [
		Vector2(0, 56),
		Vector2(0, -56),
		Vector2(152, 0),
		Vector2(-152, 0)
	]

	for desplazamiento in desplazamientos:
		var alternativa := destino + desplazamiento

		alternativa.x = clampf(
			alternativa.x,
			zona.position.x,
			zona.end.x - size.x
		)

		alternativa.y = clampf(
			alternativa.y,
			zona.position.y,
			zona.end.y - size.y
		)

		if not Rect2(alternativa, size).intersects(rect_otra):
			return alternativa

	return destino
