extends Node
## Zentraler Dienst fuer Szenenwechsel (Paket Z, 27.11.2026). Autoload "SceneLoadingService".
## Statt change_scene_to_file (laedt alles in einem Bild, Windows meldet "reagiert nicht") laedt der Dienst die Zielszene im
## Hintergrund (ResourceLoader.load_threaded_*), fragt jedes Bild den Fortschritt ab und zeigt nach 0,3 s einen Ladebildschirm.
## Balken: 0-90 % Laden, 90-100 % Instanzieren + Wechsel + zwei Bilder danach.
## Rueckfall auf change_scene_to_file bei jedem Fehler und kopflos (ausser force_threaded), damit Pruefer gleich bleiben.
## Zeitmessung: ladezeit() schreibt "[ladezeit] ..."-Zeilen per print und an user://ladezeit.log.

signal loading_finished(path: String, error: int)

const SHOW_DELAY_MSEC: int = 300
const OVERLAY_LAYER: int = 200
const LOAD_SHARE: float = 0.9
const FRAMES_AFTER_SWITCH: int = 2
const HELP_CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const LADEZEIT_LOG_PATH: String = "user://ladezeit.log"
const FALLBACK_TIPS: Array[String] = [
	"Im Orbit planst du Flüge auf der Sternkarte; ein Doppelklick auf einen Ort startet den Anflug.",
	"Prüfe vor dem Start, ob Treibstoff, Munition und Besatzung für den Einsatz reichen.",
	"Verwundete Personen fallen im Einsatz aus. Plane Ersatz in der Basis ein.",
	"Mit Esc öffnest du das Menü; dort speicherst du und kehrst zum Hauptmenü zurück.",
	"Die Zeit läuft auch in der Basis. Erledigte Aufträge bringen Geld für Wartung und Tanken.",
]

var _loading: bool = false
var _path: String = ""
var _options: Dictionary = {}
var _phase: String = ""
var _frames_left: int = 0
var _progress: float = 0.0
var _call_msec: int = 0
var _timing_active: bool = false
var _t0_msec: int = 0
var _tips_cache: Array = []
var _overlay: CanvasLayer = null
var _bar: ProgressBar = null
var _percent_label: Label = null
var _title_label: Label = null
var _tip_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # auch bei angehaltenem Baum (Bankrott) weiterlaufen
	set_process(false)
	_t0_msec = Time.get_ticks_msec()


func is_loading() -> bool:
	return _loading


## Aktueller Fortschritt 0..100 (fuer Pruefer und Anzeige).
func get_progress_percent() -> float:
	return _progress * 100.0


func is_overlay_visible() -> bool:
	return is_instance_valid(_overlay) and _overlay.visible


## Wechselt die Szene. options: "tip_context" (String), "force_threaded" (bool), "title" (String, Standard "Spiel").
func change_scene(path: String, options: Dictionary = {}) -> Error:
	if _loading:
		return ERR_BUSY
	var tree: SceneTree = get_tree()
	if tree == null:
		return ERR_UNCONFIGURED
	_t0_msec = Time.get_ticks_msec()
	_timing_active = true
	_append_log("=== Ladevorgang " + path)
	ladezeit("Klick/Aufruf change_scene " + path)
	var force_threaded: bool = bool(options.get("force_threaded", false))
	if DisplayServer.get_name() == "headless" and not force_threaded:
		return _fallback_change(path)
	if not ResourceLoader.exists(path):
		return _fallback_change(path)
	var request_error: Error = ResourceLoader.load_threaded_request(path, "PackedScene", true)
	if request_error != OK:
		return _fallback_change(path)
	_loading = true
	_path = path
	_options = options.duplicate()
	_phase = "load"
	_progress = 0.0
	_call_msec = Time.get_ticks_msec()
	set_process(true)
	return OK


