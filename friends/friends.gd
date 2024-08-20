extends Control


enum State {OFFLINE, ONLINE, BUSY, AWAY, SNOOZE, LOOKING_TO_TRADE, LOOKING_TO_PLAY}

var _ingame_collapsed: bool = false
var _online_collapsed: bool = false
var _offline_collapsed: bool = false


func load_friends_list() -> void:
	var friends := Globals.get_friends()
	for steamid in friends:
		var friend: Dictionary = friends[steamid]
		var item := Globals.FriendListItem.instantiate()
		item.name = str(friend.steamid)
		%Online.add_child(item)
		item.set_title(friend.personaname)
	
	await get_tree().process_frame


func sort_friends() -> void:
	var ingame: int = 0
	var online: int = 0
	var offline: int = 0
	
	var friends := Globals.get_friends()
	for steamid in friends:
		var friend: Dictionary = friends[steamid]
		var item: Control = %Online.get_node(str(friend.steamid))
		
		if friend.has('gameextrainfo'):
			item.reparent(%InGame)
			item.set_ingame(friend.gameextrainfo)
			ingame += 1
			
		else:
			match str(friend.personastate).to_int():
				State.OFFLINE:
					item.reparent(%Offline)
					item.set_offline(str(friend.profilestate))
					offline += 1
				State.ONLINE:
					item.set_online()
					online += 1
				State.BUSY:
					item.reparent(%Busy)
					item.set_away()
					online += 1
				State.AWAY:
					item.reparent(%Away)
					item.set_away()
					online += 1
				State.SNOOZE:
					item.reparent(%Snooze)
					item.set_away()
					online += 1
				State.LOOKING_TO_TRADE:
					item.set_online()
					online += 1
				State.LOOKING_TO_PLAY:
					item.set_online()
					online += 1
	
	await get_tree().process_frame
	
	%InGameLabel.text = str("- In Game (",ingame,")")
	%OnlineLabel.text = str("- Online (",online,")")
	%OfflineLabel.text = str("- Offline (",offline,")")


func get_friends_icons() -> void:
	var request := HTTPRequest.new()
	request.use_threads = true
	request.name = "FriendIconRequest"
	add_child(request)

	var friends := Globals.get_friends()
	for steamid in friends:
		var friend: Dictionary = friends[steamid]
		var icon_path := str(Globals.FriendsPath,str(friend.steamid),'.jpg')
		if not FileAccess.file_exists(icon_path):
			request.request_completed.connect(_on_frend_icon_request_completed.bind(icon_path))
			request.request_raw(friend.avatar)
			await request.request_completed
		
		if FileAccess.file_exists(icon_path):
			%Online.get_node(str(friend.steamid)).set_icon(icon_path)
		
	request.queue_free()


func _ready() -> void:
	%ProfileName.text = Globals.get_username()
	%ProfileIcon.texture = Globals.get_icon()
	
	await load_friends_list()
	await get_friends_icons()
	await sort_friends()
	
	%InGameBox.custom_minimum_size.y = %InGame.size.y
	%OnlineBox.custom_minimum_size.y = %OnlineList.size.y
	%OfflineBox.custom_minimum_size.y = %Offline.size.y


func _on_frend_icon_request_completed(_result, _response_code, _headers, body, path: String) -> void:
	if not body.is_empty():
		var image := Image.new()
		var error := image.load_jpg_from_buffer(body)
		if error == OK and not image.is_empty():
			image.save_jpg(path, 1.0)


func _on_in_game_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				var tween := create_tween()
				if _ingame_collapsed:
					tween.tween_property(%InGameBox, 'custom_minimum_size:y', %InGame.size.y, 0.25)
					await tween.finished
					_ingame_collapsed = false
				else:
					tween.tween_property(%InGameBox, 'custom_minimum_size:y', 0, 0.25)
					await tween.finished
					_ingame_collapsed = true


func _on_online_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				var tween := create_tween()
				if _online_collapsed:
					tween.tween_property(%OnlineBox, 'custom_minimum_size:y', %OnlineList.size.y, 0.25)
					await tween.finished
					_online_collapsed = false
				else:
					tween.tween_property(%OnlineBox, 'custom_minimum_size:y', 0, 0.25)
					await tween.finished
					_online_collapsed = true


func _on_offline_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_released():
				var tween := create_tween()
				if _offline_collapsed:
					tween.tween_property(%OfflineBox, 'custom_minimum_size:y', %Offline.size.y, 0.25)
					await tween.finished
					_offline_collapsed = false
				else:
					tween.tween_property(%OfflineBox, 'custom_minimum_size:y', 0, 0.25)
					await tween.finished
					_offline_collapsed = true
