extends Node2D

const STREAM_ENERGIA_CARGANDO: AudioStreamOggVorbis = preload("res://sfx/interaccion/energia_cargando.ogg")
const RECUPERACION_ENERGIA_POR_SEGUNDO := 8.0
const RANGO_INTERACCION := 40.0
const RANGO_ENTRADA := 150.0
const DURACION_ANIMACION_PUERTA := 0.32
const ANCHO_PUERTA_ABIERTA := 0.06

var bebe_con_zorro := false
var jugador_en_entrada := false
var puerta_abierta := false
var descanso_activo := false
var escala_puerta := Vector2.ONE
var animacion_puerta: Tween

@onready var puerta: Sprite2D = $Puerta
@onready var punto_descanso: Marker2D = $PuntoDescanso
@onready var sonido_puerta: AudioStreamPlayer2D = $SonidoPuerta
@onready var sonido_energia_cargando: AudioStreamPlayer = $SonidoEnergiaCargando
@onready var sonido_energia_full: AudioStreamPlayer = $SonidoEnergiaFull

func _ready():
	add_to_group("zona_segura")
	var stream_carga := STREAM_ENERGIA_CARGANDO.duplicate() as AudioStreamOggVorbis
	stream_carga.loop = true
	sonido_energia_cargando.stream = stream_carga
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
		if not sonido_energia_cargando.playing:
			sonido_energia_cargando.play()
		Global.recuperar_energia(RECUPERACION_ENERGIA_POR_SEGUNDO * delta)
		if Global.energia >= Global.ENERGIA_MAX:
			descanso_activo = false
			sonido_energia_cargando.stop()
			sonido_energia_full.play()
	else:
		sonido_energia_cargando.stop()
	Global.descanso_con_zorro = descanso_activo


func descansar() -> void:
	if Global.recuerdos_obtenidos < 1:
		_mostrar_aviso_zorro("El zorro aún no te ofrece descanso")
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
	escala_puerta = puerta.scale
	puerta.visible = true


func _cambiar_puerta(abierta: bool) -> void:
	if puerta_abierta == abierta:
		return
	puerta_abierta = abierta
	if sonido_puerta.stream != null:
		sonido_puerta.play()
	if animacion_puerta != null and animacion_puerta.is_running():
		animacion_puerta.kill()

	animacion_puerta = create_tween()
	animacion_puerta.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if abierta:
		animacion_puerta.tween_property(
			puerta,
			"scale",
			Vector2(escala_puerta.x * ANCHO_PUERTA_ABIERTA, escala_puerta.y),
			DURACION_ANIMACION_PUERTA
		)
		animacion_puerta.tween_callback(_ocultar_puerta)
	else:
		if not puerta.visible:
			puerta.scale = Vector2(escala_puerta.x * ANCHO_PUERTA_ABIERTA, escala_puerta.y)
		puerta.visible = true
		animacion_puerta.tween_property(puerta, "scale", escala_puerta, DURACION_ANIMACION_PUERTA)


func _ocultar_puerta() -> void:
	puerta.visible = false
	puerta.scale = escala_puerta
			
func dejar_bebe_con_zorro():
	if not Global.cuidado_bebe_desbloqueado:
		_mostrar_aviso_zorro("Necesitas el Recuerdo 2 para esto")
		return
	
	var zorro := get_tree().get_first_node_in_group("zorro") as Node2D
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if (
		zorro == null
		or cavillaca == null
		or cavillaca.global_position.distance_to(zorro.global_position) >= RANGO_INTERACCION
	):
		_mostrar_aviso_zorro("El zorro no está cerca")
		return
	
	if not Global.lleva_bebe:
		_mostrar_aviso_zorro("No llevas al bebé")
		return
	
	bebe_con_zorro = true
	Global.lleva_bebe = false
	_mostrar_aviso_zorro("Bebé dejado con el zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.call("reproducir_sonido_dejar")
		bebe.global_position = zorro.global_position


func recoger_bebe_del_zorro():
	if not bebe_con_zorro:
		return
	
	bebe_con_zorro = false
	Global.lleva_bebe = true
	_mostrar_aviso_zorro("Bebé recogido del zorro")
	
	var bebe := get_tree().get_first_node_in_group("bebe")
	if bebe != null:
		bebe.recoger()


func _mostrar_aviso_zorro(texto: String) -> void:
	Global.mostrar_aviso(texto)
	var zorro := get_tree().get_first_node_in_group("zorro")
	if zorro != null:
		zorro.call("reproducir_sonido_mensaje")
