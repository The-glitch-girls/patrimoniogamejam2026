extends Control

signal terminado

func _ready():
	$Continuar.pressed.connect(_continuar)

func _continuar():
	terminado.emit()
	queue_free()
