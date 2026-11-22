extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const MAP_SCRIPT = preload("res://scripts/island_map.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy_ai.gd")
const LOOK_SCRIPT = preload("res://scripts/look_area.gd")
const LOOT_SCRIPT = preload("res://scripts/loot_pickup.gd")

const ENEMY_SPAWNS := [
	Vector3(-10, 0.05, -20), Vector3(-5, 0.05, -25),
	Vector3(0, 0.05, -29), Vector3(5, 0.05, -25),
	Vector3(10, 0.05, -20), Vector3(0, 0.05, -38),
	Vector3(-18, 0.05, -31), Vector3(18, 0.05, -31)
]
const LOOT_DATA := [
	{"kind": "HEALTH", "amount": 35, "pos": Vector3(-8, 0.0, 3)},
	{"kind": "AMMO", "amount": 60, "pos": Vector3(8, 0.0, 1)},
	{"kind": "SMG", "amount": 80, "pos": Vector3(-16, 0.0, -14)},
	{"kind": "SHOTGUN", "amount": 24, "pos": Vector3(16, 0.0, -14)},
	{"kind": "AMMO", "amount": 45, "pos": Vector3(0, 0.0, -32)}
]

enum MatchState { LOBBY, COUNTDOWN, PLAYING, FINISHED }

var match_state := MatchState.LOBBY
var countdown_remaining := 0.0
var match_elapsed := 0.0
var kills := 0
var zone_radius := 48.0
var zone_elapsed := 0.0
var zone_damage_timer := 0.0
var player: GRBGPlayer
var enemies: Array[Node3D] = []
var pickups: Array[Node3D] = []
var zone_disc: MeshInstance3D

var health_label: Label
var ammo_label: Label
var status_label: Label
var match_label: Label
var kills_label: Label
var zone_label: Label
var weapon_label: Label
var countdown_label: Label
var start_button: Button
var lobby_overlay: ColorRect
var controls_grid: GridContainer
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label

func _ready() -> void:
	_build_world()
	_spawn_player()
	_spawn_pickups()
	_build_hud()

func _process(delta: float) -> void:
	if match_state == MatchState.COUNTDOWN:
		countdown_remaining -= delta
		countdown_label.text = "MATCH STARTS IN %d" % maxi(1, ceili(countdown_remaining))
		if countdown_remaining <= 0.0:
			_begin_match()
	elif match_state == MatchState.PLAYING:
		match_elapsed += delta
		zone_elapsed += delta
		match_label.text = "MATCH TIME: %s" % _format_time(match_elapsed)
		if zone_elapsed >= 8.0:
			zone_elapsed = 0.0
			zone_radius = maxf(14.0, zone_radius - 1.4)
			zone_disc.scale = Vector3(zone_radius, 1.0, zone_radius)
		zone_label.text = "SAFE ZONE: %.0f m" % zone_radius
		zone_damage_timer += delta
		if zone_damage_timer >= 1.0:
			zone_damage_timer = 0.0
			if Vector2(player.global_position.x, player.global_position.z).length() > zone_radius:
				player.take_damage(5)
				status_label.text = "WARNING: OUTSIDE SAFE ZONE!"
		_check_pickups()
		_update_enemy_count()

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.035, 0.12, 0.19)
	sky_material.sky_horizon_color = Color(0.78, 0.52, 0.31)
	env.sky.sky_material = sky_material
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.35
	add_child(sun)

	var island := MAP_SCRIPT.new()
	island.name = "SaurashtraBattleIsland"
	add_child(island)

	zone_disc = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.035
	zone_disc.mesh = disc
	var zone_material := StandardMaterial3D.new()
	zone_material.albedo_color = Color(0.12, 0.48, 0.95, 0.12)
	zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	zone_disc.material_override = zone_material
	zone_disc.position.y = 0.035
	zone_disc.scale = Vector3(zone_radius, 1.0, zone_radius)
	add_child(zone_disc)

