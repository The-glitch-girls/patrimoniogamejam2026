extends Area2D

const RECUPERACION_ENERGIA_POR_SEGUNDO := 8.0
const RANGO_INTERACCION := 40.0
const RANGO_ZORRO_DESCANSO := 150.0
const RANGO_ENTRADA := 150.0

var bebe_con_zorro := false
var jugador_en_entrada := false
var puerta_abierta := true
var aviso_energia_mostrado := false

@onready var arbol: TileMapLayer = $Arbol
@onready var puerta: TileMapLayer = $Puerta
@onready var colision_puerta: CollisionShape2D = $ColisionPuerta/CollisionShape2D

func _ready():
	add_to_group("zona_segura")
	_crear_arbol_y_puerta()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	jugador_en_entrada = _cavillaca_en_entrada()
	if jugador_en_entrada and not aviso_energia_mostrado:
		Global.mostrar_aviso("Con un recuerdo, la cueva recarga tu energía")
	aviso_energia_mostrado = jugador_en_entrada

	var puerta_abierta_ahora := jugador_en_entrada and Global.recuerdos_obtenidos > 0
	_cambiar_puerta(puerta_abierta_ahora)

	if puerta_abierta_ahora:
		Global.recuperar_energia(RECUPERACION_ENERGIA_POR_SEGUNDO * delta)
	Global.descanso_con_zorro = puerta_abierta_ahora


func descansar() -> void:
	if not _cavillaca_en_entrada():
		Global.mostrar_aviso("Acércate a la entrada para descansar")
		return
	if Global.recuerdos_obtenidos < 1:
		Global.mostrar_aviso("El zorro aún no te ofrece descanso")
		return
	if not _zorro_en_rango_de_descanso():
		Global.mostrar_aviso("Acércate al zorro para descansar")
		return
	if Global.energia >= Global.ENERGIA_MAX:
		Global.mostrar_aviso("Tu energía ya está completa")
		return
	Global.mostrar_aviso("Descansando junto al zorro")


func puede_descansar() -> bool:
	return _cavillaca_en_entrada() and _zorro_en_rango_de_descanso() and Global.recuerdos_obtenidos > 0


func _cavillaca_en_entrada() -> bool:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	return (
		cavillaca != null
		and cavillaca.global_position.distance_to(colision_puerta.global_position) <= RANGO_ENTRADA
	)


func _zorro_en_rango_de_descanso() -> bool:
	var zorro := get_tree().get_first_node_in_group("zorro") as Node2D
	return zorro != null and colision_puerta.global_position.distance_to(zorro.global_position) < RANGO_ZORRO_DESCANSO


func _crear_arbol_y_puerta() -> void:
	for fila in range(3):
		for columna in range(3):
			arbol.set_cell(Vector2i(columna, fila), 0, Vector2i(9 + columna, fila))
	_cambiar_puerta(false)


func _cambiar_puerta(abierta: bool) -> void:
	if puerta_abierta == abierta:
		return
	puerta_abierta = abierta
	for fila in range(1, 3):
		# La puerta del atlas va sobre el hueco oscuro del árbol.
		var celda := Vector2i(1, fila)
		if abierta:
			puerta.erase_cell(celda)
		else:
			puerta.set_cell(celda, 0, Vector2i(12, fila))
	# La puerta se oculta al desbloquearse, pero la colisión conserva el límite
	# físico para que Cavillaca no atraviese el tronco.
	colision_puerta.set_deferred("disabled", false)


func dejar_bebe_con_zorro():
	if not Global.cuidado_bebe_desbloqueado:
		Global.mostrar_aviso("Necesitas el Recuerdo 2 para esto")
		return
	
	var zorro := get_tree().get_first_node_in_group("zorro")
	if zorro == null or global_position.distance_to(zorro.global_position) >= RANGO_INTERACCION:
		Global.mostrar_aviso("El zorro no está cerca")
		return
	
	if not Global.lleva_bebe:
		Global.mostrar_aviso("No llevas al bebé")
		return
	
	bebe_con_zorro = true
	Global.lleva_bebe = false
	Global.mostrar_aviso("Bebé dejado con el zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.global_position = global_position


func recoger_bebe_del_zorro():
	if not bebe_con_zorro:
		return
	
	bebe_con_zorro = false
	Global.lleva_bebe = true
	Global.mostrar_aviso("Bebé recogido del zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.recoger()


func _on_body_entered(body: Node):
	if body.is_in_group("cavillaca"):
		var zorro := get_tree().get_first_node_in_group("zorro")
		var zorro_cerca := zorro != null and global_position.distance_to(zorro.global_position) < RANGO_INTERACCION
		
		if zorro_cerca and Global.recuerdos_obtenidos > 0:
			Global.zona_actual = "Cueva del Zorro"
		elif zorro_cerca and Global.recuerdos_obtenidos == 0:
			Global.zona_actual = "Cueva del Zorro (?)"
		else:
			Global.zona_actual = "Cueva del Zorro"


func _on_body_exited(body: Node):
	if body.is_in_group("cavillaca"):
		Global.zona_actual = "Plaza"
		Global.descanso_con_zorro = false
