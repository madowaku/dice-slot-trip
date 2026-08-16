class_name StageCatalog
extends RefCounted

const STAGE_CAIRO: StringName = &"cairo_hourglass"
const STAGE_AMAZON: StringName = &"amazon_suiu_falls"
const STAGE_KYOTO: StringName = &"kyoto_thousand_year_grid"

const DEFINITIONS: Dictionary = {
	STAGE_CAIRO: {
		"title": "砂時計のカイロ",
		"card_title": "砂時計のカイロ",
		"description": "市場、オアシス、遺跡をめぐる、ゆったり一周の旅。",
		"route": "90マス",
		"boss_label": "周回ボス：眠そうなスフィンクス",
		"unlocked": true,
		"scene": "cairo",
	},
	STAGE_AMAZON: {
		"title": "翠雨の大瀑布",
		"card_title": "翠雨の大瀑布",
		"description": "二度の分岐と激流を読み、滝裏の秘密まで探す120マスの冒険。",
		"route": "120マス・分岐探索",
		"boss_label": "試練の守護者：瀑竜アクアフォール",
		"unlocked": true,
		"scene": "amazon",
	},
	STAGE_KYOTO: {
		"title": "千年碁盤の京都",
		"card_title": "千年碁盤の京都",
		"description": "急げば近道、巡ればご利益。京都の一日を旅して御朱印を集める。",
		"route": "90マス・辻と御朱印",
		"boss_label": "碁盤守：白狐",
		"unlocked": true,
		"scene": "kyoto",
	},
}


static func has_stage(stage_id: StringName) -> bool:
	return DEFINITIONS.has(stage_id)


static func definition(stage_id: StringName) -> Dictionary:
	return (DEFINITIONS.get(stage_id, DEFINITIONS[STAGE_CAIRO]) as Dictionary).duplicate(true)


static func is_unlocked(stage_id: StringName) -> bool:
	return bool(definition(stage_id).get("unlocked", false))


static func scene_kind(stage_id: StringName) -> String:
	return str(definition(stage_id).get("scene", "cairo"))

