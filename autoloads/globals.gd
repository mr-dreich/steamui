extends Node


signal steam_initialized

const GameDataPath = 'user://app_data/'
const IconPath = 'user://app_icons/'
const HeaderPath = 'user://app_headers/'
const FriendsPath = 'user://friends_data/'

const GameListItemScene = preload('res://library/game_list_item.tscn')

const Friends = preload('res://friends/friends.tscn')
const FriendListItem = preload('res://friends/friend_list_item.tscn')

var _id: int = 0
var _username: String = "USER"
var _icon: ImageTexture = null

var _games: Dictionary = {}
var _friends: Dictionary = {}


func get_steamid() -> int:
	return _id


func get_username() -> String:
	return _username


func add_game(appid: String, dict: Dictionary) -> void:
	_games[appid] = dict.duplicate(true)


func get_games() -> Dictionary:
	return _games


func set_friends(dict: Dictionary) -> void:
	_friends = dict.duplicate(true)


func get_friends() -> Dictionary:
	return _friends


func get_icon() -> ImageTexture:
	return _icon


func initialize_steam() -> void:
	var initialize := Steam.steamInit(true, 480)
	#print("Did Steam initialize?: %s " % initialize)
	if initialize.status == 1:
		OS.set_environment('SteamAppId', str(480))
		OS.set_environment('SteamGameId', str(480))
		_id = Steam.getSteamID()
		_username = Steam.getPersonaName()
		Steam.getPlayerAvatar()
		await get_tree().process_frame
		steam_initialized.emit()


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(GameDataPath):
		DirAccess.make_dir_recursive_absolute(GameDataPath)
	if not DirAccess.dir_exists_absolute(IconPath):
		DirAccess.make_dir_recursive_absolute(IconPath)
	if not DirAccess.dir_exists_absolute(HeaderPath):
		DirAccess.make_dir_recursive_absolute(HeaderPath)
	if not DirAccess.dir_exists_absolute(FriendsPath):
		DirAccess.make_dir_recursive_absolute(FriendsPath)
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	initialize_steam()


func _on_loaded_avatar(_user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	var image := Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	_icon = ImageTexture.create_from_image(image)
