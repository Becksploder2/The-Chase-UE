extends SubViewportContainer
# First 2.5D UK studio prototype. Native Godot 3D geometry, no external models.
var world: SubViewport
var camera: Camera3D
var orbit := 0.0

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stretch = true
 world = SubViewport.new()
 world.size = Vector2i(1280, 720)
 world.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 world.transparent_bg = false
 add_child(world)
 var root := Node3D.new()
 world.add_child(root)
 camera = Camera3D.new()
 camera.position = Vector3(0, 7.2, 17)
 camera.look_at(Vector3(0, 1.1, 0))
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
 # Illuminated red C entrance arch behind the raised Chaser platform.
 # The right-hand side stays open to form the characteristic C silhouette.
 var entrance_red := Color("#f32642")
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
