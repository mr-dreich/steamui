extends MarginContainer


signal pressed(id: String)

var _normal: String = "8d95a4"
var _hover: String = "d1d4d4"


func set_button_group(button_group: ButtonGroup) -> void:
	$Button.button_group = button_group


func update(appid: String, data: Dictionary) -> void:
	set_text(data["name"])
	set_icon(str(Globals.IconPath,appid,".jpg"))
	match OS.get_name():
		"Windows":
			if data.has('windows'):
				%NotSupported.visible = data.windows
		"macOS":
			if data.has('macos'):
				%NotSupported.visible = data.macos
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			if data.has('linux'):
				%NotSupported.visible = data.linux


func set_text(game_name: String) -> void:
	var new_name := str(game_name).to_lower().capitalize()
	%Name.text = new_name
	$Button.tooltip_text = new_name


func set_icon(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var buffer := file.get_buffer(file.get_length())
		if not buffer.is_empty():
			var image := Image.new()
			var error := image.load_jpg_from_buffer(buffer)
			if error == OK and not image.is_empty():
				var texture := ImageTexture.create_from_image(image)
				if texture != null:
					%Icon.texture = texture


func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		%Name.add_theme_color_override("font_color", Color(_hover))
		pressed.emit(str(name))
	else:
		%Name.add_theme_color_override("font_color", Color(_normal))


func _on_mouse_entered() -> void:
	%Name.add_theme_color_override("font_color", Color(_hover))


func _on_mouse_exited() -> void:
	if not $Button.button_pressed:
		%Name.add_theme_color_override("font_color", Color(_normal))
