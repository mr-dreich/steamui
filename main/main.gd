extends Control


var _friends: Dictionary = {}
var _friends_window: Window = null


func load_friends() -> void:
	%FriendsLoading.show()
	%FriendsLoading.play('default')
	
	var request := HTTPRequest.new()
	add_child(request)
	request.name = "FriendsRequest"
	request.use_threads = true
	request.request_completed.connect(_on_get_friends_request_completed)
	
	var key := str("328217DE6BD2DF65FFE8152A23C7F698")
	var friends := Steam.getUserSteamFriends()
	for friend in friends:
		var url := str("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=",key,"&format=json&steamids=",friend.id)
		request.request(url)
		await request.request_completed
	
	request.queue_free()
	
	Globals.set_friends(_friends)
	_friends.clear()
	
	%FriendsLoading.stop()
	%FriendsLoading.hide()
	%Friends.disabled = false


func _ready() -> void:
	Globals.steam_initialized.connect(_on_steam_initialized)
	
	%LoadingPanel.show()
	
	var btn_group := ButtonGroup.new()
	for button: Button in %Categories.get_children():
		button.toggled.connect(_on_category_button_pressed.bind(button))
		button.button_group = btn_group
	
	%Library.button_pressed = true
	%SteamLoading.play('default')


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func _on_steam_initialized() -> void:
	%Profile.text = str(Globals.get_username()).to_upper()
	load_friends()


func _on_category_button_pressed(toggled_on: bool, button: Button) -> void:
	%CategoryPanels.get_node(str(button.name)).visible = toggled_on


func _on_get_friends_request_completed(_result, _response_code, _headers, body) -> void:
	var json := JSON.new()
	var error := json.parse(body.get_string_from_utf8())
	if error == OK and json.get_data() is Dictionary:
		var response: Dictionary = json.get_data()
		if response.has("response"):
			if response["response"].has("players"):
				var friend: Dictionary = response["response"]["players"][0]
				_friends[friend.steamid] = friend


func _on_add_game_pressed() -> void:
	pass # Replace with function body.


func _on_downloads_pressed() -> void:
	pass # Replace with function body.


func _on_friends_pressed() -> void:
	if _friends_window == null:
		_friends_window = Window.new()
		_friends_window.close_requested.connect(_on_close_friends_window)
		_friends_window.title = str("Steam Friends")
		_friends_window.transient = false
		_friends_window.exclusive = false
		_friends_window.always_on_top = false
		_friends_window.min_size = Vector2i(180, 600)
		_friends_window.size = Vector2i(280, 700)
		add_child(_friends_window)
		
		_friends_window.add_child(Globals.Friends.instantiate())
		
		var parent_rect: Rect2 = get_viewport().get_visible_rect()
		_friends_window.position.x = get_viewport().position.x + parent_rect.size.x / 2 - _friends_window.size.x / 2
		_friends_window.position.y = get_viewport().position.y + parent_rect.size.y / 2 - _friends_window.size.y / 2
	else:
		_friends_window.grab_focus()


func _on_close_friends_window() -> void:
	_friends_window.hide()
	_friends_window.queue_free()