func _process(_delta: float) -> void:
	if not _loading:
		set_process(false)
		return
	var elapsed: int = Time.get_ticks_msec() - _call_msec
	match _phase:
		"load":
			var progress_info: Array = []
			var status: int = ResourceLoader.load_threaded_get_status(_path, progress_info)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var fraction: float = float(progress_info[0]) if progress_info.size() > 0 else 0.0
				_progress = maxf(_progress, clampf(fraction, 0.0, 1.0) * LOAD_SHARE)
			elif status == ResourceLoader.THREAD_LOAD_LOADED:
				ladezeit("Szene geladen " + _path)
				_progress = maxf(_progress, LOAD_SHARE)
				_switch_to_loaded_scene()
			else:
				ladezeit("Hintergrundladen fehlgeschlagen (Status %d), Rueckfall" % status)
				_abort_with_fallback()
				return
			if _loading and elapsed >= SHOW_DELAY_MSEC:
				_show_overlay()
		"after":
			_frames_left -= 1
			_update_overlay()
			if _frames_left <= 0:
				_finish(OK)
				return
	if _loading:
		_update_overlay()


func _switch_to_loaded_scene() -> void:
	var packed: PackedScene = ResourceLoader.load_threaded_get(_path) as PackedScene
	if packed == null:
		_abort_with_fallback()
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		_abort_with_fallback()
		return
	var switch_error: Error = tree.change_scene_to_packed(packed)
	if switch_error != OK:
		ladezeit("change_scene_to_packed Fehler %d, Rueckfall" % switch_error)
		_abort_with_fallback()
		return
	ladezeit("Szene instanziert, Wechsel angefordert " + _path)
	_phase = "after"
	_frames_left = FRAMES_AFTER_SWITCH
	_progress = LOAD_SHARE + (1.0 - LOAD_SHARE) * 0.5


func _abort_with_fallback() -> void:
	var path: String = _path
	_loading = false
	set_process(false)
	_hide_overlay()
	_fallback_change(path)


func _finish(error: int) -> void:
	_progress = 1.0
	_update_overlay()
	var path: String = _path
	_loading = false
	_phase = ""
	set_process(false)
	_hide_overlay()
	ladezeit("Ladevorgang abgeschlossen " + path)
	loading_finished.emit(path, error)


## Alter Weg: change_scene_to_file in einem Stueck.
func _fallback_change(path: String) -> Error:
	var tree: SceneTree = get_tree()
	var error: Error = ERR_UNCONFIGURED
	if tree != null:
		error = tree.change_scene_to_file(path)
	_progress = 1.0 if error == OK else 0.0
	ladezeit("Direkter Wechsel (change_scene_to_file) %s Ergebnis %d" % [path, error])
	loading_finished.emit(path, error)
	return error


# ---------------------------------------------------------------- Ladebildschirm

func _show_overlay() -> void:
	if not is_instance_valid(_overlay):
		_build_overlay()
	if not _overlay.visible:
		_title_label.text = "%s wird geladen" % String(_options.get("title", "Spiel"))
		_tip_label.text = _pick_tip(String(_options.get("tip_context", "")))
		_overlay.visible = true
		ladezeit("Ladebildschirm sichtbar")


func _hide_overlay() -> void:
	if is_instance_valid(_overlay):
		_overlay.visible = false


