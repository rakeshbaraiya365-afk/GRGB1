extends CharacterBody3D
class_name GRBGPlayer

signal health_changed(current: int, maximum: int)
signal ammo_changed(magazine: int, reserve: int)
signal fire_requested(origin: Vector3, direction: Vector3, damage: int)
signal weapon_changed(weapon_name: String)

const WALK_SPEED := 6.0
const SPRINT_SPEED := 9.0
const JUMP_VELOCITY := 5.5
const GRAVITY := 18.0
const RIG_SCRIPT = preload("res://scripts/soldier_rig.gd")
const MAGAZINE_SIZE := 30
const RELOAD_SECONDS := 1.25
const WEAPONS := [
	{"name": "ASSAULT RIFLE", "damage": 34, "interval": 0.18, "mag": 30, "reserve": 120},
	{"name": "SMG", "damage": 19, "interval": 0.09, "mag": 40, "reserve": 160},
	{"name": "SHOTGUN", "damage": 78, "interval": 0.85, "mag": 8, "reserve": 40}
]

var max_health := 100
var health := 100
var magazine := 30
var reserve_ammo := 120
var fire_cooldown := 0.0
var reload_timer := 0.0
var move_vector := Vector2.ZERO
var sprint_held := false
var camera_is_first_person := false
var current_weapon_index := 0
var is_dropping := false
var parachute_visual: Node3D

var camera: Camera3D
var camera_pivot: Node3D
var body_mesh: Node3D
var soldier_rig: GRBGSoldierRig
var weapon_label := "ASSAULT RIFLE"

func _ready() -> void:
	_build_collision()
	_build_visual()
	var loadout := ConfigFile.new()
	if loadout.load("user://grbg_profile.cfg") == OK:
		select_weapon(int(loadout.get_value("profile", "weapon_index", 0)))
	_build_camera()
	health_changed.emit(health, max_health)
	ammo_changed.emit(magazine, reserve_ammo)
	weapon_changed.emit(weapon_label)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

func _build_visual() -> void:
	var config := ConfigFile.new()
	var skin := Color(0.20, 0.29, 0.19)
	if config.load("user://grbg_profile.cfg") == OK:
		skin = config.get_value("profile", "character_color", skin)
	soldier_rig = RIG_SCRIPT.new()
	soldier_rig.name = "AnimatedSoldier"
	soldier_rig.set_uniform_tint(skin)
	body_mesh = soldier_rig
	add_child(soldier_rig)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera_pivot.add_child(camera)
	camera.current = true
	set_camera_mode(false)

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_vector.length() > 0.05:
		input_vector = move_vector
	var yaw_basis := Basis(Vector3.UP, camera_pivot.rotation.y)
	var direction := yaw_basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	direction = direction.normalized()

	if not is_on_floor():
		var gravity_strength := 2.5 if is_dropping else GRAVITY
		velocity.y -= gravity_strength * delta
		if is_dropping:
			velocity.y = maxf(velocity.y, -4.0)
	elif is_dropping:
		is_dropping = false
		if is_instance_valid(parachute_visual):
			parachute_visual.queue_free()
		velocity.y = 0.0
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var speed := SPRINT_SPEED if (sprint_held or Input.is_action_pressed("sprint")) else WALK_SPEED
	if direction.length() > 0.05:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if not camera_is_first_person:
			rotation.y = atan2(-direction.x, -direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 5.0 * delta)

	move_and_slide()
	if is_instance_valid(soldier_rig):
		soldier_rig.set_motion(Vector2(velocity.x, velocity.z).length() / SPRINT_SPEED, false, false, not is_on_floor())

	if Input.is_action_just_pressed("fire"):
		shoot()
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	if Input.is_action_just_pressed("toggle_camera"):
		toggle_camera()

func set_move_vector(value: Vector2) -> void:
	move_vector = value.limit_length(1.0)

func set_sprint(value: bool) -> void:
	sprint_held = value

func jump() -> void:
	if is_on_floor() and health > 0:
		velocity.y = JUMP_VELOCITY

func rotate_view(relative_motion: Vector2) -> void:
	camera_pivot.rotation.y -= relative_motion.x * 0.004
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - relative_motion.y * 0.004, deg_to_rad(-55), deg_to_rad(35))
	if not camera_is_first_person:
		rotation.y = camera_pivot.rotation.y

