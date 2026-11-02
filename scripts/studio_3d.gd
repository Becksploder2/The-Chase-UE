extends Node3D
# Native 3D studio foundation; reusable by all formats.
@export_enum("UK", "GSN", "ABC", "REVIVAL", "BTC") var studio_format: String = "UK"
var camera: Camera3D
var orbit := 0.0

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
  get_tree().change_scene_to_file("res://scenes/bootstrap.tscn")

func _process(delta: float) -> void:
 orbit += delta
 if camera != null:
  camera.position.x = sin(orbit * 0.15) * 1.4
  camera.look_at(Vector3(0, 1.1, 0))

func _ready() -> void:
 var root: Node3D = self
 camera = Camera3D.new()
 camera.position = Vector3(0, 7.2, 17)
 camera.look_at(Vector3(0, 1.1, 0))
 camera.current = true
 camera.fov = 60
 root.add_child(camera)
 var environment := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#080f2b")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#8096c9")
 env.ambient_light_energy = 0.6
 environment.environment = env
 root.add_child(environment)
 var key := DirectionalLight3D.new()
 key.rotation_degrees = Vector3(-50, -25, 0)
 key.light_energy = 1.4
 root.add_child(key)
 block(root, Vector3(0, -0.25, 0), Vector3(24, 0.5, 18), Color("#121b39"), true)
 block(root, Vector3(0, 4, -8.5), Vector3(24, 8, 0.4), Color("#101c49"))
 for i in range(13):
  block(root, Vector3(-11.5 + i * 1.9, 4.2, -8.15), Vector3(0.23, 6.5, 0.15), Color("#1f80d0"), true)
 for side in [-1, 1]:
  block(root, Vector3(side * 10.7, 2.8, -1.5), Vector3(0.6, 5.6, 13), Color("#143c81"))
  for j in range(7):
   block(root, Vector3(side * 10.25, 0.7 + j * 0.7, -6 + j * 1.6), Vector3(0.18, 0.12, 0.8), Color("#3cb8ff"), true)
 if studio_format == "UK":
  build_uk_reference_set(root)
  return
 # Illuminated red C entrance arch behind the raised Chaser platform.
 # The right-hand side stays open to form the characteristic C silhouette.
 var entrance_red := Color("#f32642") if studio_format == "UK" else Color("#8d43f0") if studio_format in ["REVIVAL", "BTC"] else Color("#17c1ee") if studio_format == "GSN" else Color("#e74883")
 block(root, Vector3(-3.1, 3.6, -7.65), Vector3(0.55, 5.4, 0.5), entrance_red, true)
 block(root, Vector3(0, 6.05, -7.65), Vector3(6.8, 0.55, 0.5), entrance_red, true)
 block(root, Vector3(0, 1.15, -7.65), Vector3(6.8, 0.55, 0.5), entrance_red, true)
 block(root, Vector3(0.1, 3.5, -7.9), Vector3(5.5, 4.1, 0.12), Color("#090714"))
 var entrance_light := OmniLight3D.new()
 entrance_light.position = Vector3(-1.8, 3.8, -6.9)
 entrance_light.light_color = entrance_red
 entrance_light.light_energy = 2.2
 entrance_light.omni_range = 8.0
 root.add_child(entrance_light)
 # Raised Chaser platform and contestant desks.
 block(root, Vector3(0, 0.65, -5.2), Vector3(7, 1.3, 3.2), Color("#17265a"))
 block(root, Vector3(0, 1.6, -5.1), Vector3(4.4, 0.4, 1.2), Color("#277fd2"), true)
 for x in [-3.5, -1.2, 1.2, 3.5]:
  block(root, Vector3(x, 0.75, 3.2), Vector3(1.9, 1.5, 1.1), Color("#17447b"))
  block(root, Vector3(x, 1.55, 3.2), Vector3(2.0, 0.12, 1.25), Color("#4bbcf5"), true)
 # The Chase table: a long sloping illuminated playing surface.
 block(root, Vector3(0, 0.5, -0.7), Vector3(3.2, 1.0, 7.5), Color("#102e63"))
 for j in range(7):
  block(root, Vector3(0, 1.03, -3.8 + j * 1.02), Vector3(2.95, 0.05, 0.83), Color("#1a9ee6") if j % 2 == 0 else Color("#2863b7"), true)
 # Blue LED Final Chase board at the back of the stage.
 block(root, Vector3(0, 5.0, -8.12), Vector3(7.8, 2.0, 0.25), Color("#087bc4"), true)
 block(root, Vector3(0, 5.0, -7.92), Vector3(7.3, 1.6, 0.14), Color("#051f50"))
 for x in [-3.3, 3.3]:
  var lamp := OmniLight3D.new()
  lamp.position = Vector3(x, 5.8, -2.5)
  lamp.light_color = Color("#39a5ff")
  lamp.light_energy = 1.7
  lamp.omni_range = 11
  root.add_child(lamp)

