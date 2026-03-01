extends Node

var _ad_loaded: bool = false
var _rewarded_callback: Callable = Callable()


func _ready() -> void:
	_init_admob()


func _init_admob() -> void:
	if not Engine.has_singleton("AdMob"):
		push_warning("[AdManager] AdMob not available, ads disabled")
		return
	var admob: Object = Engine.get_singleton("AdMob")
	if admob.has_method("initialize"):
		admob.call("initialize")
	_preload_rewarded()


func _preload_rewarded() -> void:
	if not Engine.has_singleton("AdMob"):
		return
	var admob: Object = Engine.get_singleton("AdMob")
	if admob.has_method("loadRewardedAd"):
		admob.call("loadRewardedAd")
		_ad_loaded = true


func is_ad_free() -> bool:
	if has_node("/root/PurchaseManager"):
		var pm: Node = get_node("/root/PurchaseManager")
		if pm.has_method("has_entitlement"):
			return pm.has_entitlement(EntitlementData.AD_FREE)
	return false


func show_rewarded_ad(callback: Callable) -> void:
	if is_ad_free():
		callback.call(true)
		return

	if not Engine.has_singleton("AdMob") or not _ad_loaded:
		push_warning("[AdManager] No rewarded ad available")
		callback.call(false)
		return

	_rewarded_callback = callback
	var admob: Object = Engine.get_singleton("AdMob")
	if admob.has_method("showRewardedAd"):
		admob.call("showRewardedAd")


func _on_rewarded_ad_completed() -> void:
	_ad_loaded = false
	if _rewarded_callback.is_valid():
		_rewarded_callback.call(true)
		_rewarded_callback = Callable()
	_preload_rewarded()


func _on_rewarded_ad_failed() -> void:
	if _rewarded_callback.is_valid():
		_rewarded_callback.call(false)
		_rewarded_callback = Callable()
