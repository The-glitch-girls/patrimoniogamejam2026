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
	_crear_brillo()

# Destellos suaves alrededor del bebé mientras está en el suelo, para que se note que se puede recoger.
var brillo: CPUParticles2D

func _crear_brillo():
	brillo = CPUParticles2D.new()
	brillo.scale = Vector2.ONE / scale
	brillo.amount = 8
	brillo.lifetime = 1.4
	brillo.texture = _textura_destello()
	# Nacen en un anillo alrededor del bebé, nunca sobre su cara.
	brillo.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	brillo.emission_sphere_radius = 62.0
	brillo.direction = Vector2.UP
	brillo.spread = 20.0
	brillo.gravity = Vector2.ZERO
	brillo.initial_velocity_min = 3.0
	brillo.initial_velocity_max = 8.0
	brillo.scale_amount_min = 0.6
	brillo.scale_amount_max = 1.0
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0))
	curva.add_point(Vector2(0.4, 1))
	curva.add_point(Vector2(1, 0))
	brillo.scale_amount_curve = curva
	brillo.color = Color(1.0, 0.95, 0.7, 0.85)
	add_child(brillo)

func _textura_destello() -> Texture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 14
	tex.height = 14
	return tex

func _process(delta):
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	brillo.emitting = not Global.lleva_bebe
	if Global.lleva_bebe:
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
