## HTTP debug server for external test tooling.
## Exposes game state as JSON on localhost:8090.
## Only active in debug builds.
extends Node


var _server: TCPServer
var _port: int = 8090
var _enabled: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		return
	_enabled = true
	_server = TCPServer.new()
	var err := _server.listen(_port, "127.0.0.1")
	if err != OK:
		push_warning("[DebugServer] Failed to listen on port %d: %s" % [_port, error_string(err)])
		_enabled = false
		return
	print("[DebugServer] Listening on http://127.0.0.1:%d" % _port)


func _process(_delta: float) -> void:
	if not _enabled:
		return
	if _server.is_connection_available():
		var connection := _server.take_connection()
		if connection:
			_handle_connection(connection)


func _handle_connection(peer: StreamPeerTCP) -> void:
	peer.set_no_delay(true)
	var request_data := ""
	var body := ""
	var content_length := 0
	var headers_done := false

	for _i: int in range(100):
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			return
		var available := peer.get_available_bytes()
		if available > 0:
			var chunk := peer.get_utf8_string(available)
			request_data += chunk
			if not headers_done and "\r\n\r\n" in request_data:
				headers_done = true
				var parts := request_data.split("\r\n\r\n", true, 1)
				var header_text: String = parts[0]
				if parts.size() > 1:
					body = parts[1]
				for line: String in header_text.split("\r\n"):
					if line.to_lower().begins_with("content-length:"):
						content_length = line.split(":")[1].strip_edges().to_int()
				if content_length <= 0 or body.length() >= content_length:
					break
			elif headers_done and body.length() >= content_length:
				break
		else:
			if headers_done and (content_length <= 0 or body.length() >= content_length):
				break
			OS.delay_msec(1)

	if request_data.is_empty():
		return

	var first_line := request_data.split("\r\n")[0]
	var tokens := first_line.split(" ")
	if tokens.size() < 2:
		return

	var method: String = tokens[0]
	var path: String = tokens[1]

	var response := _route(method, path, body)
	_send_response(peer, response)


func _route(method: String, path: String, body: String) -> Dictionary:
	if method == "GET":
		match path:
			"/health":
				return _json_ok({"status": "ok", "version": "0.3.0"})
			"/state":
				return _json_ok(_get_full_state())
			"/entities":
				return _json_ok(_get_entities())
			"/run":
				return _json_ok(_get_run_state())
			"/scene":
				return _json_ok(_get_scene_tree())
			_:
				return _json_error(404, "Not found: %s" % path)

	if method == "POST":
		match path:
			"/input/move":
				return _handle_move_input(body)
			"/game/start":
				World.start_daily_run()
				return _json_ok({"action": "start_daily_run"})
			_:
				return _json_error(404, "Not found: %s" % path)

	return _json_error(405, "Method not allowed: %s" % method)


func _get_full_state() -> Dictionary:
	return {
		"run": _get_run_state(),
		"entities": _get_entities(),
	}


func _get_run_state() -> Dictionary:
	if not World.run_state:
		return {"is_active": false}
	return {
		"is_active": World.run_state.is_active,
		"current_floor": World.run_state.current_floor,
		"score": World.run_state.score,
		"turns_taken": World.run_state.turns_taken,
		"kills": World.run_state.kills,
		"daily_seed": World.run_state.daily_seed,
	}


func _get_entities() -> Dictionary:
	var result: Dictionary = {"player": null, "monsters": []}

	if not World.current_map:
		return result

	if World.player:
		var pos := World.current_map.find_monster_position(World.player)
		result.player = {
			"position": _v2i_dict(pos),
			"hp": World.player.hp,
			"max_hp": World.player.max_hp,
		}

	var monsters_arr: Array = []
	for monster: Monster in World.current_map.get_monsters():
		if monster == World.player:
			continue
		var pos := World.current_map.find_monster_position(monster)
		monsters_arr.append({
			"slug": str(monster.slug),
			"position": _v2i_dict(pos),
			"hp": monster.hp,
			"max_hp": monster.max_hp,
		})
	result.monsters = monsters_arr

	return result


func _handle_move_input(body: String) -> Dictionary:
	var json := JSON.new()
	var err := json.parse(body)
	if err != OK:
		return _json_error(400, "Invalid JSON: %s" % json.get_error_message())

	var data: Variant = json.data
	if not data is Dictionary or not data.has("direction"):
		return _json_error(400, "Missing 'direction' field")

	var dir_map: Dictionary = {
		"up": Vector2i.UP,
		"down": Vector2i.DOWN,
		"left": Vector2i.LEFT,
		"right": Vector2i.RIGHT,
	}

	var dir_str: String = str(data.direction).to_lower()
	if not dir_map.has(dir_str):
		return _json_error(400, "Invalid direction: %s" % dir_str)

	var action := PlayerAttackMoveAction.new(dir_map[dir_str])
	World.apply_player_action(action)
	return _json_ok({"action": "move", "direction": dir_str})


func _json_ok(data: Dictionary) -> Dictionary:
	return {"code": 200, "body": JSON.stringify(data)}


func _json_error(code: int, message: String) -> Dictionary:
	return {"code": code, "body": JSON.stringify({"error": message})}


func _send_response(peer: StreamPeerTCP, response: Dictionary) -> void:
	var code: int = response.get("code", 200)
	var body_text: String = response.get("body", "{}")
	var status_text := "OK" if code == 200 else "Error"

	var header := "HTTP/1.0 %d %s\r\n" % [code, status_text]
	header += "Content-Type: application/json\r\n"
	header += "Access-Control-Allow-Origin: *\r\n"
	header += "Content-Length: %d\r\n" % body_text.length()
	header += "Connection: close\r\n"
	header += "\r\n"

	peer.put_data((header + body_text).to_utf8_buffer())


func _v2i_dict(v: Vector2i) -> Dictionary:
	return {"x": v.x, "y": v.y}


func _get_scene_tree() -> Dictionary:
	var root := get_tree().current_scene
	if not root:
		return {"error": "No current scene"}
	return {"root": _serialize_node(root, 3)}


func _serialize_node(node: Node, max_depth: int) -> Dictionary:
	var data: Dictionary = {
		"name": node.name,
		"class": node.get_class(),
	}

	if node is Control:
		var ctrl := node as Control
		data["visible"] = ctrl.visible
		data["position"] = {"x": ctrl.global_position.x, "y": ctrl.global_position.y}
		data["size"] = {"w": ctrl.size.x, "h": ctrl.size.y}
		data["anchors"] = {
			"top": ctrl.anchor_top,
			"bottom": ctrl.anchor_bottom,
			"left": ctrl.anchor_left,
			"right": ctrl.anchor_right,
		}

	if node is Node2D:
		var n2d := node as Node2D
		data["visible"] = n2d.visible
		data["position"] = {"x": n2d.global_position.x, "y": n2d.global_position.y}

	if node is Button:
		data["text"] = (node as Button).text
	if node is Label:
		data["text"] = (node as Label).text
	if node is RichTextLabel:
		data["text"] = (node as RichTextLabel).text.substr(0, 120)

	if max_depth > 0 and node.get_child_count() > 0:
		var children_arr: Array = []
		for child: Node in node.get_children():
			children_arr.append(_serialize_node(child, max_depth - 1))
		data["children"] = children_arr

	return data
