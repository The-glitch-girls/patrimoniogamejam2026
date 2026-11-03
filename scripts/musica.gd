extends Node

const PISTAS := {
	"menu": "res://sfx/aa_menu_juego.ogg",
	"juego": "res://sfx/tema_juego.ogg",
}
const PISTA_COMBATE := "res://sfx/combate/aa_combate.ogg"

const VOLUMEN := {
	"menu": -8.0,
	"juego": -8.0,
	"recuerdo": -8.0,
}

var reproductor: AudioStreamPlayer
var reproductor_combate: AudioStreamPlayer
var actual := ""
var fundido: Tween
var fundido_combate: Tween
var combate_activo := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reproductor = AudioStreamPlayer.new()
	reproductor.bus = "Musica"
	reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor)
	reproductor_combate = AudioStreamPlayer.new()
	reproductor_combate.name = "MusicaCombate"
	reproductor_combate.bus = "Musica"
	reproductor_combate.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor_combate)
	tocar("menu")


func tocar(nombre: String) -> void:
	if nombre == actual or not PISTAS.has(nombre):
		return
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
	fundido.tween_property(reproductor, "volume_db", VOLUMEN[nombre], 0.7)


func tocar_stream(nombre: String, pista: AudioStream, volumen_db: float = -8.0, repetir: bool = true) -> void:
	if pista == null or nombre == actual:
		return
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
	if fundido_combate and fundido_combate.is_running():
		fundido_combate.kill()
	reproductor_combate.stream = pista
	reproductor_combate.volume_db = -40.0
	reproductor_combate.play()
	fundido_combate = create_tween()
	fundido_combate.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido_combate.tween_property(reproductor_combate, "volume_db", -8.0, 0.5)


func terminar_combate() -> void:
	if not combate_activo:
		return
	combate_activo = false
	if fundido and fundido.is_running():
		fundido.kill()
	fundido = create_tween()
	fundido.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fundido.tween_property(reproductor, "volume_db", VOLUMEN.get(actual, -8.0), 0.7)
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
	if fundido_combate and fundido_combate.is_running():
		fundido_combate.kill()
	if is_instance_valid(reproductor_combate):
		reproductor_combate.stop()
	if is_instance_valid(reproductor):
		reproductor.stop()
