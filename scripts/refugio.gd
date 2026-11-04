extends Node2D

const RECUPERACION_ENERGIA_POR_SEGUNDO := 8.0
const RANGO_INTERACCION := 40.0
const RANGO_ENTRADA := 150.0

var bebe_con_zorro := false
var jugador_en_entrada := false
var puerta_abierta := true
var descanso_activo := false

@onready var puerta: Sprite2D = $Puerta
@onready var punto_descanso: Marker2D = $PuntoDescanso

func _ready():
	add_to_group("zona_segura")
	_crear_puerta()


func _process(delta: float) -> void:
	jugador_en_entrada = _cavillaca_en_entrada()
	var puerta_abierta_ahora := jugador_en_entrada and Global.recuerdos_obtenidos > 0
	_cambiar_puerta(puerta_abierta_ahora)

	# El descanso solo recupera energía después de iniciar con R y mientras
	# Cavillaca siga dentro del rango permitido.
	if descanso_activo and not puede_descansar():
		descanso_activo = false
	if descanso_activo:
		Global.recuperar_energia(RECUPERACION_ENERGIA_POR_SEGUNDO * delta)
		if Global.energia >= Global.ENERGIA_MAX:
			descanso_activo = false
	Global.descanso_con_zorro = descanso_activo


func descansar() -> void:
	if Global.recuerdos_obtenidos < 1:
		Global.mostrar_aviso("El zorro aún no te ofrece descanso")
		return
	if not _cavillaca_en_entrada():
		Global.mostrar_aviso("Acércate al tronco para descansar")
		return
	if Global.energia >= Global.ENERGIA_MAX:
		Global.mostrar_aviso("Tu energía ya está completa")
		return
	descanso_activo = true
	Global.mostrar_aviso("Descansando junto al tronco")


func puede_descansar() -> bool:
	return _cavillaca_en_entrada() and Global.recuerdos_obtenidos > 0


func _cavillaca_en_entrada() -> bool:
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	return (
		cavillaca != null
		and cavillaca.global_position.distance_to(punto_descanso.global_position) <= RANGO_ENTRADA
	)


func _crear_puerta() -> void:
	puerta.visible = true
	_cambiar_puerta(false)


func _cambiar_puerta(abierta: bool) -> void:
	if puerta_abierta == abierta:
		return
	puerta_abierta = abierta
	puerta.visible = not abierta
			
func dejar_bebe_con_zorro():
	if not Global.cuidado_bebe_desbloqueado:
		Global.mostrar_aviso("Necesitas el Recuerdo 2 para esto")
		return
	
	var zorro := get_tree().get_first_node_in_group("zorro") as Node2D
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if (
		zorro == null
		or cavillaca == null
		or cavillaca.global_position.distance_to(zorro.global_position) >= RANGO_INTERACCION
	):
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
		bebe.global_position = zorro.global_position


func recoger_bebe_del_zorro():
	if not bebe_con_zorro:
		return
	
	bebe_con_zorro = false
	Global.lleva_bebe = true
	Global.mostrar_aviso("Bebé recogido del zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.recoger()
