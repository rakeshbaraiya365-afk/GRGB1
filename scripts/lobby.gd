extends Node3D

var showcase: Node3D
var status_label: Label
var section_overlay: Control

const RIG_SCRIPT = preload("res://scripts/soldier_rig.gd")
const ACCENT := Color(0.95, 0.48, 0.16)
const PANEL := Color(0.035, 0.055, 0.075, 0.94)
const MUTED := Color(0.62, 0.70, 0.76)

func _ready() -> void:
	_build_stage()
	_build_interface()

func _process(delta: float) -> void:
	if is_instance_valid(showcase):
		showcase.rotate_y(delta * 0.22)

func _build_stage() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.025, 0.09, 0.16)
	sky_mat.sky_horizon_color = Color(0.95, 0.43, 0.20)
	sky_mat.ground_bottom_color = Color(0.035, 0.07, 0.075)
	sky_mat.ground_horizon_color = Color(0.25, 0.28, 0.23)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -28, 0)
	sun.light_energy = 1.45
	add_child(sun)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.1, 8.5)
	camera.fov = 42.0
	add_child(camera)
	camera.look_at(Vector3(0, 1.25, 0), Vector3.UP)
	camera.current = true

	var floor_mesh := MeshInstance3D.new()
	var floor := PlaneMesh.new()
	floor.size = Vector2(35, 35)
	floor_mesh.mesh = floor
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.055, 0.12, 0.13)
	floor_mat.roughness = 0.82
	floor_mesh.material_override = floor_mat
	floor_mesh.position.y = -0.04
	add_child(floor_mesh)

	var platform := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.65
	cylinder.bottom_radius = 1.9
	cylinder.height = 0.22
	platform.mesh = cylinder
	var platform_mat := StandardMaterial3D.new()
	platform_mat.albedo_color = Color(0.12, 0.17, 0.18)
	platform_mat.metallic = 0.45
	platform_mat.roughness = 0.38
	platform.material_override = platform_mat
	platform.position = Vector3(0, 0.08, 0)
	add_child(platform)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 1.78
	ring_mesh.outer_radius = 1.84
	ring.mesh = ring_mesh
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = ACCENT
	ring_mat.emission_enabled = true
	ring_mat.emission = ACCENT
	ring_mat.emission_energy_multiplier = 1.4
	ring.material_override = ring_mat
	ring.position.y = 0.20
	add_child(ring)

	# Reuse the articulated soldier model in the lobby preview.
	showcase = RIG_SCRIPT.new()
	showcase.name = "OperatorShowcase"
	showcase.position.y = 0.22
	showcase.scale = Vector3(1.12, 1.12, 1.12)
	add_child(showcase)

func _add_capsule(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mesh.material_override = mat
	parent.add_child(mesh)

func _add_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	mesh.mesh = shape
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)

