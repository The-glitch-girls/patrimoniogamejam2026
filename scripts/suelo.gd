extends Node2D

const MURO := Color(0.08, 0.06, 0.05, 1)
const GROSOR_MURO := 18.0

var zonas: Array[Dictionary] = []

func _ready():
	_crear_mapa()


func _process(_delta):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if cavillaca == null:
		return
	Global.zona_actual = _zona_en(cavillaca.global_position)


func _crear_mapa():
	_piso(Rect2(280, 180, 280, 240), Color(0.42, 0.3, 0.2, 1), "Plaza")
	_ajedrez(Rect2(280, 180, 280, 240), Color(0.36, 0.25, 0.16, 1))

	_piso(Rect2(560, 250, 160, 100), Color(0.32, 0.22, 0.18, 1), "")
	_piso(Rect2(720, 160, 280, 280), Color(0.48, 0.22, 0.16, 1), "Huaca")

	_piso(Rect2(370, 40, 100, 140), Color(0.28, 0.24, 0.16, 1), "")
	_piso(Rect2(240, -80, 360, 120), Color(0.28, 0.38, 0.22, 1), "Jardin")

	_piso(Rect2(80, 250, 200, 100), Color(0.3, 0.24, 0.18, 1), "")
	_piso(Rect2(-80, 160, 160, 280), Color(0.16, 0.14, 0.22, 1), "Cueva")

	_piso(Rect2(370, 420, 100, 160), Color(0.26, 0.22, 0.2, 1), "")
	_piso(Rect2(200, 580, 440, 160), Color(0.22, 0.3, 0.34, 1), "Costa")
	_piso(Rect2(160, 740, 520, 180), Color(0.16, 0.36, 0.42, 1), "Mar")

	# Plaza
	_muro(Rect2(262, 162, 108, GROSOR_MURO))
	_muro(Rect2(470, 162, 108, GROSOR_MURO))
	_muro(Rect2(262, 420, 108, GROSOR_MURO))
	_muro(Rect2(470, 420, 108, GROSOR_MURO))
	_muro(Rect2(262, 162, GROSOR_MURO, 88))
	_muro(Rect2(262, 350, GROSOR_MURO, 88))
	_muro(Rect2(560, 162, GROSOR_MURO, 88))
	_muro(Rect2(560, 350, GROSOR_MURO, 88))

	# Huaca
	_muro(Rect2(720, 142, 298, GROSOR_MURO))
	_muro(Rect2(720, 440, 298, GROSOR_MURO))
	_muro(Rect2(982, 142, GROSOR_MURO, 316))
	_muro(Rect2(720, 142, GROSOR_MURO, 108))
	_muro(Rect2(720, 350, GROSOR_MURO, 108))

	# Jardin
	_muro(Rect2(222, -98, 396, GROSOR_MURO))
	_muro(Rect2(222, -98, GROSOR_MURO, 156))
	_muro(Rect2(600, -98, GROSOR_MURO, 156))
	_muro(Rect2(222, 40, 148, GROSOR_MURO))
	_muro(Rect2(470, 40, 148, GROSOR_MURO))

	# Cueva
	_muro(Rect2(-98, 142, 196, GROSOR_MURO))
	_muro(Rect2(-98, 440, 196, GROSOR_MURO))
	_muro(Rect2(-98, 142, GROSOR_MURO, 316))
	_muro(Rect2(62, 142, GROSOR_MURO, 108))
	_muro(Rect2(62, 350, GROSOR_MURO, 108))

	# Costa y mar
	_muro(Rect2(182, 562, 188, GROSOR_MURO))
	_muro(Rect2(470, 562, 188, GROSOR_MURO))
	_muro(Rect2(182, 562, GROSOR_MURO, 376))
	_muro(Rect2(638, 562, GROSOR_MURO, 376))
	_muro(Rect2(160, 920, 538, GROSOR_MURO))


func _piso(rect: Rect2, color: Color, nombre: String):
	var piso := ColorRect.new()
	piso.position = rect.position
	piso.size = rect.size
	piso.color = color
	piso.z_index = -19
	piso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(piso)

	if nombre != "":
		zonas.append({ "nombre": nombre, "rect": rect })
		var etiqueta := Label.new()
		etiqueta.text = nombre.to_upper()
		etiqueta.position = rect.position + Vector2(16, 16)
		etiqueta.modulate = Color(1, 1, 1, 0.28)
		etiqueta.z_index = -9
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(etiqueta)


func _ajedrez(rect: Rect2, color: Color):
	var tam := 48
	var cols := int(rect.size.x / tam)
	var filas := int(rect.size.y / tam)
	for x in range(cols):
		for y in range(filas):
			if (x + y) % 2 == 0:
				continue
			var losa := ColorRect.new()
			losa.position = rect.position + Vector2(x * tam, y * tam)
			losa.size = Vector2(tam - 2, tam - 2)
			losa.color = color
			losa.z_index = -18
			losa.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(losa)


func _muro(rect: Rect2):
	var visual := ColorRect.new()
	visual.position = rect.position
	visual.size = rect.size
	visual.color = MURO
	visual.z_index = -10
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)

	var cuerpo := StaticBody2D.new()
	cuerpo.position = rect.position + rect.size * 0.5
	var forma := RectangleShape2D.new()
	forma.size = rect.size
	var colision := CollisionShape2D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	add_child(cuerpo)


func _zona_en(punto: Vector2) -> String:
	for zona in zonas:
		if zona.rect.has_point(punto):
			return zona.nombre
	return "Huaca"
