extends Node

var _entitlements: Dictionary = {}  # Dictionary[String, bool]


func _ready() -> void:
	_init_revenuecat()


func _init_revenuecat() -> void:
	if not Engine.has_singleton("RevenueCat"):
		push_warning("[PurchaseManager] RevenueCat not available, purchases disabled")
		return
	var rc: Object = Engine.get_singleton("RevenueCat")
	if rc.has_method("configure"):
		# API keys configured per platform
		var api_key := ""
		if OS.get_name() == "Android":
			api_key = OS.get_environment("REVENUECAT_ANDROID_KEY")
		elif OS.get_name() == "iOS":
			api_key = OS.get_environment("REVENUECAT_IOS_KEY")
		if not api_key.is_empty():
			rc.call("configure", api_key)


func has_entitlement(entitlement_id: String) -> bool:
	return _entitlements.get(entitlement_id, false)


func purchase(product_id: String, callback: Callable = Callable()) -> void:
	if not Engine.has_singleton("RevenueCat"):
		push_warning("[PurchaseManager] Cannot purchase: RevenueCat unavailable")
		if callback.is_valid():
			callback.call(false)
		return

	var rc: Object = Engine.get_singleton("RevenueCat")
	if rc.has_method("purchase"):
		rc.call("purchase", product_id)
		# In production, await callback from RC SDK
		if callback.is_valid():
			callback.call(true)


func restore_purchases(callback: Callable = Callable()) -> void:
	if not Engine.has_singleton("RevenueCat"):
		if callback.is_valid():
			callback.call(false)
		return

	var rc: Object = Engine.get_singleton("RevenueCat")
	if rc.has_method("restorePurchases"):
		rc.call("restorePurchases")
		if callback.is_valid():
			callback.call(true)


func refresh_entitlements() -> void:
	if not Engine.has_singleton("RevenueCat"):
		return
	var rc: Object = Engine.get_singleton("RevenueCat")
	if rc.has_method("getCustomerInfo"):
		rc.call("getCustomerInfo")
