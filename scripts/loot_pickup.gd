extends Area3D
class_name GRBGLootPickup

var kind := "AMMO"
var amount := 30
var display_name := "AMMO"
var spin_speed := 1.2

func _ready() -> void:
	monitoring = true
	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 1.25
	collision.shape = sphere_shape
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.75, 0.75, 0.75)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	match kind:
		"HEALTH":
			material.albedo_color = Color(0.12, 0.82, 0.35)
			display_name = "MEDKIT"
		"AMMO":
			material.albedo_color = Color(0.95, 0.72, 0.12)
			display_name = "AMMO"
		"SMG":
			material.albedo_color = Color(0.18, 0.65, 0.95)
			display_name = "SMG"
		"SHOTGUN":
			material.albedo_color = Color(0.72, 0.28, 0.82)
			display_name = "SHOTGUN"
	mesh_instance.material_override = material
	mesh_instance.position.y = 0.7
	add_child(mesh_instance)

	var label := Label3D.new()
	label.text = display_name
	label.position.y = 1.45
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	add_child(label)

func _process(delta: float) -> void:
	rotation.y += spin_speed * delta
