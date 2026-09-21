extends CanvasLayer

func _process(_delta):
	$EnergiaBar.value = Global.energia
	$CorduraBar.value = Global.cordura
	$TiempoLabel.text = "Tiempo: %.1f" % Global.tiempo_juego