func _update_overlay() -> void:
	if not is_instance_valid(_overlay) or not _overlay.visible:
		return
	var percent: float = clampf(_progress * 100.0, 0.0, 100.0)
	_bar.value = percent
	_percent_label.text = "%d %%" % int(round(percent))


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "SceneLoadingOverlay"
	_overlay.layer = OVERLAY_LAYER
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.03, 0.04, 0.07, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP # kein zweiter Klick waehrend des Ladens
	_overlay.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "Center"
	background.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.custom_minimum_size = Vector2(620, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "Spiel wird geladen"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	box.add_child(_title_label)
	_bar = ProgressBar.new()
	_bar.name = "ProgressBar"
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(620, 26)
	box.add_child(_bar)
	_percent_label = Label.new()
	_percent_label.name = "PercentLabel"
	_percent_label.text = "0 %"
	_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_percent_label.add_theme_font_size_override("font_size", 22)
	box.add_child(_percent_label)
	_tip_label = Label.new()
	_tip_label.name = "TipLabel"
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.custom_minimum_size = Vector2(620, 60)
	_tip_label.modulate = Color(0.8, 0.85, 0.95, 0.9)
	box.add_child(_tip_label)
	_overlay.visible = false


## Tipp aus dem Hilfekatalog (data/contextual_help_catalog.json), passend zu context (screen_id oder help_id-Anfang), sonst zufaellig.
func _pick_tip(context: String) -> String:
	if _tips_cache.is_empty():
		_load_tips()
	var matching: Array = []
	var wanted: String = context.strip_edges().to_lower()
	if not wanted.is_empty():
		for entry: Dictionary in _tips_cache:
			if String(entry.get("screen", "")) == wanted or String(entry.get("id", "")).begins_with(wanted):
				matching.append(entry)
	var pool: Array = matching if not matching.is_empty() else _tips_cache
	if pool.is_empty():
		return "Tipp: " + FALLBACK_TIPS[randi() % FALLBACK_TIPS.size()]
	var chosen: Dictionary = pool[randi() % pool.size()]
	return "Tipp: " + String(chosen.get("text", ""))


func _load_tips() -> void:
	_tips_cache = []
	if FileAccess.file_exists(HELP_CATALOG_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HELP_CATALOG_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			var entries: Variant = (parsed as Dictionary).get("entries", [])
			if typeof(entries) == TYPE_ARRAY:
				for raw: Variant in entries:
					if typeof(raw) != TYPE_DICTIONARY:
						continue
					var entry: Dictionary = raw
					if String(entry.get("status", "")) != "ready":
						continue
					var lines: Variant = entry.get("compact_lines", [])
					if typeof(lines) != TYPE_ARRAY or (lines as Array).is_empty():
						continue
					var text: String = " ".join(PackedStringArray((lines as Array).map(func(l: Variant) -> String: return String(l))))
					if text.strip_edges().is_empty():
						continue
					_tips_cache.append({
						"id": String(entry.get("help_id", "")).to_lower(),
						"screen": String(entry.get("screen_id", "")).to_lower(),
						"text": text,
					})
	if _tips_cache.is_empty():
		for tip: String in FALLBACK_TIPS:
			_tips_cache.append({"id": "", "screen": "", "text": tip.trim_prefix("Tipp: ")})


# ---------------------------------------------------------------- Zeitmessung

## Schreibt "[ladezeit] +<ms> ms  <label>" (ms seit change_scene, sonst seit Dienststart) per print und an user://ladezeit.log.
## Kopflos ohne laufenden Ladevorgang bleibt es still, damit Pruefer nicht mit Zeilen zugemuellt werden.
func ladezeit(label: String) -> void:
	if DisplayServer.get_name() == "headless" and not _timing_active:
		return
	var line: String = "[ladezeit] +%d ms  %s" % [Time.get_ticks_msec() - _t0_msec, label]
	print(line)
	_append_log(line)


## Wie ladezeit(), aber erst nach dem naechsten gezeichneten Bild (ohne await aufrufen).
func ladezeit_after_next_draw(label: String) -> void:
	await RenderingServer.frame_post_draw
	ladezeit(label)


func _append_log(line: String) -> void:
	if DisplayServer.get_name() == "headless" and not _timing_active:
		return
	var mode: FileAccess.ModeFlags = FileAccess.READ_WRITE if FileAccess.file_exists(LADEZEIT_LOG_PATH) else FileAccess.WRITE
	var file: FileAccess = FileAccess.open(LADEZEIT_LOG_PATH, mode)
	if file == null:
		return
	file.seek_end()
	file.store_line(line)
	file.close()
