extends Node

var _config: FirebaseConfig
var _http: HTTPRequest
var _id_token: String = ""
var _uid: String = ""
var _authenticated: bool = false


func _ready() -> void:
	_config = FirebaseConfig.load_config()
	_http = HTTPRequest.new()
	add_child(_http)


# --- Authentication ---

func authenticate_anonymous(callback: Callable = Callable()) -> void:
	if not _config.is_configured():
		push_warning("[BackendService] Firebase not configured, using local mode")
		if callback.is_valid():
			callback.call(false)
		return

	var url := "%s/accounts:signUp?key=%s" % [_config._auth_url, _config.api_key]
	var body := JSON.stringify({"returnSecureToken": true})
	var headers := ["Content-Type: application/json"]

	var req := HTTPRequest.new()
	add_child(req)
	req.request(url, headers, HTTPClient.METHOD_POST, body)
	var result: Array = await req.request_completed
	req.queue_free()

	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code == 200:
		var json := JSON.new()
		json.parse(response_body.get_string_from_utf8())
		var data: Dictionary = json.data
		_id_token = data.get("idToken", "")
		_uid = data.get("localId", "")
		_authenticated = true
		World.auth_completed.emit(_uid)
	else:
		push_error("[BackendService] Auth failed: %d" % response_code)

	if callback.is_valid():
		callback.call(_authenticated)


func is_authenticated() -> bool:
	return _authenticated


# --- Daily Seed ---

func fetch_daily_seed() -> int:
	if not _config.is_configured():
		return SeedFactory.daily_seed()

	var today := _get_today_str()
	var url := "%s/daily_seeds/%s" % [_config._firestore_url, today]
	var headers := _auth_headers()

	var req := HTTPRequest.new()
	add_child(req)
	req.request(url, headers, HTTPClient.METHOD_GET)
	var result: Array = await req.request_completed
	req.queue_free()

	var response_code: int = result[1]
	if response_code != 200:
		return SeedFactory.daily_seed()

	var json := JSON.new()
	json.parse((result[3] as PackedByteArray).get_string_from_utf8())
	var data: Dictionary = json.data
	var fields: Dictionary = data.get("fields", {})
	var seed_field: Dictionary = fields.get("seed", {})
	return seed_field.get("integerValue", str(SeedFactory.daily_seed())).to_int()


# --- Score Submission ---

func submit_score(score: int, seed_value: int, run_data: Dictionary = {}) -> bool:
	if not _config.is_configured():
		print("[BackendService] Score submitted locally: %d (seed: %d)" % [score, seed_value])
		return true

	var url := "%s/scores" % _config._firestore_url
	var headers := _auth_headers()
	headers.append("Content-Type: application/json")

	var today := _get_today_str()
	var body := JSON.stringify({
		"fields": {
			"uid": {"stringValue": _uid},
			"score": {"integerValue": str(score)},
			"seed": {"integerValue": str(seed_value)},
			"date": {"stringValue": today},
			"floor": {"integerValue": str(run_data.get("floor", 0))},
			"turns": {"integerValue": str(run_data.get("turns", 0))},
			"kills": {"integerValue": str(run_data.get("kills", 0))},
			"class": {"stringValue": run_data.get("class", "warrior")},
			"hash": {"stringValue": run_data.get("hash", "")},
		}
	})

	var req := HTTPRequest.new()
	add_child(req)
	req.request(url, headers, HTTPClient.METHOD_POST, body)
	var result: Array = await req.request_completed
	req.queue_free()

	return (result[1] as int) == 200


# --- Leaderboard ---

