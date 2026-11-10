extends StaticBody2D

const CAPA_COLISION_SOLIDA := 4
const MASCARA_COLISION_SOLIDA := 1
# Anclas visuales, medidas desde el origen de cada personaje.
const OFFSET_PIES_CAVILLACA_Y := 103.0
const OFFSET_PIES_BEBE_Y := 48.0
const RANGO_ORDEN_X := 90.0
const RANGO_ORDEN_Y := 120.0

const SFX_RECOGER := preload("res://sfx/interaccion/bebe_recoger.ogg")
const SFX_DEJAR := preload("res://sfx/interaccion/bebe_dejar.ogg")
const OFFSET_CARGADO := Vector2(22, -52)
const SEGUIMIENTO := 14.0

var bob_t := 0.0
var llorando := false
@onready var sonido_accion: AudioStreamPlayer = $SonidoAccion

func _ready():
	add_to_group("bebe")
	z_index = 0
	# Usa la misma pareja de capa/máscara que el loro y el zorro.
	collision_layer = CAPA_COLISION_SOLIDA
	collision_mask = MASCARA_COLISION_SOLIDA
	var colision_activa := not Global.lleva_bebe
	$BloqueoPies.disabled = not colision_activa
	$AnimatedSprite2D.play("normal")

func _process(delta):
	# Global.lleva_bebe también cambia desde Refugio y desde las transiciones.
	# Mantener el collider sincronizado evita que quede apagado al soltarlo allí.
	var debe_deshabilitar_colision := Global.lleva_bebe
	if $BloqueoPies.disabled != debe_deshabilitar_colision:
		$BloqueoPies.set_deferred("disabled", debe_deshabilitar_colision)

	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if Global.lleva_bebe:
		# Al cargarlo, el dibujo debe quedar delante de Cavillaca.
		$AnimatedSprite2D.z_index = 1
		_seguir_carga(cavillaca, delta)
		return

	bob_t += delta
	$AnimatedSprite2D.position = Vector2(
		0,
		-0.7 + sin(bob_t * 3.2) * 0.1
	)

	if cavillaca != null and cavillaca.esta_cerca_del_bebe():
		$AnimatedSprite2D.modulate = Color(1.18, 1.12, 0.95)
	else:
		$AnimatedSprite2D.modulate = Color.WHITE
	_actualizar_orden_visual(cavillaca)


func _actualizar_orden_visual(cavillaca: Node2D) -> void:
	if cavillaca == null:
		$AnimatedSprite2D.z_index = 0
		return

	var diferencia := cavillaca.global_position - global_position
	var se_solapan := (
		absf(diferencia.x) < RANGO_ORDEN_X
		and absf(diferencia.y) < RANGO_ORDEN_Y
	)
	if not se_solapan:
		$AnimatedSprite2D.z_index = 0
		return

	var pies_cavillaca_y := cavillaca.global_position.y + OFFSET_PIES_CAVILLACA_Y
	var pies_bebe_y := global_position.y + OFFSET_PIES_BEBE_Y
	# Igual que loro/zorro: solo cambia cuál sprite se dibuja delante al solaparse.
	$AnimatedSprite2D.z_index = 1 if pies_cavillaca_y < pies_bebe_y else -1

func recoger():
	_sonar_accion(SFX_RECOGER)
	$BloqueoPies.set_deferred("disabled", true)
	Global.lleva_bebe = true
	llorando = false
	$AnimatedSprite2D.play("normal")


func dejar(_posicion: Vector2):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	
	if cavillaca == null:
		return

	_sonar_accion(SFX_DEJAR)
	# Usa la posición frontal solicitada por Cavillaca. Al dejarlo hacia abajo,
	# lo aleja un poco más para que su nueva colisión no aparezca dentro del jugador.
	var destino := _posicion
	if cavillaca.facing.y > 0.0:
		destino += Vector2.DOWN * 72.0
	global_position = destino

	Global.lleva_bebe = false
	$AnimatedSprite2D.position = Vector2(0, -14)
	$AnimatedSprite2D.modulate = Color.WHITE
	$BloqueoPies.set_deferred("disabled", false)


func reproducir_sonido_dejar() -> void:
	_sonar_accion(SFX_DEJAR)


func _sonar_accion(audio: AudioStream) -> void:
	sonido_accion.stop()
	sonido_accion.stream = audio
	sonido_accion.play()

func _seguir_carga(cavillaca: Node2D, delta: float):
	if cavillaca == null:
		return

	var lado := 1.0
	if "facing" in cavillaca and cavillaca.facing.x < 0.0:
		lado = -1.0

	var destino := cavillaca.global_position + Vector2(OFFSET_CARGADO.x * lado, OFFSET_CARGADO.y)
	global_position = global_position.lerp(destino, 1.0 - exp(-SEGUIMIENTO * delta))
	$AnimatedSprite2D.position = Vector2.ZERO
	$AnimatedSprite2D.modulate = Color(1.05, 0.98, 0.9)

func cambiar_llanto(valor: bool):
	llorando = valor

	if llorando:
		$AnimatedSprite2D.play("llorando")
	else:
		$AnimatedSprite2D.play("normal")
