extends CheckButton

export(String) var settings_section
export(String) var settings_key


func _ready():
	if settings_section and settings_key:
		pressed = SettingsManager.get_value(settings_section, settings_key)


func _on_SettingsCheckButton_pressed():
	if settings_section and settings_key:
		SettingsManager.set_value(settings_section, settings_key, pressed)
