extends Node2D
class_name Guest
## 客人状态机：入场 → 按偏好选席 → 落位（下水泡汤 / 榻榻米盘坐）产币 → 离店点评。
## 契合度与今日心愿共同决定产币速率与离店星级，星级回写声望。
## 茶室 kind=lounge：不沾水、坐着更久、投币更慢，与池子共用同一套状态机。

enum State { WALK_IN, STAY, LEAVE }

const SPEED := 52.0
const SOAK_MIN := 7.0
const SOAK_MAX := 13.0
## 落座没有水温赶人，一坐就是半天：停留更长、单拍更慢，吞吐随之下降
const REST_MIN := 13.0
const REST_MAX := 21.0
const COIN_INTERVAL := 2.0
const COIN_INTERVAL_REST := 3.0
const FOOT_PAD := 2.0
## 基准步幅：一脚步子迈过的地面距离，实际步幅再乘物种步态档位。
## 步频由它与实际速度共同决定，动画跟着位移走就不会滑步
const STEP_PX := 20.0
## 基准换帧序列：只换抬哪条腿，具体走哪几帧由步态档位给（跳步物种另有 hop 帧）
const STRIDE := ["stepL", "stepR"]

signal coin_earned(amount: int)
signal finished(guest: Node2D)
signal reviewed(guest: Node2D, stars: int, wish_id: String, wish_done: bool)
## 叙事取词的三个时刻：落位（看清池子的那一刻）、泡到一半、起身离店。
## 选哪句台词是 GameManager 的事，客人只管报时。
signal seated(guest: Node2D)
signal murmured(guest: Node2D)
signal leaving(guest: Node2D)

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
var lounge := false
var stay_left := 0.0
var stay_actual := 0.0
var stay_window := SOAK_MAX
var coin_every := COIN_INTERVAL
var coin_left := COIN_INTERVAL
var emote_left := 2.0
var bob_t := randf() * 6.0
## 走过的路程累计：脚步帧与身体沉浮都由它推出，而不是挂在不相关的时间上
var stride_px := 0.0
## 步态档位与按档位换算出的移速：步幅、换帧序列、落地沉浮、左右摆幅都取自这张表
var gait := {}
var walk_speed := SPEED
var _stepping_out := true
var _murmured := false
var _step_out_pos := Vector2.ZERO
var _walk_off := 0.0

var sprite: Sprite2D
var ripple: Sprite2D

func setup(p_species: String, p_yukata: Color, spawn: Vector2, p_slot: Dictionary, p_exit: Vector2) -> void:
	species = p_species
	var sp := GameData.species(p_species)
	guest_name = String(sp.names.pick_random())
	gait = GameData.gait_of(p_species)
	walk_speed = SPEED * float(gait.get("speed", 1.0))
	affinity = GameData.affinity(p_species, String(p_slot.get("type", "")))
	yukata = p_yukata
	slot = p_slot
	lounge = not bool(p_slot.get("water", true))
	coin_every = COIN_INTERVAL_REST if lounge else COIN_INTERVAL
	coin_left = coin_every
	wish_id = GameManager.pick_wish(String(p_slot.get("room", "")))
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
			_walk(delta, target, _take_seat)
		State.STAY:
			_stay(delta)
		State.LEAVE:
			if _stepping_out:
				_walk(delta, _step_out_pos, func() -> void: _stepping_out = false)
			else:
				_walk(delta, exit_pos, _depart)

func _walk(delta: float, to: Vector2, on_arrive: Callable) -> void:
	var d := to - position
	var step := walk_speed * delta
	var from := position
	if d.length() <= step:
		position = to
		_finish_walk()
		on_arrive.call()
		return
	position += d.normalized() * step
	z_index = int(position.y)
	# 不做左右镜像：正对镜头的角色一翻就换了浴衣的衽向、换了尾巴那一边、连左上光都翻到右上，
	# 玩家看到的不是「转身」而是「扭一下」。方向交给脚步与位移去说。
	stride_px += from.distance_to(position)
	var span := STEP_PX * float(gait.get("step", 1.0))
	var n := int(stride_px / span)
	var phase := fmod(stride_px, span) / span
	var frames: Array = gait.get("frames", STRIDE)
	var pose := String(frames[n % frames.size()])
	_set_pose(pose)
	sprite.offset = Vector2(_sway(n), _walk_off + _bob(pose, phase))

## 竖直方向只有一格活动空间：落脚那一下沉一格，撑腿的其余时间回到地面线。
## 走路时只往下不往上——整张图抬起来会把撑地的那只脚一起带离地面，看着像在飘着走。
## 跳步物种反过来：腾空帧两脚在画里已经收起来，这时整只离地才是对的。
func _bob(pose: String, phase: float) -> float:
	if pose == "hop":
		return -float(gait.get("air", 0.0)) if phase > 0.2 else 0.0
	if phase < float(gait.get("dip_t", 0.28)):
		return float(gait.get("dip", 0.0))
	return 0.0

