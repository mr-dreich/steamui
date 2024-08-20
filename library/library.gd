extends MarginContainer


var _games: Array = []


func filter_games_by_os_only() -> void:
	pass


func load_games() -> void:
	var request := HTTPRequest.new()
	request.name = "GamesRequest"
	request.use_threads = true
	add_child(request)
	
	var id := str(Globals.get_steamid())
	var key := str("328217DE6BD2DF65FFE8152A23C7F698")
	var url := str("https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=",key,"&steamid=",id)
	var options := str("&format=json&include_appinfo=true&include_played_free_games")
	
	request.request_completed.connect(_on_library_request_completed)
	request.request(str(url,options))
	await request.request_completed
	request.queue_free()
	
	%LoadingPanel.hide()
	
	var btn_group := ButtonGroup.new()
	for game in _games:
		if not int(game["appid"]) in [12230, 12240, 12250]:
			var item := Globals.GameListItemScene.instantiate()
			item.pressed.connect(_on_library_item_pressed)
			item.name = str(game["appid"])
			%GamesList.add_child(item)
			item.set_button_group(btn_group)
			item.set_text(game["name"])
			item.set_icon(str(Globals.IconPath,game["appid"],".jpg"))
	
	for game in _games:
		var icon_path := str(Globals.IconPath,game.appid,".jpg")
		await get_game_icon(game, icon_path)
		var header_path := str(Globals.HeaderPath,game.appid,".jpg")
		await get_game_header(game, header_path)
		if %GamesList.has_node(str(game.appid)):
			%GamesList.get_node(str(game.appid)).set_icon(str(Globals.IconPath,game.appid,".jpg"))
	
	await get_game_details()


func get_game_details() -> void:
	var request := HTTPRequest.new()
	request.use_threads = true
	request.name = "GameDetailsRequest"
	add_child(request)
	request.request_completed.connect(_on_game_details_request_completed)
	
	var json := JSON.new()
	for game in _games:
		var data_path := str(Globals.GameDataPath,game.appid,'.json')
		if not FileAccess.file_exists(data_path):
			request.request_raw(str("https://store.steampowered.com/api/appdetails/?appids=",game.appid))
			await request.request_completed
		
		if FileAccess.file_exists(data_path):
			var file := FileAccess.open(data_path, FileAccess.READ)
			var _err := json.parse(file.get_as_text())
			var data := Dictionary(json.get_data())
			Globals.add_game(str(game.appid), data)
			await get_tree().process_frame
	
	request.queue_free()
	_games.clear()


func get_game_icon(game: Dictionary, icon_path: String) -> void:
	var request := HTTPRequest.new()
	request.use_threads = true
	request.name = "GameIconRequest"
	add_child(request)
	
	if not FileAccess.file_exists(icon_path):
		request.request_completed.connect(_on_game_icon_request_completed.bind(icon_path))
		var icon_url := str(game["appid"],"/",game["img_icon_url"],".jpg")
		request.request_raw(str("http://media.steampowered.com/steamcommunity/public/images/apps/",icon_url))
		await request.request_completed
	request.queue_free()
	
	if %GamesList.has_node(str(game.keys()[0])):
		%GamesList.get_node(str(game.keys()[0])).set_icon(icon_path)


func get_game_header(game: Dictionary, image_path: String) -> void:
	if not FileAccess.file_exists(image_path):
		var request := HTTPRequest.new()
		request.use_threads = true
		request.name = "GameHeaderRequest"
		add_child(request)
		request.request_completed.connect(_on_game_header_request_completed.bind(image_path))
		request.request_raw(str("https://steamcdn-a.akamaihd.net/steam/apps/",game.appid,"/library_hero.jpg"))
		await request.request_completed
		request.queue_free()


func _ready() -> void:
	Globals.steam_initialized.connect(_on_steam_initialized)
	
	match OS.get_name():
		"Windows":
			%OSOnly.texture_normal = load("res://textures/windowslogo.svg")
			%OSOnly.texture_pressed = load("res://textures/windowslogo.svg")
			%OSOnly.texture_hover = load("res://textures/windowslogo.svg")
		"macOS":
			%OSOnly.texture_normal = load("res://textures/applelogo.svg")
			%OSOnly.texture_pressed = load("res://textures/applelogo.svg")
			%OSOnly.texture_hover = load("res://textures/applelogo.svg")
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			%OSOnly.texture_normal = load("res://textures/linuxlog.svg")
			%OSOnly.texture_pressed = load("res://textures/linuxlog.svg")
			%OSOnly.texture_hover = load("res://textures/linuxlog.svg")


func _on_steam_initialized() -> void:
	%Profile.text = str(Globals.get_username()).to_upper()
	load_games()


func _on_library_request_completed(_result, _response_code, _headers, body) -> void:
	var json := JSON.new()
	var error := json.parse(body.get_string_from_utf8())
	if error == OK and json.get_data() is Dictionary:
		var response: Dictionary = json.get_data()
		if response.has("response"):
			if response["response"].has("games"):
				_games = response["response"]["games"]


func _on_game_details_request_completed(_result, _response_code, _headers, body) -> void:
	var json := JSON.new()
	var body_string: String = body.get_string_from_utf8()
	var error := json.parse(body_string)
	if error == OK and json.get_data() is Dictionary:
		var response: Dictionary = json.get_data()
		for appid in response:
			if response[appid].has('data'):
				var file := FileAccess.open(str(Globals.GameDataPath,appid,'.json'), FileAccess.WRITE)
				file.store_string(JSON.stringify(response[appid]['data']))


func _on_game_icon_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, path: String) -> void:
	if response_code != 404 and not body.is_empty():
		var image := Image.new()
		var error := image.load_jpg_from_buffer(body)
		if error == OK and not image.is_empty():
			image.save_jpg(path, 1.0)
		else:
			print("Failed to load game icon: ",path)


func _on_game_header_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, path: String) -> void:
	if response_code != 404 and not body.is_empty():
		var image := Image.new()
		var error := image.load_jpg_from_buffer(body)
		if error == OK and not image.is_empty():
			image.save_jpg(path, 1.0)
		else:
			print("Failed to load game header: ",path)


func _on_os_only_toggled(toggled_on: bool) -> void:
	var games := Globals.get_games()
	if toggled_on:
		%OSOnly.modulate = Color(0.16078431904316, 0.58431375026703, 0.98823529481888)
		match OS.get_name():
			"Windows":
				for appid in games:
					%GamesList.get_node(appid).visible = games[appid]['platforms'].windows
			"macOS":
				for appid in games:
					%GamesList.get_node(appid).visible = games[appid]['platforms'].mac
			"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				for appid in games:
					%GamesList.get_node(appid).visible = games[appid]['platforms'].linux
	else:
		%OSOnly.modulate = Color(0.45882353186607, 0.45882353186607, 0.45882353186607)
		for appid in games:
			%GamesList.get_node(appid).show()


func _on_library_item_pressed(appid: String) -> void:
	var header_path := str(Globals.HeaderPath,appid,".jpg")
	var file := FileAccess.open(header_path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var image := Image.new()
		image.load_jpg_from_buffer(file.get_buffer(file.get_length()))
		if image != null:
			var texture := ImageTexture.create_from_image(image)
			if texture != null:
				%GameHeader.texture = texture
	else:
		print(str("Failed to load file: ", header_path))
		%GameHeader.texture = null
