class_name EntitlementData
extends RefCounted


const BATTLE_PASS := "battle_pass"
const AD_FREE := "ad_free"
const STARTER_PACK := "starter_pack"

const PRODUCT_IDS := {
	BATTLE_PASS: "com.snapdungeon.battlepass",
	AD_FREE: "com.snapdungeon.adfree",
	STARTER_PACK: "com.snapdungeon.starterpack",
}


static func all_entitlements() -> PackedStringArray:
	return PackedStringArray([BATTLE_PASS, AD_FREE, STARTER_PACK])