## 摇摆：身子随两脚交替左右倒，只有蹼禽与海豹那一档给非零值
func _sway(n: int) -> float:
	var s := float(gait.get("sway", 0.0))
	return s if n % 2 == 0 else -s

## 走完一段：回到两脚着地的中立帧，落座与泡水都从这个姿势接
func _finish_walk() -> void:
	stride_px = 0.0
	_set_pose("walk")
	sprite.offset = Vector2(0, _walk_off)

func _set_pose(pose: String) -> void:
	var tex := _tex(species, yukata, pose)
	if sprite.texture != tex:
		sprite.texture = tex

## 落位：下水的换泡汤姿态并浮起水波，茶室的盘坐到坐垫上
func _take_seat() -> void:
	state = State.STAY
	stay_window = REST_MAX if lounge else SOAK_MAX
	stay_left = randf_range(REST_MIN if lounge else SOAK_MIN, stay_window)
	position = slot.pos
	z_index = int(slot.water_y)
	if lounge:
		_set_rest_pose()
	else:
		_set_soak_pose()
	seated.emit(self)

func _set_soak_pose() -> void:
	sprite.texture = _tex(species, yukata, "soak")
	# 泡汤图的水线在画布底部，直接让底边贴住节点 y
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	ripple = Sprite2D.new()
	ripple.texture = ImageTexture.create_from_image(PixelArt.make_ripple(30))
	ripple.scale = Vector2(2, 2)
	ripple.position = Vector2(0, 2)
	ripple.z_index = -1
	add_child(ripple)

## 落座图与行走图同尺寸：脚掌换成坐垫后仍贴着同一条地面线，锚点照用行走那套
func _set_rest_pose() -> void:
	sprite.texture = _tex(species, yukata, "rest")
	_walk_off = FOOT_PAD - sprite.texture.get_height() * 0.5
	sprite.offset = Vector2(0, _walk_off)

func _stay(delta: float) -> void:
	bob_t += delta * (0.9 if lounge else 3.0)
	stay_left -= delta
	stay_actual += delta
	if lounge:
		# 坐着不动会像贴图，让身子随呼吸一涨一落
		sprite.offset = Vector2(0, _walk_off + round(sin(bob_t)))
	elif ripple:
		ripple.modulate.a = 0.65 + 0.35 * sin(bob_t)
	coin_left -= delta
	if coin_left <= 0.0:
		coin_left = coin_every
		_earn()
	emote_left -= delta
	if emote_left <= 0.0:
		emote_left = randf_range(2.5, 4.5)
		_spawn_emote()
	if not _murmured and stay_actual >= stay_window * 0.3:
		_murmured = true
		murmured.emit(self)
	if stay_left <= 0.0:
		state = State.LEAVE
		_stepping_out = true
		_step_out_pos = slot.pos + Vector2(0, 30)
		wish_done = _evaluate_wish()
		leaving.emit(self)
		if ripple:
			ripple.queue_free()
		_finish_walk()

## 应得产币：物种小费为基数，契合度、席位等级、房间设施、心愿共同加成，再乘时段倍率
func _stay_income() -> int:
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
	var granted := GameManager.take_pool_budget(String(slot.get("type", "")), _stay_income(),
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
		"snack", "photo", "tea", "nap":
			return true
	return false

func star_rating() -> int:
	var s := 2 + affinity
	if wish_done:
		s += 1
	if stay_actual >= stay_window * 0.8:
		s += 1
	return clampi(s, 1, 5)

## 情绪特效：池子里是冒出来的心心，茶室是茶碗上升起的一缕热气
func _spawn_emote() -> void:
	var emote := Sprite2D.new()
	emote.scale = Vector2(2, 2)
	emote.z_index = 1
	add_child(emote)
	if lounge:
		emote.texture = ImageTexture.create_from_image(PixelArt.make_steam_puff())
		emote.position = Vector2(2, -22)
		var tw := create_tween()
		tw.tween_property(emote, "position:y", -34.0, 1.1)
		tw.parallel().tween_property(emote, "modulate:a", 0.0, 1.1)
		tw.tween_callback(emote.queue_free)
		return
	emote.texture = ImageTexture.create_from_image(PixelArt.make_heart())
	emote.position = Vector2(0, -34)
	var tween := create_tween()
	tween.tween_property(emote, "position:y", -46.0, 0.7)
	tween.parallel().tween_property(emote, "modulate:a", 0.0, 0.7)
	tween.tween_callback(emote.queue_free)

func _depart() -> void:
	reviewed.emit(self, star_rating(), wish_id, wish_done)
	finished.emit(self)
	queue_free()
