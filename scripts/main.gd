extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy_ai.gd")

const ENEMY_SPAWNS := [
	Vector3(-10, 0.05, -20),
	Vector3(-5, 0.05, -25),
	Vector3(0, 0.05, -29),
	Vector3(5, 0.05, -25),
	Vector3(10, 0.05, -20),
	Vector3(0, 0.05, -38)
]

enum MatchState { LOBBY, COUNTDOWN, PLAYING, FINISHED }

var match_state := MatchState.LOBBY
var countdown_remaining := 0.0
var match_elapsed := 0.0
var kills := 0
var player: GRBGPlayer
var enemies: Array[Node3D] = []

var health_label: Label
var ammo_label: Label
var status_label: Label
var match_label: Label
var kills_label: Label
var countdown_label: Label
var start_button: Button
var lobby_overlay: ColorRect
var controls_grid: GridContainer

func _ready() -> void:
	_build_world()
	_spawn_player()
	_build_hud()

func _process(delta: float) -> void:
	if match_state == MatchState.COUNTDOWN:
		countdown_remaining -= delta
		countdown_label.text = "MATCH STARTS IN %d" % maxi(1, ceili(countdown_remaining))
		if countdown_remaining <= 0.0:
			_begin_match()
	elif match_state == MatchState.PLAYING:
		match_elapsed += delta
		match_label.text = "MATCH TIME: %s" % _format_time(match_elapsed)
		_update_enemy_count()

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	add_child(sun)

	var ground := StaticBody3D.new()
	ground.name = "ArenaGround"
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 100)
	ground_mesh.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.22, 0.31, 0.22)
	ground_material.roughness = 1.0
	ground_mesh.material_override = ground_material
	ground.add_child(ground_mesh)
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(100, 0.5, 100)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.25
	ground.add_child(ground_collision)
	add_child(ground)

	# Scattered low cover, leaving open lanes for the demo enemy AI.
	var cover_positions := [
		Vector3(-13, 0, -9), Vector3(13, 0, -9),
		Vector3(-13, 0, -23), Vector3(13, 0, -23),
		Vector3(-6, 0, -34), Vector3(7, 0, -35),
		Vector3(-19, 0, -17), Vector3(19, 0, -17)
	]
	for position in cover_positions:
		var block := StaticBody3D.new()
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.8, 1.5, 2.8)
		mesh_instance.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.34, 0.37, 0.32)
		mesh_instance.material_override = material
		mesh_instance.position.y = 0.75
		block.add_child(mesh_instance)
		var collider := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = box.size
		collider.shape = box_shape
		collider.position.y = 0.75
		block.add_child(collider)
		block.position = position
		add_child(block)

func _spawn_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector3(0, 0.05, 7)
	player.fire_requested.connect(_on_player_fire)
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "GRBG 1  |  BATTLE ROYALE DEMO"
	title.position = Vector2(18, 14)
	title.add_theme_font_size_override("font_size", 23)
	root.add_child(title)

	health_label = Label.new()
	health_label.position = Vector2(18, 50)
	health_label.add_theme_font_size_override("font_size", 19)
	root.add_child(health_label)

	ammo_label = Label.new()
	ammo_label.position = Vector2(18, 78)
	ammo_label.add_theme_font_size_override("font_size", 19)
	root.add_child(ammo_label)

	status_label = Label.new()
	status_label.text = "Press START to find a demo match."
	status_label.position = Vector2(18, 108)
	status_label.add_theme_font_size_override("font_size", 16)
	root.add_child(status_label)

	match_label = Label.new()
	match_label.text = "MATCH TIME: 00:00"
	match_label.position = Vector2(18, 138)
	match_label.add_theme_font_size_override("font_size", 16)
	root.add_child(match_label)

	kills_label = Label.new()
	kills_label.text = "KILLS: 0  |  ENEMIES: 0"
	kills_label.position = Vector2(18, 164)
	kills_label.add_theme_font_size_override("font_size", 16)
	root.add_child(kills_label)

	controls_grid = GridContainer.new()
	controls_grid.columns = 4
	controls_grid.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_grid.offset_left = 12
	controls_grid.offset_top = -112
	controls_grid.offset_right = -12
	controls_grid.offset_bottom = -12
	controls_grid.add_theme_constant_override("h_separation", 7)
	controls_grid.add_theme_constant_override("v_separation", 6)
	root.add_child(controls_grid)
	_add_hold_button("◀", Vector2.LEFT)
	_add_hold_button("▲", Vector2.UP)
	_add_hold_button("▼", Vector2.DOWN)
	_add_hold_button("▶", Vector2.RIGHT)
	_add_action_button("JUMP", _on_jump_pressed)
	_add_action_button("FIRE", _on_fire_pressed)
	_add_action_button("RELOAD", _on_reload_pressed)
	_add_action_button("CAM", _on_camera_pressed)
	controls_grid.visible = false

	_build_lobby_overlay(root)
	_on_health_changed(player.health, player.max_health)
	_on_ammo_changed(player.magazine, player.reserve_ammo)

