@tool
extends StaticBody2D

@export var imagen: Texture2D:
	set(valor):
		imagen = valor
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite != null:
			sprite.texture = valor

var piedra_recolectada := false


func _ready() -> void:
	$Sprite2D.texture = imagen
	$DetectorInteraccion.body_entered.connect(_al_entrar_en_rango)
	$DetectorInteraccion.body_exited.connect(_al_salir_del_rango)


func _al_entrar_en_rango(body: Node2D) -> void:
	if body.is_in_group("cavillaca") and body.has_method("registrar_contacto_jarron"):
		body.call("registrar_contacto_jarron", self, true)


func _al_salir_del_rango(body: Node2D) -> void:
	if body.is_in_group("cavillaca") and body.has_method("registrar_contacto_jarron"):
		body.call("registrar_contacto_jarron", self, false)


func puede_recolectar_piedra() -> bool:
	return not piedra_recolectada


func recolectar_piedra() -> bool:
	if piedra_recolectada:
		return false
	piedra_recolectada = true
	return true
