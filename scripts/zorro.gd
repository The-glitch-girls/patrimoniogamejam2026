extends Area2D

const RANGO_INTERACCION := 50.0
const VELOCIDAD_GUIAR := 40.0
const POSICION_CUEVA := Vector2(200, 200)

var guiando := false
var paso_t := 0.0
var cavillaca_sigue := false
var cueva_desbloqueada := false

func _ready():
	add_to_group("zorro")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta):
	paso_t += delta
	
	var cavillaca := get_tree().get_first_node_in_group("cavillaca") as Node2D
	if cavillaca != null:
		var distancia := global_position.distance_to(cavillaca.global_position)
		cavillaca_sigue = distancia <= RANGO_INTERACCION
		
		if guiando and cavillaca_sigue:
			_guiar_hacia_cueva(delta)
		elif guiando:
			_esperar_jugador(delta)
	
	_animar_caminata(delta)


func _guiar_hacia_cueva(delta: float):
	var hacia_cueva := (POSICION_CUEVA - global_position).normalized()
	global_position += hacia_cueva * VELOCIDAD_GUIAR * delta
	
	if global_position.distance_to(POSICION_CUEVA) < 20.0:
		guiando = false
		cueva_desbloqueada = true
		Global.mostrar_aviso("¡Cueva del zorro desbloqueada!")
		Global.cueva_zorro_desbloqueada = true


func _esperar_jugador(delta: float):
	pass


func iniciar_guia():
	guiando = true
	Global.mostrar_aviso("Sigue al zorro a su cueva")


func _animar_caminata(delta: float):
	var ritmo := 10.0 if guiando else 6.0
	var osc := sin(paso_t * ritmo)
	$Cuerpo.position.y = osc * 1.0
	$Cola.position = Vector2(-6, 4 + osc * 1.5)


func _on_body_entered(body: Node):
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = true
		if not cueva_desbloqueada:
			Global.prompt_interaccion = "E  Seguir zorro"


func _on_body_exited(body: Node):
	if body.is_in_group("cavillaca"):
		Global.zorro_cerca = false
		Global.prompt_interaccion = ""
