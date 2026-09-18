extends Node2D
class_name Guest
## 客人状态机：入场 → 按偏好选池 → 入池泡澡产币 → 离店点评。
## 契合度与今日心愿共同决定产币速率与离店星级，星级回写声望。

enum State { WALK_IN, SOAK, LEAVE }

const SPEED := 52.0
const SOAK_MIN := 7.0
const SOAK_MAX := 13.0
const COIN_INTERVAL := 2.0
const FOOT_PAD := 2.0

signal coin_earned(amount: int)
signal finished(guest: Node2D)
signal reviewed(guest: Node2D, stars: int, wish_id: String, wish_done: bool)

static var _tex_cache := {}

var state := State.WALK_IN
var species := "shib"
var guest_name := "旺财"
var yukata := Color.WHITE
var wish_id := "photo"
var wish_done := false
var affinity := 0
var slot := {}
var target := Vector2.ZERO
var exit_pos := Vector2.ZERO
var soak_left := 0.0
var soak_actual := 0.0
var coin_left := COIN_INTERVAL
var heart_left := 2.0
var bob_t := randf() * 6.0
var _stepping_out := true
var _step_out_pos := Vector2.ZERO
var _walk_off := 0.0

var sprite: Sprite2D
var ripple: Sprite2D

func setup(p_species: String, p_yukata: Color, spawn: Vector2, p_slot: Dictionary, p_exit: Vector2) -> void:
	species = p_species
	var sp := GameData.species(p_species)
	guest_name = String(sp.names.pick_random())
	wish_id = String(GameData.WISHES.keys().pick_random())
	affinity = GameData.affinity(p_species, String(p_slot.get("type", "")))
	yukata = p_yukata
	slot = p_slot
	exit_pos = p_exit
	position = spawn
	target = slot.pos + Vector2(0, -4)
	sprite = Sprite2D.new()
	sprite.texture = _tex(species, yukata, "walk")
	sprite.scale = Vector2(2, 2)
	# 底部中心锚定：脚掌落在节点位置上方 FOOT_PAD 像素，体型不同也不会浮空或陷地
	_walk_off = FOOT_PAD - sprite.texture.get_height() * 0.5
	sprite.offset = Vector2(0, _walk_off)
	add_child(sprite)
	z_index = int(position.y)
	add_to_group("guests")

static func _tex(sp: String, yk: Color, pose: String) -> Texture2D:
	var key := "%s|%s|%s" % [sp, yk.to_html(), pose]
	if not _tex_cache.has(key):
		_tex_cache[key] = ImageTexture.create_from_image(PixelArt.make_animal(sp, yk, pose))
	return _tex_cache[key]

func state_name() -> String:
	return State.keys()[state]

func _process(delta: float) -> void:
	match state:
		State.WALK_IN:
			_walk(delta, target, _arrive_pool)
		State.SOAK:
			_soak(delta)
		State.LEAVE:
			if _stepping_out:
				_walk(delta, _step_out_pos, func() -> void: _stepping_out = false)
			else:
				_walk(delta, exit_pos, _depart)

func _walk(delta: float, to: Vector2, on_arrive: Callable) -> void:
	var d := to - position
	var step := SPEED * delta
	bob_t += delta * 9.0
	sprite.offset = Vector2(0, _walk_off + round(sin(bob_t)))
	sprite.flip_h = d.x < 0.0
	if d.length() <= step:
		position = to
		on_arrive.call()
	else:
		position += d.normalized() * step
		z_index = int(position.y)

func _arrive_pool() -> void:
	state = State.SOAK
	soak_left = randf_range(SOAK_MIN, SOAK_MAX)
	position = slot.pos
	z_index = int(slot.water_y)
	if slot.get("water", true):
		_set_soak_pose()

func _set_soak_pose() -> void:
	sprite.texture = _tex(species, yukata, "soak")
	sprite.flip_h = false
	# 泡汤图的水线在画布底部，直接让底边贴住节点 y
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	ripple = Sprite2D.new()
	ripple.texture = ImageTexture.create_from_image(PixelArt.make_ripple(20))
	ripple.scale = Vector2(2, 2)
	ripple.position = Vector2(0, 2)
	ripple.z_index = -1
	add_child(ripple)

func _soak(delta: float) -> void:
	bob_t += delta * 3.0
	soak_left -= delta
	soak_actual += delta
	if ripple:
		ripple.modulate.a = 0.65 + 0.35 * sin(bob_t)
	coin_left -= delta
	if coin_left <= 0.0:
		coin_left = COIN_INTERVAL
		_earn()
	heart_left -= delta
	if heart_left <= 0.0:
		heart_left = randf_range(2.5, 4.5)
		_spawn_heart()
	if soak_left <= 0.0:
		state = State.LEAVE
		_stepping_out = true
		_step_out_pos = slot.pos + Vector2(0, 30)
		wish_done = _evaluate_wish()
		if ripple:
			ripple.queue_free()
		sprite.texture = _tex(species, yukata, "walk")
		sprite.offset = Vector2(0, _walk_off)

## 应得产币：物种小费为基数，契合度、池位等级、房间设施、心愿共同加成，再乘时段倍率
func _soak_income() -> int:
	var pay := float(GameData.species(species).get("pay", 12))
	var room_id := String(slot.get("room", ""))
	var mult := GameManager.income_mult() * (1.0 + 0.35 * affinity)
	mult *= GameManager.pool_income_mult(room_id, int(slot.get("pool", 0)))
	mult *= GameManager.facility_bonus(room_id)
	if wish_done:
		mult *= 1.25
	return maxi(1, int(round(pay / 6.0 * mult)))

## 产币池有单日上限，额度用完的这一拍就不再进账
func _earn() -> void:
	var granted := GameManager.take_pool_budget(String(slot.get("type", "")), _soak_income(),
			String(slot.get("room", "")), int(slot.get("pool", 0)))
	if granted > 0:
		coin_earned.emit(granted)

func _evaluate_wish() -> bool:
	var room_id := String(slot.get("room", ""))
	for need: String in GameData.wish_needs(wish_id):
		if not GameManager.has_facility(room_id, need):
			return false
	var fn: Callable = slot.get("peers", Callable())
	var peers: int = int(fn.call(self)) if fn.is_valid() else 0
	match wish_id:
		"alone":
			return peers == 0
		"chat":
			return peers >= 2
		"snack", "photo", "nap":
			return true
	return false

func star_rating() -> int:
	var s := 2 + affinity
	if wish_done:
		s += 1
	if soak_actual >= SOAK_MAX * 0.8:
		s += 1
	return clampi(s, 1, 5)

func _spawn_heart() -> void:
	var heart := Sprite2D.new()
	heart.texture = ImageTexture.create_from_image(PixelArt.make_heart())
	heart.scale = Vector2(2, 2)
	heart.position = Vector2(0, -34)
	heart.z_index = 1
	add_child(heart)
	var tween := create_tween()
	tween.tween_property(heart, "position:y", -46.0, 0.7)
	tween.parallel().tween_property(heart, "modulate:a", 0.0, 0.7)
	tween.tween_callback(heart.queue_free)

func _depart() -> void:
	reviewed.emit(self, star_rating(), wish_id, wish_done)
	finished.emit(self)
	queue_free()