func _add_building(title: String, position: Vector3, size: Vector3, color: Color) -> void:
	var building := StaticBody3D.new()
	building.position = position
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	mesh_instance.position.y = size.y / 2.0
	building.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y / 2.0
	building.add_child(collision)
	var sign := Label3D.new()
	sign.text = title
	sign.position = Vector3(0, size.y + 1.0, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 34
	building.add_child(sign)
	add_child(building)

func _add_cover(position: Vector3) -> void:
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
	player.weapon_changed.connect(_on_weapon_changed)
	add_child(player)

func _spawn_pickups() -> void:
	for data in LOOT_DATA:
		var pickup = LOOT_SCRIPT.new()
		pickup.kind = data.kind
		pickup.amount = data.amount
		pickup.position = data.pos
		add_child(pickup)
		pickups.append(pickup)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "GRBG 1  |  SAURASHTRA BATTLE ISLAND"
	title.position = Vector2(18, 12)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	health_label = _add_label(root, Vector2(18, 46), 18)
	ammo_label = _add_label(root, Vector2(18, 72), 18)
	weapon_label = _add_label(root, Vector2(18, 98), 16)
	status_label = _add_label(root, Vector2(18, 124), 16)
	match_label = _add_label(root, Vector2(18, 150), 16)
	kills_label = _add_label(root, Vector2(18, 176), 16)
	zone_label = _add_label(root, Vector2(18, 202), 16)
	status_label.text = "Press START to enter the island."

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
	_add_action_button("WEAPON", _on_weapon_pressed)
	_add_action_button("CAM", _on_camera_pressed)
	_add_action_button("SPRINT", _on_sprint_pressed)
	controls_grid.visible = false

	var look_area: GRBGLookArea = LOOK_SCRIPT.new()
	look_area.player = player
	look_area.anchor_left = 0.48
	look_area.anchor_right = 1.0
	look_area.anchor_top = 0.0
	look_area.anchor_bottom = 0.78
	look_area.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(look_area)
	look_area.visible = false
	look_area.name = "TouchLookArea"
	look_area.set_meta("gameplay_look_area", true)
	look_area.z_index = -1
	_build_lobby_overlay(root)
	_build_result_overlay(root)
	_on_health_changed(player.health, player.max_health)
	_on_ammo_changed(player.magazine, player.reserve_ammo)
	_on_weapon_changed(player.weapon_label)

func _add_label(parent: Control, position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _build_lobby_overlay(root: Control) -> void:
	lobby_overlay = ColorRect.new()
	lobby_overlay.color = Color(0.015, 0.025, 0.04, 0.92)
	lobby_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(lobby_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 290)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var logo := Label.new()
	logo.text = "GRBG 1"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 44)
	column.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "BATTLE ROYALE  |  OFFLINE TEST"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)
	countdown_label = Label.new()
	countdown_label.text = "READY TO DROP"
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 23)
	column.add_child(countdown_label)
	start_button = Button.new()
	start_button.text = "START"
	start_button.custom_minimum_size = Vector2(260, 64)
	start_button.add_theme_font_size_override("font_size", 25)
	start_button.pressed.connect(_on_start_pressed)
	column.add_child(start_button)
	var note := Label.new()
	note.text = "Matchmaking demo: 5 seconds\n8 AI enemies • Saurashtra Island"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)

func _build_result_overlay(root: Control) -> void:
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.01, 0.02, 0.035, 0.94)
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.visible = false
	root.add_child(result_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 230)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	result_title = Label.new()
	result_title.text = "MATCH OVER"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 30)
	column.add_child(result_title)
	result_detail = Label.new()
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(result_detail)
	var restart := Button.new()
	restart.text = "PLAY AGAIN"
	restart.custom_minimum_size = Vector2(250, 58)
	restart.pressed.connect(func(): get_tree().reload_current_scene())
	column.add_child(restart)

