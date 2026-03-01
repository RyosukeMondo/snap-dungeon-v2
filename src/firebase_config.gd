class_name FirebaseConfig
extends RefCounted


var api_key: String = ""
var project_id: String = ""
var auth_domain: String = ""

var _firestore_url: String:
	get:
		return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % project_id

var _auth_url: String:
	get:
		return "https://identitytoolkit.googleapis.com/v1"


static func load_config() -> FirebaseConfig:
	var config := FirebaseConfig.new()

	# Try environment variables first
	var env_key := OS.get_environment("FIREBASE_API_KEY")
	if not env_key.is_empty():
		config.api_key = env_key
		config.project_id = OS.get_environment("FIREBASE_PROJECT_ID")
		config.auth_domain = OS.get_environment("FIREBASE_AUTH_DOMAIN")
		return config

	# Try encrypted resource
	var res_path := "res://firebase_config.tres"
	if ResourceLoader.exists(res_path):
		var res := ResourceLoader.load(res_path)
		if res and res.has_method("get_meta"):
			config.api_key = res.get_meta("api_key", "")
			config.project_id = res.get_meta("project_id", "")
			config.auth_domain = res.get_meta("auth_domain", "")
		return config

	return config


func is_configured() -> bool:
	return not api_key.is_empty() and not project_id.is_empty()
