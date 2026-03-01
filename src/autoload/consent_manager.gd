extends Node

const CONSENT_KEY := "gdpr_consent_given"
const CONSENT_VERSION := 1

signal consent_granted()
signal consent_denied()

var _consent_given: bool = false


func _ready() -> void:
	_consent_given = _load_consent()


func has_consent() -> bool:
	return _consent_given


func needs_consent() -> bool:
	return not _consent_given and _is_gdpr_region()


func grant_consent() -> void:
	_consent_given = true
	_save_consent(true)
	consent_granted.emit()


func deny_consent() -> void:
	_consent_given = false
	_save_consent(false)
	consent_denied.emit()


func _is_gdpr_region() -> bool:
	var locale := OS.get_locale_language()
	var gdpr_locales := [
		"de", "fr", "it", "es", "pt", "nl", "pl", "sv", "da", "fi",
		"nb", "cs", "sk", "hu", "ro", "bg", "hr", "sl", "lt", "lv",
		"et", "el", "mt", "ga", "en_GB",
	]
	return locale in gdpr_locales


func _save_consent(granted: bool) -> void:
	var config := ConfigFile.new()
	config.set_value("privacy", "consent", granted)
	config.set_value("privacy", "version", CONSENT_VERSION)
	config.set_value("privacy", "timestamp", Time.get_unix_time_from_system())
	config.save("user://consent.cfg")


func _load_consent() -> bool:
	var config := ConfigFile.new()
	if config.load("user://consent.cfg") != OK:
		return false
	var version: int = config.get_value("privacy", "version", 0)
	if version < CONSENT_VERSION:
		return false
	return config.get_value("privacy", "consent", false)