func _on_start_pressed() -> void:
	if match_state != MatchState.LOBBY:
		return
	match_state = MatchState.COUNTDOWN
	countdown_remaining = 5.0
	start_button.disabled = true
	start_button.text = "SEARCHING..."
	countdown_label.text = "MATCH STARTS IN 5"
	status_label.text = "MATCHMAKING DEMO: searching for a test match..."

func _begin_match() -> void:
	match_state = MatchState.PLAYING
	lobby_overlay.visible = false
	controls_grid.visible = true
	get_node("CanvasLayer/Control/TouchLookArea").visible = true
	status_label.text = "DROP IN! Collect loot and eliminate all enemies."
	match_elapsed = 0.0
	kills = 0
	zone_radius = 48.0
	zone_disc.scale = Vector3(zone_radius, 1.0, zone_radius)
	player.begin_parachute_drop()
	for i in range(ENEMY_SPAWNS.size()):
		var enemy = ENEMY_SCRIPT.new()
		enemy.name = "DemoEnemy_%02d" % (i + 1)
		enemy.target_player = player
		enemy.position = ENEMY_SPAWNS[i]
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)
		enemies.append(enemy)
	_update_enemy_count()

func _add_hold_button(caption: String, direction: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(46, 46)
	button.button_down.connect(func(): player.set_move_vector(direction))
	button.button_up.connect(func(): player.set_move_vector(Vector2.ZERO))
	controls_grid.add_child(button)

func _add_action_button(caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(62, 46)
	button.pressed.connect(action)
	controls_grid.add_child(button)

func _on_jump_pressed() -> void:
	player.jump()

func _on_fire_pressed() -> void:
	player.shoot()

func _on_reload_pressed() -> void:
	player.reload_weapon()

func _on_weapon_pressed() -> void:
	player.switch_weapon()

func _on_camera_pressed() -> void:
	player.toggle_camera()

func _on_sprint_pressed() -> void:
	player.set_sprint(not player.sprint_held)
	status_label.text = "SPRINT: ON" if player.sprint_held else "SPRINT: OFF"

func _on_player_fire(origin: Vector3, direction: Vector3, damage: int) -> void:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 110.0)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_method("apply_damage"):
		collider.apply_damage(damage)
		status_label.text = "HIT! Enemy took %d damage." % damage

func _on_enemy_defeated(enemy: Node3D) -> void:
	kills += 1
	status_label.text = "ENEMY ELIMINATED!"
	_update_enemy_count()
	if kills >= ENEMY_SPAWNS.size():
		_finish_match(true)

func _update_enemy_count() -> void:
	var remaining := 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			remaining += 1
	kills_label.text = "KILLS: %d  |  ENEMIES: %d" % [kills, remaining]

func _check_pickups() -> void:
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			pickups.erase(pickup)
			continue
		if player.global_position.distance_to(pickup.global_position) < 2.1:
			player.collect_pickup(pickup.kind, pickup.amount)
			status_label.text = "PICKED UP: %s" % pickup.display_name
			pickups.erase(pickup)
			pickup.queue_free()

func _on_health_changed(current: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH: %d / %d" % [current, maximum]
	if current <= 0 and match_state == MatchState.PLAYING:
		_finish_match(false)

func _on_ammo_changed(magazine: int, reserve: int) -> void:
	if is_instance_valid(ammo_label):
		ammo_label.text = "AMMO: %d / %d" % [magazine, reserve]

func _on_weapon_changed(name: String) -> void:
	if is_instance_valid(weapon_label):
		weapon_label.text = "WEAPON: %s" % name

func _finish_match(won: bool) -> void:
	if match_state == MatchState.FINISHED:
		return
	match_state = MatchState.FINISHED
	player.set_physics_process(false)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	result_title.text = "BOOYAH! VICTORY" if won else "YOU ARE ELIMINATED"
	result_detail.text = "KILLS: %d / %d\nSURVIVAL TIME: %s" % [kills, ENEMY_SPAWNS.size(), _format_time(match_elapsed)]
	result_overlay.visible = true
	status_label.text = "MATCH FINISHED"
