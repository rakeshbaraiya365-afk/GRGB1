extends CharacterBody3D
class_name GRBGPlayer

signal health_changed(current: int, maximum: int)
signal ammo_changed(magazine: int, reserve: int)
signal fire_requested(origin: Vector3, direction: Vector3)

const WALK_SPEED := 6.0
const SPRINT_SPEED := 9.0
const JUMP_VELOCITY := 5.5
const GRAVITY := 18.0
const MAGAZINE_SIZE := 30
const FIRE_INTERVAL := 0.18
const RELOAD_SECONDS := 1.25

var max_health := 100
var health := 100
var magazine := MAGAZINE_SIZE
var reserve_ammo := 90
var fire_cooldown := 0.0
var reload_timer := 0.0
var move_vector := Vector2.ZERO
var sprint_held := false
var camera_is_first_person := false

var camera: Camera3D
var camera_pivot: Node3D
var body_mesh: MeshInstance3D

func _ready() -> void:
	_build_collision()
	_build_visual()
	_build_camera()
	health_changed.emit(health, max_health)
	ammo_changed.emit(magazine, reserve_ammo)

func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

func _build_visual() -> void:
	body_mesh = MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.42
	capsule_mesh.height = 1.8
	body_mesh.mesh = capsule_mesh
	body_mesh.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.42, 0.72)
	material.metallic = 0.12
	material.roughness = 0.55
	body_mesh.material_override = material
	add_child(body_mesh)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera_pivot.add_child(camera)
	camera.current = true
	set_camera_mode(false)

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if move_vector.length() > 0.05:
		input_vector = move_vector
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	direction = global_transform.basis * direction
	direction.y = 0.0
	direction = direction.normalized()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var speed := SPRINT_SPEED if (sprint_held or Input.is_action_pressed("sprint")) else WALK_SPEED
	if direction.length() > 0.05:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 5.0 * delta)

	move_and_slide()

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
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func shoot() -> void:
	if fire_cooldown > 0.0 or reload_timer > 0.0:
		return
	if magazine <= 0:
		reload_weapon()
		return
	magazine -= 1
	fire_cooldown = FIRE_INTERVAL
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	fire_requested.emit(origin, direction)
	ammo_changed.emit(magazine, reserve_ammo)

func reload_weapon() -> void:
	if reload_timer > 0.0 or magazine >= MAGAZINE_SIZE or reserve_ammo <= 0:
		return
	reload_timer = RELOAD_SECONDS

func _finish_reload() -> void:
	var needed := MAGAZINE_SIZE - magazine
	var loaded := mini(needed, reserve_ammo)
	magazine += loaded
	reserve_ammo -= loaded
	ammo_changed.emit(magazine, reserve_ammo)

func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		set_physics_process(false)

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
	camera.look_at(camera_pivot.global_position + Vector3(0, 0.0, -12.0), Vector3.UP)

func toggle_camera() -> void:
	set_camera_mode(not camera_is_first_person)
