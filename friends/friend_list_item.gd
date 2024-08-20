extends MarginContainer


const OnlineColor1 = '69c8f3'
const OnlineColor2 = '45819b'

const OfflineColor1 = '969696'
const OfflineColor2 = '5e5e5e'

const AwayColor1 = '3b6276'
const AwayColor2 = '3b6276'

const InGameColor1 = 'd8f8b7'
const InGameColor2 = '88ba52'
const InGameColor3 = '597536'


func set_icon(file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var image := Image.new()
		image.load_jpg_from_buffer(file.get_buffer(file.get_length()))
		if image != null:
			var texture := ImageTexture.create_from_image(image)
			if texture != null:
				%Icon.texture = texture


func set_title(text: String) -> void:
	%Name.text = text


func set_status(text: String) -> void:
	%Status.text = text


func set_offline(last_online: String) -> void:
	%Name.add_theme_color_override("font_color", Color(OfflineColor1))
	%Game.hide()
	%Status.add_theme_color_override("font_color", Color(OfflineColor2))
	%Status.show()
	var time := Time.get_datetime_dict_from_unix_time(last_online.to_int())
	var display_string := "%d/%02d/%02d" % [time.day, time.month, time.year];
	set_status(str("Last seen: ",display_string))


func set_online() -> void:
	%Name.add_theme_color_override("font_color", Color(OnlineColor1))
	%Game.hide()
	%Status.add_theme_color_override("font_color", Color(OnlineColor2))
	%Status.show()
	set_status("Online")


func set_away() -> void:
	%Name.add_theme_color_override("font_color", Color(AwayColor1))
	%Game.hide()
	%Status.add_theme_color_override("font_color", Color(AwayColor2))
	%Status.show()
	set_status("Away")


func set_ingame(game_name: String) -> void:
	%Name.add_theme_color_override("font_color", Color(InGameColor1))
	%Game.show()
	%Game.add_theme_color_override("font_color", Color(InGameColor2))
	%Status.hide()
	%Game.text = game_name


func _on_mouse_entered() -> void:
	%Background.show()


func _on_mouse_exited() -> void:
	%Background.hide()