func _build_lobby_overlay(root: Control) -> void:
	lobby_overlay = ColorRect.new()
	lobby_overlay.color = Color(0.015, 0.025, 0.04, 0.90)
	lobby_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(lobby_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(310, 250)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var logo := Label.new()
	logo.text = "GRBG 1"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 42)
	column.add_child(logo)

	var subtitle := Label.new()
	subtitle.text = "BATTLE ROYALE  |  TRAINING MATCH"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	column.add_child(subtitle)

	countdown_label = Label.new()
	countdown_label.text = "READY TO PLAY"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 23)
	column.add_child(countdown_label)

	start_button = Button.new()
	start_button.text = "START"
	start_button.custom_minimum_size = Vector2(250, 64)
	start_button.add_theme_font_size_override("font_size", 25)
	start_button.pressed.connect(_on_start_pressed)
	column.add_child(start_button)

	var note := Label.new()
	note.text = "Demo matchmaking: match begins in 5 seconds"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)

func _on_start_pressed() -> void:
	if match_state != MatchState.LOBBY:
		return
	match_state = MatchState.COUNTDOWN
	countdown_remaining = 5.0
	start_button.disabled = true
	start_button.text = "SEARCHING..."
	countdown_label.text = "MATCH STARTS IN 5"
	status_label.text = "MATCHMAKING DEMO: finding players..."

func _begin_match() -> void:
	match_state = MatchState.PLAYING
	lobby_overlay.visible = false
	controls_grid.visible = true
	countdown_label.text = "MATCH STARTED"
	status_label.text = "6 AI enemies entered the training match."
	match_elapsed = 0.0
	kills = 0
	for i in range(ENEMY_SPAWNS.size()):
		var enemy: Node3D = ENEMY_SCRIPT.new()
		enemy.name = "DemoEnemy_%02d" % (i + 1)
		enemy.set("target_player", player)
		enemy.position = ENEMY_SPAWNS[i]
		enemy.connect("defeated", _on_enemy_defeated)
		add_child(enemy)
		enemies.append(enemy)
	_update_enemy_count()

func _add_hold_button(caption: String, direction: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(48, 48)
	button.button_down.connect(func(): player.set_move_vector(direction))
	button.button_up.connect(func(): player.set_move_vector(Vector2.ZERO))
	controls_grid.add_child(button)

func _add_action_button(caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(58, 48)
	button.pressed.connect(action)
	controls_grid.add_child(button)

func _on_jump_pressed() -> void:
	player.jump()

func _on_fire_pressed() -> void:
	player.shoot()

func _on_reload_pressed() -> void:
	player.reload_weapon()

func _on_camera_pressed() -> void:
	player.toggle_camera()

func _on_player_fire(origin: Vector3, direction: Vector3) -> void:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_method("apply_damage"):
		collider.apply_damage(34)
		status_label.text = "HIT! Enemy took damage."

func _on_enemy_defeated(enemy: Node3D) -> void:
	kills += 1
	status_label.text = "ENEMY ELIMINATED!"
	_update_enemy_count()
	if kills >= ENEMY_SPAWNS.size():
		match_state = MatchState.FINISHED
		status_label.text = "BOOYAH! DEMO MATCH WON!"

func _update_enemy_count() -> void:
	var remaining := 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			remaining += 1
	kills_label.text = "KILLS: %d  |  ENEMIES: %d" % [kills, remaining]

func _on_health_changed(current: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH: %d / %d" % [current, maximum]
		if current <= 0:
			status_label.text = "YOU ARE DOWN - demo match over."

func _on_ammo_changed(magazine: int, reserve: int) -> void:
	if is_instance_valid(ammo_label):
		ammo_label.text = "AMMO: %d / %d" % [magazine, reserve]
