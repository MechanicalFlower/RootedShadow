# Helps with handling Godot Engine settings relevant to GOAT.

extends Node

signal value_changed(section, key)

const SETTINGS_FILE_NAME := "user://settings.cfg"

# Min volume dB
const MIN_VOLUME_DB = -80.0

# Each entry contains: section name, key name, default value
var default_values := [
	["graphics", "fullscreen_enabled", true],
	["sound", "music_volume", 1.0],
	["sound", "effects_volume", 1.0],
	["controls", "mouse_sensitivity", 0.3],
]

# If enabled, settings will be saved to file when changed
var autosave := true

var _settings_file := ConfigFile.new()


func _ready():
	_settings_file.load(SETTINGS_FILE_NAME)

	for entry in default_values:
		var section = entry[0]
		var key = entry[1]
		var value = entry[2]
		# Add detailed signals for each section and key
		add_user_signal("value_changed_{}_{}".format([section, key], "{}"))
		# If settings file doesn't have the section/key yet,
		# add it with the default value
		if _settings_file.get_value(section, key, null) == null:
			_settings_file.set_value(section, key, value)

	_settings_file.save(SETTINGS_FILE_NAME)

	# Connect settings to global handlers
	var settings_signals_handlers = {
		"value_changed_graphics_fullscreen_enabled": "_on_fullscreen_settings_changed",
		"value_changed_sound_music_volume": "_on_music_settings_changed",
		"value_changed_sound_effects_volume": "_on_effects_settings_changed",
	}

	for key in settings_signals_handlers:
		connect(key, self, settings_signals_handlers[key])

	# Make sure that initial values are loaded correctly
	_on_fullscreen_settings_changed()
	_on_music_settings_changed()
	_on_effects_settings_changed()


func get_value(section: String, key: String):
	var value = _settings_file.get_value(section, key)
	assert(value != null)
	return value


func set_value(section: String, key: String, value) -> void:
	var previous_value = _settings_file.get_value(section, key)
	if previous_value != value:
		_settings_file.set_value(section, key, value)
		if autosave:
			_settings_file.save(SETTINGS_FILE_NAME)
		emit_signal("value_changed", section, key)
		emit_signal("value_changed_{}_{}".format([section, key], "{}"))


func find_matching_loaded_locale() -> String:
	"""
	Returns a loaded locale that best matches currently set locale. If there
	are no translations provided, returns an empty string. Otherwise, attempts
	to match the exact locale name, if that fails, checks a partial match
	(e.g. "en_US" will match "en"). If the matching process fails for the
	current locale, fallback locale (from Project Settings) is checked.
	If that fails too, the first provided locale is returned.
	"""
	var current_locale = TranslationServer.get_locale()
	var loaded_locales = TranslationServer.get_loaded_locales()
	var fallback_locale = ProjectSettings.get("locale/fallback")

	# If no translations are provided, return ""
	if not loaded_locales:
		return ""

	# If the exact locale is loaded, return it
	if current_locale in loaded_locales:
		return current_locale

	# Look for partial matches, e.g. current is "en_US", loaded is "en"
	# Try the current locale first, then the fallback locale
	for locale in [current_locale, fallback_locale]:
		for loaded_locale in loaded_locales:
			if locale.substr(0, 2) == loaded_locale.substr(0, 2):
				return loaded_locale

	# If nothing matches, return first provided translation
	return loaded_locales[0]


func disable_for_html():
	return OS.get_name() != "HTML5"


func _on_fullscreen_settings_changed() -> void:
	OS.window_fullscreen = get_value("graphics", "fullscreen_enabled")


func _on_music_settings_changed() -> void:
	var volume = get_value("sound", "music_volume")
	_set_volume_db("Music", volume)


func _on_effects_settings_changed() -> void:
	var volume = get_value("sound", "effects_volume")
	_set_volume_db("SFX", volume)


func _set_volume_db(bus_name: String, volume: float) -> void:
	"""
	Volume is a value between 0 (complete silence) and 1 (default bus volume).
	It is recalculated to a non-linear value between -80 and 0 dB.
	Using a linear value causes the sound to almost vanish long before the
	volume slider reaches minimum.
	"""
	# Recalculate to <MIN_VOLUME_DB, 0>, non-linear
	var volume_db = abs(MIN_VOLUME_DB) * sqrt(2 * volume - pow(volume, 2)) + MIN_VOLUME_DB
	var bus_id = AudioServer.get_bus_index(bus_name)
	assert(bus_id != -1, "Invalid bus_name = " + bus_name)
	AudioServer.set_bus_volume_db(bus_id, volume_db)
