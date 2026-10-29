extends Control

# Native Godot foundation. Legacy Electron gameplay remains in src/ until ported.
const FORMATS = {
 "uk": {"title": "THE CHASE · UK", "host": "Bradley Walsh", "players": 4},
 "gsn": {"title": "THE CHASE · GSN", "host": "Brooke Burns", "players": 4},
 "abc": {"title": "THE CHASE · ABC", "host": "Sara Haines", "players": 3},
 "btc": {"title": "BEAT THE CHASERS", "host": "Bradley Walsh", "players": 1}
}
const QUESTIONS = [
 ["What planet is known as the Red Planet?", ["Mars", "Venus", "Saturn", "Mercury"], 0],
 ["How many sides does a hexagon have?", ["Five", "Six", "Seven", "Eight"], 1],
 ["Which ocean borders California?", ["Atlantic", "Indian", "Pacific", "Arctic"], 2],
 ["What is the capital of France?", ["Berlin", "Madrid", "Paris", "Rome"], 2],
 ["What is 12 multiplied by 8?", ["86", "94", "96", "108"], 2],
 ["Which element has the chemical symbol O?", ["Gold", "Oxygen", "Osmium", "Iron"], 1],
 ["How many minutes are in one hour?", ["45", "50", "60", "90"], 2]
]
var mode := "uk"
var phase := "menu"
var stage: Control
var overlay: VBoxContainer
var clock: Timer
var question_index := 0
var cash_correct := 0
var seconds_left := 60
var intro_step := 0
var btc_revealed := 0
var btc_offers: Array = []
var btc_selected_offer := {}
const BTC_CHASERS = ["Mark Labbett", "Anne Hegerty", "Shaun Wallace", "Paul Sinha", "Jenny Ryan"]
var imported_tracks := {}
var music: AudioStreamPlayer
var file_dialog: FileDialog
var music_slot := "intro"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
 rng.randomize()
 stage = Control.new()
 stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 overlay = VBoxContainer.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_theme_constant_override("separation", 12)
 add_child(overlay)
 clock = Timer.new()
 clock.wait_time = 1.0
 clock.timeout.connect(_on_tick)
 add_child(clock)
 music = AudioStreamPlayer.new()
 add_child(music)
 file_dialog = FileDialog.new()
 file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
 file_dialog.access = FileDialog.ACCESS_FILESYSTEM
 file_dialog.filters = PackedStringArray(["*.ogg, *.mp3, *.wav ; Audio"])
 file_dialog.file_selected.connect(_on_music_file)
 add_child(file_dialog)
 show_menu()

func clear_ui() -> void:
 for child in overlay.get_children():
  child.queue_free()
 for child in stage.get_children():
  child.queue_free()

func heading(t: String) -> void:
 var l := Label.new()
 l.text = t
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size", 28)
 l.add_theme_color_override("font_color", Color("#ffe7a1"))
 overlay.add_child(l)

func label(t: String) -> void:
 var l := Label.new()
 l.text = t
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size", 18)
 overlay.add_child(l)

func action(t: String, callback: Callable) -> void:
 var b := Button.new()
 b.text = t
 b.custom_minimum_size = Vector2(0, 43)
 b.pressed.connect(callback)
 overlay.add_child(b)

func show_menu() -> void:
 phase = "menu"
 clock.stop()
 music.stop()
 clear_ui()
 heading("THE CHASE · 8-BIT ULTIMATE EDITION")
 label("NATIVE GODOT PREVIEW — gameplay migration in progress")
 for id in FORMATS:
  var chosen: String = id
  action(FORMATS[id]["title"], func(): select_mode(chosen))

