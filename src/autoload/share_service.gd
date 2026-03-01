extends Node


func share_run(run_state: RunState) -> void:
	var card := ShareCardData.from_run(run_state, PersistenceManager.profile)
	var text := ShareCardRenderer.render_text_card(card)

	if _has_native_share():
		_native_share(text)
	else:
		_clipboard_share(text)


func _has_native_share() -> bool:
	return Engine.has_singleton("GodotAndroidShare")


func _native_share(text: String) -> void:
	var share_plugin: Object = Engine.get_singleton("GodotAndroidShare")
	if share_plugin and share_plugin.has_method("share_text"):
		share_plugin.call("share_text", "Snap Dungeon Results", text)


func _clipboard_share(text: String) -> void:
	DisplayServer.clipboard_set(text)
	print("[ShareService] Share text copied to clipboard")
