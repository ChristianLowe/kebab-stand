extends Button

func _pressed():
	Global.emit(self.name)
