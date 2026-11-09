extends StaticBody2D

const SFX_RECOGER := preload("res://sfx/interaccion/bebe_recoger.ogg")
const SFX_DEJAR := preload("res://sfx/interaccion/bebe_dejar.ogg")
const OFFSET_CARGADO := Vector2(22, -52)
const SEGUIMIENTO := 14.0

var bob_t := 0.0
var llorando := false
@onready var sonido_accion: AudioStreamPlayer = $SonidoAccion

func _ready():
	add_to_group("bebe")
	$AnimatedSprite2D.play("normal")

func _process(delta):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if Global.lleva_bebe:
		z_index = 1
		_seguir_carga(cavillaca, delta)
		return

	bob_t += delta
	$AnimatedSprite2D.position = Vector2(
		0,
		-14 + sin(bob_t * 3.2) * 2.0
	)

	if cavillaca != null and cavillaca.esta_cerca_del_bebe():
		$AnimatedSprite2D.modulate = Color(1.18, 1.12, 0.95)
	else:
		$AnimatedSprite2D.modulate = Color.WHITE
	
	z_index = 1

func recoger():
	_sonar_accion(SFX_RECOGER)
	$CollisionShape2D.set_deferred("disabled", true)
	Global.lleva_bebe = true
	llorando = false
	$AnimatedSprite2D.play("normal")


func dejar(_posicion: Vector2):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	
	if cavillaca == null:
		return

	_sonar_accion(SFX_DEJAR)
	var pies := cavillaca.get_node("CollisionShape2D") as CollisionShape2D
	global_position = pies.global_position

	Global.lleva_bebe = false
	$AnimatedSprite2D.position = Vector2(0, -14)
	$AnimatedSprite2D.modulate = Color.WHITE
	$CollisionShape2D.set_deferred("disabled", false)


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