func block(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color, glowing: bool = false) -> void:
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = dimensions
 mesh.mesh = box
 mesh.position = pos
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.metallic = 0.15
 mat.roughness = 0.45
 if glowing:
  mat.emission_enabled = true
  mat.emission = color
  mat.emission_energy_multiplier = 1.4
 mesh.material_override = mat
 parent.add_child(mesh)

# UK reference: black glossy floor, blue vertical LEDs, continuous red
# perimeter band, angular central silhouette and red/teal/navy ladder.
func build_uk_reference_set(root: Node3D) -> void:
 # The reference studio has a long red LED perimeter with blue vertical light bars.
 block(root, Vector3(0, 2.15, -8.15), Vector3(23.5, 1.35, 0.22), Color("#a91a2c"), true)
 for side in [-1, 1]:
  block(root, Vector3(side * 10.4, 2.1, -2.3), Vector3(0.22, 1.3, 12), Color("#a91a2c"), true)
  for j in range(8):
   var z := -7.3 + j * 1.55
   block(root, Vector3(side * 10.2, 0.32, z), Vector3(0.18, 0.11, 0.65), Color("#216fff"), true)
 # Angular, dark central table/support structure; a distinctive wedge silhouette.
 var wedge := MeshInstance3D.new()
 wedge.name = "Angular black UK table support"
 var prism := PrismMesh.new()
 prism.size = Vector3(6.2, 3.5, 6.8)
 wedge.mesh = prism
 wedge.position = Vector3(1.3, 1.7, -0.1)
 wedge.rotation_degrees = Vector3(0, 0, 180)
 var wedge_material := StandardMaterial3D.new()
 wedge_material.albedo_color = Color("#080a12")
 wedge_material.metallic = 0.9
 wedge_material.roughness = 0.14
 wedge.material_override = wedge_material
 root.add_child(wedge)
 # Raised circular plinth approximated with a cylinder and luminous rim.
 var plinth := MeshInstance3D.new()
 plinth.name = "Circular stage plinth"
 var cylinder := CylinderMesh.new()
 cylinder.top_radius = 4.1
 cylinder.bottom_radius = 4.1
 cylinder.height = 0.35
 plinth.mesh = cylinder
 plinth.position = Vector3(0, 0.03, 0)
 var plinth_mat := StandardMaterial3D.new()
 plinth_mat.albedo_color = Color("#19153b")
 plinth_mat.metallic = 0.7
 plinth.material_override = plinth_mat
 root.add_child(plinth)
 # Rear blue score desk, based on the distant scoreboard in the photograph.
 block(root, Vector3(-3.3, 0.95, -7.0), Vector3(4.4, 1.65, 0.85), Color("#174b9b"))
 block(root, Vector3(-3.3, 1.6, -6.49), Vector3(4.1, 0.22, 0.08), Color("#53d4ff"), true)
 # UK ladder: red chaser zone, two cyan steps, navy lower steps.
 # Keep it separate from the table, as an illuminated display in the 3D scene.
 var ladder := Node3D.new()
 ladder.name = "UK Chase ladder"
 ladder.position = Vector3(4.2, 1.1, -3.8)
 ladder.rotation_degrees.y = -22
 root.add_child(ladder)
 for j in range(7):
  var tile_color := Color("#bb1628") if j == 0 else Color("#07bdbd") if j <= 2 else Color("#101b79")
  block(ladder, Vector3(0, 2.85 - j * 0.47, 0), Vector3(2.05 - j * 0.055, 0.43, 0.14), tile_color, j <= 2)
  block(ladder, Vector3(0, 2.62 - j * 0.47, 0.09), Vector3(2.05 - j * 0.055, 0.035, 0.07), Color("#a7d6ef"), true)
 block(ladder, Vector3(0, 0.95, 0.14), Vector3(1.9, 0.41, 0.1), Color("#101a64"), true)
 var prize := Label3D.new()
 prize.text = "£9,000"
 prize.font_size = 70
 prize.pixel_size = 0.003
 prize.position = Vector3(0, 0.95, 0.23)
 prize.modulate = Color.WHITE
 ladder.add_child(prize)
 # Blue overhead spotlights and a red floor reflection effect.
 for i in range(8):
  var spot := SpotLight3D.new()
  spot.position = Vector3(-9.0 + i * 2.6, 7.2, -3.8)
  spot.rotation_degrees.x = -90
  spot.light_color = Color("#307dff") if i % 2 == 0 else Color("#ed2547")
  spot.light_energy = 4.0
  spot.spot_range = 11.0
  root.add_child(spot)