func shoot() -> void:
	if health <= 0 or fire_cooldown > 0.0 or reload_timer > 0.0 or is_dropping:
		return
	if magazine <= 0:
		reload_weapon()
		return
	var weapon: Dictionary = WEAPONS[current_weapon_index]
	magazine -= 1
	fire_cooldown = float(weapon.interval)
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	fire_requested.emit(origin, direction, int(weapon.damage))
	if is_instance_valid(soldier_rig):
		soldier_rig.set_motion(Vector2(velocity.x, velocity.z).length() / SPRINT_SPEED, false, true, not is_on_floor())
	ammo_changed.emit(magazine, reserve_ammo)

func reload_weapon() -> void:
	if reload_timer > 0.0 or magazine >= int(WEAPONS[current_weapon_index].mag) or reserve_ammo <= 0:
		return
	reload_timer = RELOAD_SECONDS

func _finish_reload() -> void:
	var needed := int(WEAPONS[current_weapon_index].mag) - magazine
	var loaded := mini(needed, reserve_ammo)
	magazine += loaded
	reserve_ammo -= loaded
	ammo_changed.emit(magazine, reserve_ammo)

func switch_weapon() -> void:
	select_weapon((current_weapon_index + 1) % WEAPONS.size())

func select_weapon(index: int) -> void:
	current_weapon_index = clampi(index, 0, WEAPONS.size() - 1)
	var weapon: Dictionary = WEAPONS[current_weapon_index]
	weapon_label = str(weapon.name)
	magazine = int(weapon.mag)
	reserve_ammo = int(weapon.reserve)
	reload_timer = 0.0
	weapon_changed.emit(weapon_label)
	ammo_changed.emit(magazine, reserve_ammo)
	if is_instance_valid(soldier_rig):
		soldier_rig.set_weapon(current_weapon_index)

func collect_pickup(kind: String, amount: int) -> void:
	match kind:
		"HEALTH":
			health = mini(max_health, health + amount)
			health_changed.emit(health, max_health)
		"AMMO":
			reserve_ammo += amount
			ammo_changed.emit(magazine, reserve_ammo)
		"SMG":
			current_weapon_index = 1
			weapon_label = "SMG"
			magazine = 40
			reserve_ammo += amount
			weapon_changed.emit(weapon_label)
			ammo_changed.emit(magazine, reserve_ammo)
		"SHOTGUN":
			current_weapon_index = 2
			weapon_label = "SHOTGUN"
			magazine = 8
			reserve_ammo += amount
			weapon_changed.emit(weapon_label)
			ammo_changed.emit(magazine, reserve_ammo)
	if is_instance_valid(soldier_rig):
		soldier_rig.set_weapon(current_weapon_index)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		velocity = Vector3.ZERO
		set_physics_process(false)

func begin_parachute_drop() -> void:
	is_dropping = true
	position.y = 16.0
	velocity = Vector3.ZERO
	parachute_visual = Node3D.new()
	parachute_visual.name = "Parachute"
	add_child(parachute_visual)
	var canopy := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 0.42
	canopy.mesh = sphere
	canopy.scale = Vector3(2.0, 0.35, 1.35)
	var fabric := StandardMaterial3D.new()
	fabric.albedo_color = Color(0.88, 0.32, 0.12)
	fabric.roughness = 0.9
	canopy.material_override = fabric
	canopy.position.y = 4.0
	parachute_visual.add_child(canopy)
	var cord := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.025
	rod.bottom_radius = 0.025
	rod.height = 2.6
	cord.mesh = rod
	var cord_material := StandardMaterial3D.new()
	cord_material.albedo_color = Color(0.85, 0.85, 0.78)
	cord.material_override = cord_material
	cord.position.y = 2.6
	parachute_visual.add_child(cord)

func set_camera_mode(first_person: bool) -> void:
	camera_is_first_person = first_person
	if camera == null:
		return
	if first_person:
		camera.position = Vector3(0, 0.05, 0.12)
		camera.fov = 82.0
		if body_mesh:
			body_mesh.visible = false
	else:
		camera.position = Vector3(0, 0.35, 5.2)
		camera.fov = 75.0
		if body_mesh:
			body_mesh.visible = true
	camera.look_at(camera_pivot.global_position - camera_pivot.global_transform.basis.z * 12.0, Vector3.UP)

func toggle_camera() -> void:
	set_camera_mode(not camera_is_first_person)
