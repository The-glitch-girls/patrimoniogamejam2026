extends Node

const PISTAS := {
	"menu": "res://sfx/musica_menu.ogg",
	"juego": "res://sfx/musica_juego.ogg",
	"ganar": "res://sfx/musica_ganar.ogg",
	"perder": "res://sfx/musica_perder.ogg",
}

const VOLUMEN := {
	"menu": -10.0,
	"juego": -12.0,
	"ganar": -8.0,
	"perder": -10.0,
}

var reproductor: AudioStreamPlayer
var actual := ""
var fundido: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reproductor = AudioStreamPlayer.new()
	reproductor.bus = "Musica"
	reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor)
	tocar("menu")


func tocar(nombre: String) -> void:
	if nombre == actual or not PISTAS.has(nombre):
		return
	actual = nombre
	var pista := load(PISTAS[nombre]) as AudioStreamOggVorbis
	if pista == null:
		return
	pista.loop = nombre != "ganar"
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
