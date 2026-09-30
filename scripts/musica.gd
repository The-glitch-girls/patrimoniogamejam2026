extends Node

const PISTAS := {
	"menu": "res://sfx/aa_menu_juego.ogg",
	"juego": "res://sfx/aa_gameplay_juego.ogg",
	"ganar": "res://sfx/musica_ganar.ogg",
	"perder": "res://sfx/aa_perder.ogg",
}

const VOLUMEN := {
	"menu": -8.0,
	"juego": -8.0,
	"recuerdo": -8.0,
	"ganar": -8.0,
	"perder": -5.0,
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
