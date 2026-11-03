extends Node

const PISTAS := {
	"menu": "res://sfx/aa_menu.ogg",
	"juego": "res://sfx/aa_tema_gameplay.ogg",
	"tension": "res://sfx/aa_tension_gameplay.ogg",
}
const PISTA_COMBATE := "res://sfx/combate/aa_combate.ogg"
const DURACION_FUNDIDO_TENSION := 5.0

var reproductor: AudioStreamPlayer
var reproductor_tension: AudioStreamPlayer
var reproductor_combate: AudioStreamPlayer
var actual := ""
var fundido: Tween
var fundido_tension: Tween
var fundido_combate: Tween
var combate_activo := false
var tension_activa := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reproductor = AudioStreamPlayer.new()
	reproductor.bus = "Musica"
	reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor)
	reproductor_tension = AudioStreamPlayer.new()
	reproductor_tension.name = "MusicaTension"
	reproductor_tension.bus = "Musica"
	reproductor_tension.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor_tension)
	reproductor_combate = AudioStreamPlayer.new()
	reproductor_combate.name = "MusicaCombate"
	reproductor_combate.bus = "Musica"
	reproductor_combate.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor_combate)
	tocar("menu")


func tocar(nombre: String) -> void:
	if nombre == actual or not PISTAS.has(nombre):
		return
	if nombre != "juego":
		_detener_tension()
	actual = nombre
	var pista := load(PISTAS[nombre]) as AudioStreamOggVorbis
	if pista == null:
		return
	pista.loop = true
	if fundido:
		fundido.kill()
	fundido = create_tween()
	fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if reproductor.playing:
		fundido.tween_property(reproductor, "volume_db", -40.0, 0.45)
		fundido.tween_callback(func():
			reproductor.stream = pista
			reproductor.volume_db = -40.0
			reproductor.play()
		)
	else:
		reproductor.stream = pista
		reproductor.volume_db = -40.0
		reproductor.play()
	fundido.tween_property(reproductor, "volume_db", 0.0, 0.7)


func tocar_stream(nombre: String, pista: AudioStream, volumen_db: float = 0.0, repetir: bool = true) -> void:
	if pista == null or nombre == actual:
		return
	_detener_tension()
	if combate_activo:
		if fundido_combate and fundido_combate.is_running():
			fundido_combate.kill()
		reproductor_combate.stop()
		combate_activo = false
	actual = nombre
	if pista is AudioStreamOggVorbis:
		(pista as AudioStreamOggVorbis).loop = repetir
	if fundido and fundido.is_running():
		fundido.kill()
	fundido = create_tween()
	fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if reproductor.playing:
		fundido.tween_property(reproductor, "volume_db", -40.0, 0.45)
		fundido.tween_callback(func():
			reproductor.stream = pista
			reproductor.volume_db = -40.0
			reproductor.play()
		)
	else:
		reproductor.stream = pista
		reproductor.volume_db = -40.0
		reproductor.play()
	fundido.tween_property(reproductor, "volume_db", volumen_db, 0.7)


func iniciar_juego_con_tension() -> void:
	if actual == "juego" and reproductor.playing and reproductor_tension.playing:
		return
	actual = "juego"
	combate_activo = false
	tension_activa = false
	if fundido and fundido.is_running():
		fundido.kill()
	if fundido_tension and fundido_tension.is_running():
		fundido_tension.kill()
	if reproductor.playing:
		fundido = create_tween()
		fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		fundido.tween_property(reproductor, "volume_db", -40.0, 0.45)
		fundido.tween_callback(_reproducir_juego_y_tension)
	else:
		_reproducir_juego_y_tension()


