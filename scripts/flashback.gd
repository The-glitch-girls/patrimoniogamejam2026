extends Control

signal terminado

const ID_FLASHBACK := "insistencia"

func _ready():
	$Continuar.pressed.connect(_continuar)

func _continuar():
	if not ID_FLASHBACK in Global.flashbacks_desbloqueados:
		Global.flashbacks_desbloqueados.append(ID_FLASHBACK)
	
	Global.presencia_cuniraya += 1.0
	
	terminado.emit()
	queue_free()
