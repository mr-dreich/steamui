extends GridContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resized.connect(_on_resized)
	set('theme_override_constants/h_separation', 2)
	set('theme_override_constants/v_separation', 2)


func _on_resized() -> void:
	if get_child_count() > 0:
		var child_size: int = get_child(0).size.x
		var old_amount: int = columns
		var new_amount: int = floor(size.x / (child_size + get('theme_override_constants/h_separation')))
		if new_amount != old_amount:
			if new_amount > 0:
				columns = int(new_amount)