func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.12
	mesh.material_override = mat
	parent.add_child(mesh)

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.012, 0.025, 0.038, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 76
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.028, 0.04, 0.91), 0))
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 22)
	top_row.add_theme_constant_override("margin_left", 28)
	top_row.add_theme_constant_override("margin_right", 28)
	top_row.add_theme_constant_override("margin_top", 12)
	top_row.add_theme_constant_override("margin_bottom", 12)
	top.add_child(top_row)
	var brand := Label.new()
	brand.text = "GRBG 1"
	brand.add_theme_font_size_override("font_size", 30)
	brand.add_theme_color_override("font_color", Color.WHITE)
	top_row.add_child(brand)
	var edition := Label.new()
	edition.text = "BATTLE ROYALE"
	edition.add_theme_font_size_override("font_size", 14)
	edition.add_theme_color_override("font_color", ACCENT)
	edition.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(edition)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var online := Label.new()
	online.text = "●  OFFLINE TEST LOBBY"
	online.add_theme_font_size_override("font_size", 13)
	online.add_theme_color_override("font_color", Color(0.95, 0.72, 0.40))
	online.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(online)

	var left := VBoxContainer.new()
	left.position = Vector2(24, 112)
	left.custom_minimum_size = Vector2(218, 0)
	left.add_theme_constant_override("separation", 10)
	root.add_child(left)
	var section := Label.new()
	section.text = "MAIN MENU"
	section.add_theme_font_size_override("font_size", 13)
	section.add_theme_color_override("font_color", MUTED)
	left.add_child(section)
	for item in ["LOBBY", "CHARACTER", "WEAPONS", "VAULT"]:
		var nav := Button.new()
		nav.text = "   " + item
		nav.custom_minimum_size = Vector2(205, 48)
		nav.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nav.add_theme_font_size_override("font_size", 16)
		nav.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.045, 0.06, 0.84), 7))
		nav.add_theme_stylebox_override("hover", _panel_style(Color(0.15, 0.10, 0.075, 0.95), 7))
		nav.add_theme_color_override("font_color", Color(0.87, 0.91, 0.92))
		left.add_child(nav)
		nav.pressed.connect(_open_section.bind(item))

	var right := PanelContainer.new()
	right.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right.anchor_top = 0.20
	right.anchor_bottom = 0.70
	right.offset_left = -270
	right.offset_right = -22
	right.add_theme_stylebox_override("panel", _panel_style(PANEL, 12))
	root.add_child(right)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 10)
	details.add_theme_constant_override("margin_left", 18)
	details.add_theme_constant_override("margin_right", 18)
	details.add_theme_constant_override("margin_top", 16)
	details.add_theme_constant_override("margin_bottom", 16)
	right.add_child(details)
	var mode := Label.new()
	mode.text = "SELECT MODE"
	mode.add_theme_font_size_override("font_size", 13)
	mode.add_theme_color_override("font_color", MUTED)
	details.add_child(mode)
	var battle := Label.new()
	battle.text = "BATTLE ROYALE"
	battle.add_theme_font_size_override("font_size", 21)
	battle.add_theme_color_override("font_color", Color.WHITE)
	details.add_child(battle)
	var map := Label.new()
	map.text = "SAURASHTRA ISLAND"
	map.add_theme_font_size_override("font_size", 14)
	map.add_theme_color_override("font_color", ACCENT)
	details.add_child(map)
	var line := HSeparator.new()
	details.add_child(line)
	var info := Label.new()
	info.text = "8 AI BOTS\nSOLO • TRAINING MATCH\n5 SECOND LOCAL QUEUE"
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(info)

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -112
	bottom.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.028, 0.04, 0.91), 0))
	root.add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 16)
	bottom_row.add_theme_constant_override("margin_left", 28)
	bottom_row.add_theme_constant_override("margin_right", 28)
	bottom_row.add_theme_constant_override("margin_top", 14)
	bottom_row.add_theme_constant_override("margin_bottom", 14)
	bottom.add_child(bottom_row)
	var player_name := Label.new()
	player_name.text = "PLAYER 01   |   ROOKIE"
	player_name.add_theme_font_size_override("font_size", 15)
	player_name.add_theme_color_override("font_color", Color.WHITE)
	player_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom_row.add_child(player_name)
	var status_spacer := Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(status_spacer)
	status_label = Label.new()
	status_label.text = "READY TO DEPLOY"
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", MUTED)
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom_row.add_child(status_label)
	var start := Button.new()
	start.text = "  START MATCH  "
	start.custom_minimum_size = Vector2(220, 58)
	start.add_theme_font_size_override("font_size", 19)
	start.add_theme_color_override("font_color", Color.WHITE)
	start.add_theme_stylebox_override("normal", _panel_style(ACCENT, 9))
	start.add_theme_stylebox_override("hover", _panel_style(Color(1.0, 0.60, 0.25), 9))
	start.pressed.connect(_start_match)
	bottom_row.add_child(start)

	var disclaimer := Label.new()
	disclaimer.text = "CHARACTER DISPLAY IS A TEMPORARY PLACEHOLDER • ONLINE MULTIPLAYER NOT YET ENABLED"
	disclaimer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	disclaimer.position = Vector2(24, -132)
	disclaimer.add_theme_font_size_override("font_size", 10)
	disclaimer.add_theme_color_override("font_color", Color(0.72, 0.77, 0.78))
	root.add_child(disclaimer)

