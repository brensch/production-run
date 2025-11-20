extends PanelContainer

func add_log(message: String):
	var entry = "[color=yellow]" + Time.get_time_string_from_system() + "[/color]: " + message
	$LogText.text = entry + "\n" + $LogText.text