func _reproducir_juego_y_tension() -> void:
	var pista_juego := load(PISTAS["juego"]) as AudioStreamOggVorbis
	var pista_tension := load(PISTAS["tension"]) as AudioStreamOggVorbis
	if pista_juego == null or pista_tension == null:
		push_error("No se pudieron cargar las pistas de juego y tensión")
		return
	pista_juego.loop = true
	pista_tension.loop = true
	reproductor.stream = pista_juego
	reproductor.volume_db = -40.0
	reproductor_tension.stream = pista_tension
	reproductor_tension.volume_db = -80.0
	reproductor.play()
	reproductor_tension.play()
	fundido = create_tween()
	fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido.tween_property(reproductor, "volume_db", 0.0, 0.7)


func actualizar_tension(activa: bool) -> void:
	if tension_activa == activa:
		return
	tension_activa = activa
	if not reproductor_tension.playing or combate_activo:
		return
	if fundido_tension and fundido_tension.is_running():
		fundido_tension.kill()
	fundido_tension = create_tween()
	fundido_tension.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var volumen_objetivo := 0.0 if activa else -80.0
	fundido_tension.tween_property(
		reproductor_tension,
		"volume_db",
		volumen_objetivo,
		DURACION_FUNDIDO_TENSION
	)


func _detener_tension() -> void:
	tension_activa = false
	if fundido_tension and fundido_tension.is_running():
		fundido_tension.kill()
	if is_instance_valid(reproductor_tension):
		reproductor_tension.stop()


func iniciar_combate() -> void:
	if combate_activo:
		return
	var pista := load(PISTA_COMBATE) as AudioStreamOggVorbis
	if pista == null:
		return
	pista.loop = true
	combate_activo = true
	if fundido and fundido.is_running():
		fundido.kill()
	fundido = create_tween()
	fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido.tween_property(reproductor, "volume_db", -80.0, 0.5)
	if fundido_tension and fundido_tension.is_running():
		fundido_tension.kill()
	fundido_tension = create_tween()
	fundido_tension.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido_tension.tween_property(reproductor_tension, "volume_db", -80.0, 0.5)
	if fundido_combate and fundido_combate.is_running():
		fundido_combate.kill()
	reproductor_combate.stream = pista
	reproductor_combate.volume_db = -40.0
	reproductor_combate.play()
	fundido_combate = create_tween()
	fundido_combate.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido_combate.tween_property(reproductor_combate, "volume_db", 0.0, 0.5)


func terminar_combate() -> void:
	if not combate_activo:
		return
	combate_activo = false
	if fundido and fundido.is_running():
		fundido.kill()
	fundido = create_tween()
	fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido.tween_property(reproductor, "volume_db", 0.0, 0.7)
	if reproductor_tension.playing:
		if fundido_tension and fundido_tension.is_running():
			fundido_tension.kill()
		fundido_tension = create_tween()
		fundido_tension.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		var volumen_tension := 0.0 if tension_activa else -80.0
		fundido_tension.tween_property(reproductor_tension, "volume_db", volumen_tension, DURACION_FUNDIDO_TENSION)
	if fundido_combate and fundido_combate.is_running():
		fundido_combate.kill()
	fundido_combate = create_tween()
	fundido_combate.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido_combate.tween_property(reproductor_combate, "volume_db", -40.0, 0.5)
	fundido_combate.tween_callback(reproductor_combate.stop)


func detener_pista_combate() -> void:
	if fundido_combate and fundido_combate.is_running():
		fundido_combate.kill()
	if not is_instance_valid(reproductor_combate) or not reproductor_combate.playing:
		return
	fundido_combate = create_tween()
	fundido_combate.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido_combate.tween_property(reproductor_combate, "volume_db", -40.0, 0.5)
	fundido_combate.tween_callback(reproductor_combate.stop)


func detener() -> void:
	if fundido and fundido.is_running():
		fundido.kill()
	actual = ""
	combate_activo = false
	_detener_tension()
	if fundido_combate and fundido_combate.is_running():
		fundido_combate.kill()
	if is_instance_valid(reproductor_combate):
		reproductor_combate.stop()
	if is_instance_valid(reproductor):
		reproductor.stop()
