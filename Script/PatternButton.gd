extends CheckBox
signal emit_num(num)

func _on_button_pressed():
	var n = int(get_name())
	emit_signal("emit_num", n)
