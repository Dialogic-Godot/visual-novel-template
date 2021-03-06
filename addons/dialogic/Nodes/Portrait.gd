extends Control

var z_index = 0

var character_data = {
	'name': 'Default',
	'image': "res://addons/dialogic/Example Assets/portraits/df-3.png",
	'color': Color(0.973511, 1, 0.152344),
	'file': '',
	'mirror_portraits': false
}

var single_portrait_mode = false
var dim_time = 0.5
var direction = 'left'
var debug = false
var fading_out = false

var current_state := {'character':'', 'portrait':'', 'position':'', 'mirrored':false}

signal animation_finished

func init(expression: String = '') -> void:
	set_portrait(expression)


func _ready():
	if debug:
		print('Character data loaded: ', character_data)
		print(rect_position, $TextureRect.rect_size)
	
	$AnimationTween.connect('finished_animation', self, 'emit_signal', ['animation_finished'])


func set_portrait(expression: String) -> void:
	if expression == "(Don't change)":
		return

	if expression == '':
		expression = 'Default'
	
	current_state['portrait'] = expression
	
	# Clearing old custom scenes
	for n in get_children():
		if 'DialogicCustomPortraitScene' in n.name:
			n.queue_free()
	
	var default
	for p in character_data['portraits']:
		if p['name'] == expression:
			if is_scene(p['path']):
				# Creating a scene portrait
				var custom_node = load(p['path'])
				var instance = custom_node.instance()
				instance.name = 'DialogicCustomPortraitScene'
				add_child(instance)
				
				$TextureRect.texture = ImageTexture.new()
				return
			else:
				# Creating an image portrait
				if ResourceLoader.exists(p['path']):
					$TextureRect.texture = load(p['path'])
				else:
					$TextureRect.texture = ImageTexture.new()
				return
		
		# Saving what the default is to fallback to it.
		if p['name'] == 'Default':
			default = p['path']
	
	
	# Everything failed, go with the default one
	if is_scene(default):
		push_warning('[Dialogic] Portrait missing: "' + expression + '". Maybe you deleted it? Update your timeline.')
		# Creating a scene portrait
		var custom_node = load(default)
		var instance = custom_node.instance()
		instance.name = 'DialogicCustomPortraitScene'
		add_child(instance)
		
		$TextureRect.texture = ImageTexture.new()
		return
	else:
		# Creating an image portrait
		if ResourceLoader.exists(default):
			$TextureRect.texture = load(default)
		else:
			$TextureRect.texture = ImageTexture.new()
		return



func set_mirror(value):
	current_state['mirrored'] = value
	if character_data["data"].has('mirror_portraits'):
		if character_data["data"]['mirror_portraits']:
			$TextureRect.flip_h = !value
		else:
			$TextureRect.flip_h = value
	else:
		$TextureRect.flip_h = value


func move_to_position(position_offset):
	var positions = {
		'left': Vector2(-400, 0),
		'right': Vector2(+400, 0),
		'center': Vector2(0, 0),
		'center_right': Vector2(200, 0),
		'center_left': Vector2(-200, 0)}
	
	direction = position_offset
	rect_position = positions[position_offset]
	
	# Setting the scale of the portrait
	var custom_scale = Vector2(1, 1)
	if character_data.has('data'):
		if character_data['data'].has('scale'):
			custom_scale = Vector2(
				float(character_data['data']['scale']) / 100,
				float(character_data['data']['scale']) / 100
			)
			rect_scale = custom_scale
		if character_data['data'].has('offset_x'):
			rect_position += Vector2(
				character_data['data']['offset_x'],
				character_data['data']['offset_y']
			)
	
	if $TextureRect.get('texture'):
		rect_position -= Vector2(
			$TextureRect.texture.get_width() * 0.5,
			$TextureRect.texture.get_height()
		) * custom_scale
	

func animate(animation_name = '[No Animation]', time = 1, loop = 1, delete = false ):
	if animation_name == "[No Animation]":
		return
	
	if '_in' in animation_name:
		$TextureRect.modulate = Color(1,1,1,0)
	
	$AnimationTween.loop = loop
	$AnimationTween.play($TextureRect, animation_name, time)
	
	if delete:
		$AnimationTween.connect("tween_all_completed", self, "queue_free")


func focus():
	if not fading_out:
		tween_modulate(modulate, Color(1,1,1, 1))


func focusout(dim_color = Color(0.5, 0.5, 0.5, 1.0)):
	if single_portrait_mode:
		dim_color.a = 0
	if not fading_out:
		tween_modulate(modulate, dim_color)


func tween_modulate(from_value, to_value):
	$ModulationTween.stop(self, 'modulation')
	$ModulationTween.interpolate_property(
		self, "modulate", from_value, to_value, dim_time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	$ModulationTween.start()
	return $ModulationTween


func is_scene(path) -> bool:
	if '.tscn' in path.to_lower():
		return true
	return false
