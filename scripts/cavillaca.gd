extends CharacterBody2D

const VELOCIDAD_CAMINAR := 100.0
const VELOCIDAD_CORRER := 180.0

var energia_temporizador := 0.0

func _physics_process(delta):
	var direccion := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var esta_corriendo := Input.is_action_pressed("correr")
	var velocidad_actual := VELOCIDAD_CAMINAR

	if esta_corriendo:
		velocidad_actual = VELOCIDAD_CORRER

	velocity = direccion * velocidad_actual

	move_and_slide()

	# Consumo de energía mientras se mueve
	if direccion != Vector2.ZERO:
		energia_temporizador += delta

		if energia_temporizador >= 1.0:
			energia_temporizador = 0.0

			if esta_corriendo:
				Global.perder_energia(Global.COSTO_CORRER)
			else:
				Global.perder_energia(Global.COSTO_CAMINAR)