func select_mode(id: String) -> void:
 mode = id
 phase = "setup"
 clear_ui()
 draw_studio()
 heading(FORMATS[mode]["title"])
 label("Host: " + FORMATS[mode]["host"])
 action("START THE SHOW", start_intro)
 action("IMPORT OPENING MUSIC", func(): import_music("intro"))
 action("IMPORT HERE COMES THE CHASER CUE", func(): import_music("chaser-entrance"))
 action("IMPORT CASH BUILDER MUSIC", func(): import_music("cash"))
 if mode == "btc":
  action("IMPORT BTC BATTLE MUSIC", func(): import_music("btc-battle"))
 action("BACK", show_menu)

func start_intro() -> void:
 phase = "intro"
 intro_step = 0
 show_intro()

func show_intro() -> void:
 clear_ui()
 draw_studio()
 heading(FORMATS[mode]["title"])
 if mode == "btc":
  var steps := ["SPINNING C'S · OPENING", "PLEASE WELCOME " + FORMATS[mode]["host"].to_upper(), "CONTESTANT ENTRANCE", "THE CHASERS"]
  label(steps[intro_step])
 else:
  label("WELCOME TO THE CHASE")
 if intro_step == 0:
  play_track("intro")
 action("NEXT", next_intro)
 action("SKIP TO CASH BUILDER", begin_cash)

func next_intro() -> void:
 intro_step += 1
 if intro_step >= (4 if mode == "btc" else 1):
  begin_cash()
 else:
  show_intro()

func reveal_chaser() -> void:
 phase = "chaser_entrance"
 play_track("chaser-entrance")
 clear_ui()
 draw_studio()
 heading("HERE COMES THE CHASER")
 label("The Chaser makes their entrance!")
 action("CONTINUE", func(): select_mode(mode))

func begin_cash() -> void:
 phase = "cash"
 question_index = 0
 cash_correct = 0
 seconds_left = 60
 play_track("cash")
 if mode != "btc":
  clock.start()
 show_question()

func show_question() -> void:
 clear_ui()
 draw_studio()
 heading("CASH BUILDER")
 label(("QUESTION %d OF 5" % (question_index + 1)) if mode == "btc" else ("%d SECONDS REMAINING" % seconds_left))
 var q: Array = QUESTIONS[question_index % QUESTIONS.size()]
 label(q[0])
 for i in range(4):
  var answer_index := i
  action(q[1][i], func(): answer(answer_index))
 action("MAIN MENU", show_menu)

func answer(index: int) -> void:
 var q: Array = QUESTIONS[question_index % QUESTIONS.size()]
 if index == q[2]:
  cash_correct += 1
 question_index += 1
 if (mode == "btc" and question_index >= 5) or (mode != "btc" and seconds_left <= 0):
  finish_cash()
 else:
  show_question()

func _on_tick() -> void:
 if phase != "cash":
  return
 seconds_left -= 1
 if seconds_left <= 5:
  music.volume_db = linear_to_db(maxf(0.001, float(seconds_left) / 5.0))
 if seconds_left <= 0:
  finish_cash()
 else:
  show_question()

func finish_cash() -> void:
 clock.stop()
 music.stop()
 phase = "cash_result"
 clear_ui()
 draw_studio()
 heading("CASH BUILDER COMPLETE")
 label("%d CORRECT ANSWERS" % cash_correct)
 label("Further Chase rounds are being ported from Electron.")
 if mode == "btc":
  begin_btc_offers()
 else:
  action("HERE COMES THE CHASER", reveal_chaser)
  action("BACK TO SHOW SETUP", func(): select_mode(mode))

func begin_btc_offers() -> void:
 phase = "btc_offers"
 btc_revealed = 2
 btc_offers.clear()
 # Each subsequent Chaser adds a new offer. All offers are displayed before selection.
 for n in range(2, 6):
  btc_offers.append({"chasers": n, "money": cash_correct * 1000 + (n - 1) * 10000, "clock": 60 - n * 5})
 show_btc_offers()

