class_name V06TravelCardCatalog
extends RefCounted

const CATEGORY_ALL := "ALL"
const CATEGORY_ITEM := "ITEM"
const CATEGORY_EVENT := "EVENT"
const CATEGORY_BOSS := "BOSS"
const CATEGORY_MEMORY := "MEMORY"

const ITEM_COMPASS: Texture2D = preload("res://assets/art/items/cairo/cairo-item-brass-compass.png")
const ITEM_SCARAB: Texture2D = preload("res://assets/art/items/cairo/cairo-item-scarab-seal.png")
const ITEM_CANTEEN: Texture2D = preload("res://assets/art/items/cairo/cairo-item-water-canteen.png")
const EVENT_FERRY: Texture2D = preload("res://assets/art/events/cairo/cairo-event-ferry-offer.png")
const EVENT_MARKET: Texture2D = preload("res://assets/art/events/cairo/cairo-event-market-hawker.png")
const EVENT_NILE: Texture2D = preload("res://assets/art/events/cairo/cairo-event-nile-tailwind.png")
const EVENT_RUIN: Texture2D = preload("res://assets/art/events/cairo/cairo-event-ruin-whisper.png")
const BOSS_SPHINX: Texture2D = preload("res://assets/art/bosses/cairo/cairo-boss-start.png")
const MEMORY_CAIRO: Texture2D = preload("res://assets/art/postcards/cairo/cairo-journey-postcard.png")


static func definitions() -> Array[Dictionary]:
	return [
		{
			"id": "item:water_canteen",
			"category": CATEGORY_ITEM,
			"title": "旅人の水筒",
			"effect": "♥ +1",
			"source": "ITEMマス",
			"description": "乾いた旅の途中で、ハートを1回復する。ハートが満タンのときは使わずに取っておける。",
			"art": ITEM_CANTEEN,
		},
		{
			"id": "item:brass_compass",
			"category": CATEGORY_ITEM,
			"title": "真鍮のコンパス",
			"effect": "次の移動 +1",
			"source": "ITEMマス",
			"description": "次に止めたサイコロへ1マスを足す。あと少しで届く回復やイベントを狙いたいときに役立つ。",
			"art": ITEM_COMPASS,
		},
		{
			"id": "item:scarab_seal",
			"category": CATEGORY_ITEM,
			"title": "スカラベの護符",
			"effect": "RISK ×0",
			"source": "ITEMマス",
			"description": "次に止まったRISKの効果を1回だけ無効にする。危険な近道へ入る前に使うと安心。",
			"art": ITEM_SCARAB,
		},
		{
			"id": "event:market_hawker",
			"category": CATEGORY_EVENT,
			"title": "市場の呼び込み",
			"effect": "コイン2 → 次の移動 +2",
			"source": "市場のEVENTマス",
			"description": "きらめく品を掲げた呼び込みが、にぎやかに声をかけてくる。コインを払うと近道の地図を確認できる。",
			"art": EVENT_MARKET,
		},
		{
			"id": "event:nile_tailwind",
			"category": CATEGORY_EVENT,
			"title": "ナイルの追い風",
			"effect": "コイン3 → 次の移動 +4",
			"source": "オアシスのEVENTマス",
			"description": "ナイルの帆が大きくふくらみ、心地よい追い風が旅人を包む。ラクダを雇えば次の一歩が大きく伸びる。",
			"art": EVENT_NILE,
		},
		{
			"id": "event:ruin_whisper",
			"category": CATEGORY_EVENT,
			"title": "遺跡のささやき",
			"effect": "コイン2 → 次のRISK ×0",
			"source": "遺跡のEVENTマス",
			"description": "壁画からほどけた青い光が、砂時計の秘密をささやく。ガイドを頼むと次のRISKを安全に越えられる。",
			"art": EVENT_RUIN,
		},
		{
			"id": "event:ferry_offer",
			"category": CATEGORY_EVENT,
			"title": "渡し船の客引き",
			"effect": "コイン3 → 次の移動 +4",
			"source": "ナイルのEVENTマス",
			"description": "陽気な船頭がナイルを渡る舟へ招いてくる。渡し舟を選ぶと次の移動が大きく伸びる。",
			"art": EVENT_FERRY,
		},
		{
			"id": "boss:sleepy_sphinx",
			"category": CATEGORY_BOSS,
			"title": "眠そうなスフィンクス",
			"effect": "鏡面レース  ·  x と 7−x",
			"source": "カイロのゴール",
			"description": "あなたの出目をxとすると、スフィンクスは反対面の7−xで進む。3投のPAIR・STRAIGHT・TRIPLEがレースを有利にする。",
			"art": BOSS_SPHINX,
		},
		{
			"id": "memory:cairo_journey_complete",
			"category": CATEGORY_MEMORY,
			"title": "砂時計のカイロ",
			"effect": "JOURNEY COMPLETE",
			"source": "ボスレース勝利",
			"description": "眠そうなスフィンクスとゴールを越えた、カイロの旅の記念。",
			"art": MEMORY_CAIRO,
		},
		{
			"id": "memory:cairo_spice_market_complete",
			"category": CATEGORY_MEMORY,
			"title": "香辛料市場の一日",
			"effect": "MARKET MEMORY",
			"source": "市場の発展記録",
			"description": "香辛料市場の発展を最後まで見届けた旅の記録。",
			"art": MEMORY_CAIRO,
		},
	]


static func definition(card_id: String) -> Dictionary:
	for entry: Dictionary in definitions():
		if str(entry.get("id", "")) == card_id:
			return entry
	return {}


static func valid_id(card_id: String) -> bool:
	return not definition(card_id).is_empty()


static func category_label(category: String) -> String:
	match category:
		CATEGORY_ITEM: return "アイテム"
		CATEGORY_EVENT: return "イベント"
		CATEGORY_BOSS: return "ボス"
		CATEGORY_MEMORY: return "旅の記念"
		_: return "すべて"
