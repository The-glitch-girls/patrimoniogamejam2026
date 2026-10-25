extends Node

const RUTA_CONFIG := "user://ajustes.cfg"

var volumen_master: float = 1.0
var volumen_musica: float = 0.8
var volumen_efectos: float = 1.0
var volumen_ambiente: float = 1.0
var idioma: String = "es"


func _ready() -> void:
	cargar()
	aplicar()


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_CONFIG) != OK:
		return
	volumen_master = float(cfg.get_value("audio", "master", volumen_master))
	volumen_musica = float(cfg.get_value("audio", "musica", volumen_musica))
	volumen_efectos = float(cfg.get_value("audio", "sfx", volumen_efectos))
	volumen_ambiente = float(cfg.get_value("audio", "ambiente", volumen_ambiente))
	idioma = str(cfg.get_value("idioma", "actual", idioma))
	if not idioma in ["es", "en", "fr"]:
		idioma = "es"


func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", volumen_master)
	cfg.set_value("audio", "musica", volumen_musica)
	cfg.set_value("audio", "sfx", volumen_efectos)
	cfg.set_value("audio", "ambiente", volumen_ambiente)
	cfg.set_value("idioma", "actual", idioma)
	cfg.save(RUTA_CONFIG)


func aplicar() -> void:
	_set_bus("Master", volumen_master)
	_set_bus("Musica", volumen_musica)
	_set_bus("SFX", volumen_efectos)
	_set_bus("Ambiente", volumen_ambiente)


func set_volumen_master(valor: float) -> void:
	volumen_master = clampf(valor, 0.0, 1.0)
	_set_bus("Master", volumen_master)
	guardar()


func set_volumen_musica(valor: float) -> void:
	volumen_musica = clampf(valor, 0.0, 1.0)
	_set_bus("Musica", volumen_musica)
	guardar()


func set_volumen_efectos(valor: float) -> void:
	volumen_efectos = clampf(valor, 0.0, 1.0)
	_set_bus("SFX", volumen_efectos)
	guardar()


func set_volumen_ambiente(valor: float) -> void:
	volumen_ambiente = clampf(valor, 0.0, 1.0)
	_set_bus("Ambiente", volumen_ambiente)
	guardar()


func set_idioma(valor: String) -> void:
	if not valor in ["es", "en", "fr"]:
		return
	idioma = valor
	guardar()


func _set_bus(nombre: String, lineal: float) -> void:
	var indice := AudioServer.get_bus_index(nombre)
	if indice == -1:
		return
	var silenciado := lineal <= 0.001
	AudioServer.set_bus_mute(indice, silenciado)
	if silenciado:
		return
	AudioServer.set_bus_volume_db(indice, linear_to_db(lineal))
