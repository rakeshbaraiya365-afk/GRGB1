extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const TARGET_SCRIPT = preload("res://scripts/target_dummy.gd")

var player: GRBGPlayer
var health_label: Label
var ammo_label: Label
var status_label: Label
var fire_button: Button

func _ready() -> void:
	_build_world()
	_spawn_player()
	_spawn_targets()
	_build_hud()

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

	for i in range(12):
		var block := StaticBody3D.new()
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.4, 1.6, 2.4)
		mesh_instance.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.34, 0.37, 0.32)
		mesh_instance.material_override = material
		mesh_instance.position.y = 0.8
		block.add_child(mesh_instance)
		var collider := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = box.size
		collider.shape = box_shape
		collider.position.y = 0.8
		block.add_child(collider)
		block.position = Vector3(float((i % 4) * 8 - 12), 0, float(int(i / 4) * -8 - 8))
		add_child(block)

func _spawn_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	player.position = Vector3(0, 0.05, 7)
	player.fire_requested.connect(_on_player_fire)
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	add_child(player)

func _spawn_targets() -> void:
	for i in range(5):
		var target: GRBGTargetDummy = TARGET_SCRIPT.new()
		target.position = Vector3(float((i - 2) * 4), 0, -14.0 - float(i % 2) * 3.0)
		add_child(target)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var title := Label.new()
	title.text = "GRBG 1  |  TRAINING ARENA"
	title.position = Vector2(22, 18)
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	health_label = Label.new()
	health_label.position = Vector2(22, 58)
	health_label.add_theme_font_size_override("font_size", 20)
	root.add_child(health_label)

	ammo_label = Label.new()
	ammo_label.position = Vector2(22, 88)
	ammo_label.add_theme_font_size_override("font_size", 20)
	root.add_child(ammo_label)

	status_label = Label.new()
	status_label.text = "Offline training prototype"
	status_label.position = Vector2(22, 122)
	status_label.add_theme_font_size_override("font_size", 16)
	root.add_child(status_label)

	var controls := HBoxContainer.new()
	controls.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 16
	controls.offset_top = -84
	controls.offset_right = -16
	controls.offset_bottom = -16
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)

	_add_hold_button(controls, "◀", Vector2.LEFT)
	_add_hold_button(controls, "▲", Vector2.UP)
	_add_hold_button(controls, "▼", Vector2.DOWN)
	_add_hold_button(controls, "▶", Vector2.RIGHT)
	_add_action_button(controls, "JUMP", _on_jump_pressed)
	_add_action_button(controls, "FIRE", _on_fire_pressed)
	_add_action_button(controls, "RELOAD", _on_reload_pressed)
	_add_action_button(controls, "CAM", _on_camera_pressed)

func _add_hold_button(parent: Control, caption: String, direction: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(58, 58)
	button.button_down.connect(func(): player.set_move_vector(direction))
	button.button_up.connect(func(): player.set_move_vector(Vector2.ZERO))
	parent.add_child(button)

func _add_action_button(parent: Control, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(72, 58)
	button.pressed.connect(action)
	parent.add_child(button)

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
	if collider is GRBGTargetDummy:
		collider.apply_damage(34)
		status_label.text = "HIT! Target damaged."

func _on_health_changed(current: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH: %d / %d" % [current, maximum]
		if current <= 0:
			status_label.text = "YOU ARE DOWN - restart the scene to retry."

func _on_ammo_changed(magazine: int, reserve: int) -> void:
	if is_instance_valid(ammo_label):
		ammo_label.text = "AMMO: %d / %d" % [magazine, reserve]
