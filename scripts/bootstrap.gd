extends Control

# Independent startup screen: always renders even if the game script fails to parse.
var status_label: Label

func _ready() -> void:
 var background := ColorRect.new()
 background.color = Color("#0a1230")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 var layout := VBoxContainer.new()
 layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layout.alignment = BoxContainer.ALIGNMENT_CENTER
 layout.add_theme_constant_override("separation", 20)
 add_child(layout)
 var title := Label.new()
 title.text = "THE CHASE"
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_size_override("font_size", 58)
 title.add_theme_color_override("font_color", Color("#f2d57b"))
 layout.add_child(title)
 status_label = Label.new()
 status_label.text = "STARTING THE GAME..."
 status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 status_label.add_theme_font_size_override("font_size", 22)
 layout.add_child(status_label)
 # Let the startup screen draw before loading the large gameplay script.
 await get_tree().process_frame
 await get_tree().process_frame
 _open_game()

func _open_game() -> void:
 var game_scene := load("res://scenes/main.tscn") as PackedScene
 if game_scene == null:
  _startup_failed("Could not load the game scene. Check the GitHub startup log.")
  return
 var error := get_tree().change_scene_to_packed(game_scene)
 if error != OK:
  _startup_failed("Game scene failed to open (error %d)." % error)

func _startup_failed(message: String) -> void:
 status_label.text = "STARTUP ERROR: " + message
 push_error(message)