func fetch_leaderboard(leaderboard_type: String = "daily") -> Array[LeaderboardEntry]:
	var entries: Array[LeaderboardEntry] = []

	if not _config.is_configured():
		return entries

	var today := _get_today_str()
	var url := "%s:runQuery" % _config._firestore_url.replace("/documents", "")
	var headers := _auth_headers()
	headers.append("Content-Type: application/json")

	var query := {
		"structuredQuery": {
			"from": [{"collectionId": "scores"}],
			"where": {
				"fieldFilter": {
					"field": {"fieldPath": "date"},
					"op": "EQUAL",
					"value": {"stringValue": today},
				}
			},
			"orderBy": [{"field": {"fieldPath": "score"}, "direction": "DESCENDING"}],
			"limit": 100,
		}
	}

	var req := HTTPRequest.new()
	add_child(req)
	req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(query))
	var result: Array = await req.request_completed
	req.queue_free()

	if (result[1] as int) != 200:
		return entries

	var json := JSON.new()
	json.parse((result[3] as PackedByteArray).get_string_from_utf8())
	var results_arr: Array = json.data if json.data is Array else []

	var rank := 1
	for item: Variant in results_arr:
		if item is Dictionary and item.has("document"):
			var fields: Dictionary = item.document.get("fields", {})
			var entry := LeaderboardEntry.from_dict({
				"rank": rank,
				"name": _extract_string(fields, "uid", "Anonymous"),
				"score": _extract_int(fields, "score"),
				"floor": _extract_int(fields, "floor"),
				"turns": _extract_int(fields, "turns"),
				"kills": _extract_int(fields, "kills"),
				"class": _extract_string(fields, "class", "warrior"),
			})
			entries.append(entry)
			rank += 1

	return entries


func fetch_player_rank(score: int) -> int:
	if not _config.is_configured():
		return -1

	var today := _get_today_str()
	var url := "%s:runQuery" % _config._firestore_url.replace("/documents", "")
	var headers := _auth_headers()
	headers.append("Content-Type: application/json")

	var query := {
		"structuredQuery": {
			"from": [{"collectionId": "scores"}],
			"where": {
				"compositeFilter": {
					"op": "AND",
					"filters": [
						{"fieldFilter": {"field": {"fieldPath": "date"}, "op": "EQUAL", "value": {"stringValue": today}}},
						{"fieldFilter": {"field": {"fieldPath": "score"}, "op": "GREATER_THAN", "value": {"integerValue": str(score)}}},
					]
				}
			},
			"select": {"fields": [{"fieldPath": "score"}]},
		}
	}

	var req := HTTPRequest.new()
	add_child(req)
	req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(query))
	var result: Array = await req.request_completed
	req.queue_free()

	if (result[1] as int) != 200:
		return -1

	var json := JSON.new()
	json.parse((result[3] as PackedByteArray).get_string_from_utf8())
	var results_arr: Array = json.data if json.data is Array else []
	return results_arr.size() + 1


# --- Profile Sync ---

func sync_profile(profile: PlayerProfile) -> void:
	if not _config.is_configured() or _uid.is_empty():
		return

	var url := "%s/player_profiles/%s" % [_config._firestore_url, _uid]
	var headers := _auth_headers()
	headers.append("Content-Type: application/json")

	var body := JSON.stringify({
		"fields": {
			"streak": {"integerValue": str(profile.streak_days)},
			"best_score": {"integerValue": str(profile.best_score)},
			"total_runs": {"integerValue": str(profile.total_runs)},
			"gems": {"integerValue": str(profile.gem_balance)},
		}
	})

	var req := HTTPRequest.new()
	add_child(req)
	req.request(url, headers, HTTPClient.METHOD_PATCH, body)
	await req.request_completed
	req.queue_free()


# --- Helpers ---

func _auth_headers() -> Array:
	var headers: Array = []
	if not _id_token.is_empty():
		headers.append("Authorization: Bearer %s" % _id_token)
	return headers


func _get_today_str() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [now.year, now.month, now.day]


static func _extract_string(fields: Dictionary, key: String, fallback: String = "") -> String:
	var field: Dictionary = fields.get(key, {})
	return field.get("stringValue", fallback)


static func _extract_int(fields: Dictionary, key: String, fallback: int = 0) -> int:
	var field: Dictionary = fields.get(key, {})
	return str(field.get("integerValue", str(fallback))).to_int()