func show_btc_offers() -> void:
 clear_ui()
 draw_studio()
 heading("BEAT THE CHASERS · THE OFFERS")
 label("%d CHASERS REVEALED" % btc_revealed)
 for i in range(btc_revealed):
  label(BTC_CHASERS[i])
 var current: Dictionary = btc_offers[btc_revealed - 2]
 label("%s OFFERS: £%d · CHASERS GET %d SECONDS" % [BTC_CHASERS[btc_revealed - 1], current["money"], current["clock"]])
 if btc_revealed < 5:
  action("REVEAL NEXT CHASER AND OFFER", func():
   btc_revealed += 1
   show_btc_offers()
  )
 else:
  action("VIEW ALL OFFERS", show_btc_selection)

func show_btc_selection() -> void:
 phase = "btc_selection"
 clear_ui()
 draw_studio()
 heading("NOW CHOOSE YOUR OFFER")
 label("All Chasers and their offers have been revealed.")
 for offer in btc_offers:
  var selected: Dictionary = offer
  action("%d CHASERS · £%d · %d SECONDS" % [selected["chasers"], selected["money"], selected["clock"]], func(): choose_btc_offer(selected))

func choose_btc_offer(offer: Dictionary) -> void:
 btc_selected_offer = offer.duplicate()
 phase = "btc_battle_preview"
 clear_ui()
 draw_studio()
 heading("OFFER ACCEPTED")
 label("%d CHASERS · £%d · %d SECOND CHASER CLOCK" % [offer["chasers"], offer["money"], offer["clock"]])
 label("The native Godot clock battle is not yet ported.")
 action("BACK TO SETUP", func(): select_mode(mode))

func import_music(slot: String) -> void:
 music_slot = slot
 file_dialog.popup_centered_ratio(0.7)

func _on_music_file(path: String) -> void:
 var ext := path.get_extension().to_lower()
 var stream: AudioStream
 if ext == "mp3":
  stream = AudioStreamMP3.load_from_file(path)
 elif ext == "ogg":
  stream = AudioStreamOggVorbis.load_from_file(path)
 elif ext == "wav":
  stream = AudioStreamWAV.load_from_file(path)
 if stream != null:
  imported_tracks[mode + ":" + music_slot] = stream
  label("IMPORTED: " + path.get_file())
 else:
  label("Could not decode this audio file.")

func play_track(slot: String) -> void:
 music.stop()
 music.volume_db = 0.0
 var key := mode + ":" + slot
 if imported_tracks.has(key):
  music.stream = imported_tracks[key]
  music.play()

func rect(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
 var r := ColorRect.new()
 r.position = pos
 r.size = size
 r.color = color
 parent.add_child(r)
 return r

func draw_studio() -> void:
 var bg := Color("#101c48") if mode == "uk" else Color("#0c3261") if mode == "gsn" else Color("#173c6b") if mode == "abc" else Color("#291143")
 rect(stage, Vector2.ZERO, Vector2(1280, 720), bg)
 for i in range(12):
  rect(stage, Vector2(70 + i * 95, 135), Vector2(30, 8), Color("#f2cf83"))
 rect(stage, Vector2(100, 300), Vector2(1080, 250), bg.lightened(0.2))
 if mode == "btc":
  # Native scene geometry: elevated horseshoe and central exit walkway.
  rect(stage, Vector2(230, 205), Vector2(820, 36), Color("#d2a4fa"))
  rect(stage, Vector2(230, 205), Vector2(50, 230), Color("#9e6cdb"))
  rect(stage, Vector2(1000, 205), Vector2(50, 230), Color("#9e6cdb"))
  rect(stage, Vector2(350, 395), Vector2(580, 32), Color("#a274dd"))
  rect(stage, Vector2(565, 430), Vector2(150, 230), Color("#55317e"))
 else:
  # Perspective table: progressively wider rungs toward the contestant.
  for i in range(7):
   var width := 250.0 + i * 50.0
   rect(stage, Vector2(640 - width / 2.0, 250 + i * 44), Vector2(width, 35), Color("#2267ae") if i % 2 == 0 else Color("#dbb15f"))