func _open_section(section: String) -> void:
	if is_instance_valid(section_overlay):
		section_overlay.queue_free()
	section_overlay = Control.new()
	section_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	section_overlay.z_index = 20
	add_child(section_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.012, 0.022, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	section_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	section_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 390)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, 14))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = section
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", ACCENT)
	column.add_child(heading)
	var detail := Label.new()
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", MUTED)
	column.add_child(detail)

	match section:
		"CHARACTER":
			detail.text = "Choose your operator appearance. Your choice is saved on this device."
			_add_choice_button(column, "RECON  •  FIELD GREEN", _select_character.bind("RECON", Color(0.20, 0.29, 0.19)))
			_add_choice_button(column, "DESERT  •  SAND", _select_character.bind("DESERT", Color(0.55, 0.40, 0.23)))
			_add_choice_button(column, "SHADOW  •  DARK", _select_character.bind("SHADOW", Color(0.12, 0.16, 0.19)))
		"WEAPONS":
			detail.text = "Choose your starting weapon for the next offline training match."
			_add_choice_button(column, "ASSAULT RIFLE  •  BALANCED", _select_weapon.bind(0))
			_add_choice_button(column, "SMG  •  FAST FIRE", _select_weapon.bind(1))
			_add_choice_button(column, "SHOTGUN  •  CLOSE RANGE", _select_weapon.bind(2))
		"VAULT":
			var cfg := ConfigFile.new()
			cfg.load("user://grbg_profile.cfg")
			var operator_name: String = str(cfg.get_value("profile", "character_name", "RECON"))
			var weapon_index: int = int(cfg.get_value("profile", "weapon_index", 0))
			var weapon_names := ["ASSAULT RIFLE", "SMG", "SHOTGUN"]
			detail.text = "SAVED LOADOUT\nOPERATOR: %s\nPRIMARY: %s\n\nYour selected gear will be used when the match starts." % [operator_name, weapon_names[clampi(weapon_index, 0, 2)]]
			_add_choice_button(column, "SAVE LOADOUT", _save_profile)
		"LOBBY":
			detail.text = "SAURASHTRA ISLAND\n8 AI opponents • Solo training\nSelect your operator and starting weapon before deployment."
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func():
		if is_instance_valid(section_overlay):
			section_overlay.queue_free()
	)
	column.add_child(close)

func _add_choice_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
	var choice := Button.new()
	choice.text = caption
	choice.custom_minimum_size = Vector2(0, 48)
	choice.add_theme_font_size_override("font_size", 15)
	choice.add_theme_stylebox_override("normal", _panel_style(Color(0.08, 0.12, 0.14), 7))
	choice.add_theme_stylebox_override("hover", _panel_style(Color(0.18, 0.13, 0.09), 7))
	choice.pressed.connect(action)
	parent.add_child(choice)

func _select_character(character_name: String, color: Color) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://grbg_profile.cfg")
	cfg.set_value("profile", "character_name", character_name)
	cfg.set_value("profile", "character_color", color)
	cfg.save("user://grbg_profile.cfg")
	_set_status("OPERATOR SAVED: " + character_name)
	if is_instance_valid(section_overlay):
		section_overlay.queue_free()

func _select_weapon(index: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://grbg_profile.cfg")
	cfg.set_value("profile", "weapon_index", clampi(index, 0, 2))
	cfg.save("user://grbg_profile.cfg")
	var names := ["ASSAULT RIFLE", "SMG", "SHOTGUN"]
	_set_status("STARTING WEAPON SAVED: " + names[clampi(index, 0, 2)])
	if is_instance_valid(section_overlay):
		section_overlay.queue_free()

func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://grbg_profile.cfg")
	cfg.save("user://grbg_profile.cfg")
	_set_status("LOADOUT SAVED ON THIS DEVICE")
	if is_instance_valid(section_overlay):
		section_overlay.queue_free()

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.42, 0.52, 0.56, 0.30)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message

func _start_match() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
