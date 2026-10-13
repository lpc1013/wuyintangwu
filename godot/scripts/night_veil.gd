class_name NightVeil
extends CanvasLayer
## 入夜后压在画面上的一层蓝，和被它压下去之后重新点起的三处暖光：
## 背景里本来就画好的灯笼、玩家挂上墙的纸灯笼、汤面自己泛起来的那层。
## 光全排在夜罩之后，ADD 混合只加亮不遮挡，等于在被染蓝的画面上重新点火。
## 这一层只管画：不认识 ROOMS 表，也不读时钟——调用方每帧把「夜有多深」交进来。

const TINT := Color(0.06, 0.08, 0.22)
## 夜罩把画面压蓝，暖光再把它焐回来：同一张径向衰减贴图，靠 modulate 分色
const LAMP_COLOR := Color(1.0, 0.74, 0.4)
const WATER_COLOR := Color(0.46, 0.8, 0.95)
## 背景里那几盏灯笼只有十几像素宽，光晕再放一圈就要把整盏灯糊成白斑
const LAMP_SCALE := 2.0
const LANTERN_SCALE := 1.7
## 灯光峰值不拉满：ADD 混合下 1.0 直接过曝，留出余量让火苗的抖动看得见
const LAMP_ALPHA := 0.62
const WATER_ALPHA := 0.24
## 纸灯笼里的火苗不该是死的：整幅光按正弦轻轻抖，幅度小到不抢戏
const FLICKER_AMPLITUDE := 0.09
const FLICKER_SPEED := 3.4
## 夜罩最深只压到 0.78：深夜若只暗下一成五，看着就像黄昏而不是夜
const TINT_ALPHA := 0.78
## 光比天色提前 1.6 倍拉满，免得天黑透了灯还只有一半力气；白天夜色为 0，光就彻底熄干净
const GLOW_RAMP := 1.6

var rect: ColorRect
var lamp_glows: Array[Sprite2D] = []
var lantern_glows: Array[Sprite2D] = []
var water_glows: Array[Sprite2D] = []
var _glow_mat: CanvasItemMaterial
var _time := 0.0

## lights: 背景画好的灯心坐标；water_rects: 要泛光的池面矩形，茶室交空数组就一片都不泛
func build(lights: Array, water_rects: Array) -> void:
	layer = 5
	rect = ColorRect.new()
	rect.size = GameRules.VIEWPORT_SIZE
	rect.color = Color(TINT, 0.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	for i in lights.size():
		var g := _glow(Vector2(lights[i]), LAMP_SCALE, LAMP_COLOR)
		g.set_meta("ph", float(i) * 1.7)
		lamp_glows.append(g)
	var d := float(PixelArt.GLOW_SIZE)
	for i in water_rects.size():
		var pool: Rect2 = water_rects[i]
		var w := _glow(pool.get_center(), 1.0, WATER_COLOR)
		w.scale = Vector2(pool.size.x / d * 1.1, pool.size.y / d * 1.9)
		w.set_meta("ph", float(i) * 2.1)
		water_glows.append(w)

## 玩家挂的灯笼也要亮。增删之后整批重建：上限才 8 盏，
## 比让一串光与一堆设施精灵永远对齐要省心。
## 光心位置由调用方算好交进来——这一层不该知道「lantern」这个设施 id。
func sync_lanterns(spots: Array) -> void:
	for g: Sprite2D in lantern_glows:
		if is_instance_valid(g):
			g.queue_free()
	lantern_glows.clear()
	for i in spots.size():
		var g := _glow(Vector2(spots[i]), LANTERN_SCALE, LAMP_COLOR)
		g.set_meta("ph", float(i) * 2.3)
		lantern_glows.append(g)

func update_night(light: float, delta: float) -> void:
	rect.color = Color(TINT, light * TINT_ALPHA)
	_time += delta
	var base := clampf(light * GLOW_RAMP, 0.0, 1.0)
	for g: Sprite2D in lamp_glows:
		_flicker(g, base)
	for g: Sprite2D in lantern_glows:
		_flicker(g, base)
	for g: Sprite2D in water_glows:
		var breathe := 1.0 + 0.18 * sin(_time * 0.9 + float(g.get_meta("ph")))
		g.modulate.a = clampf(base * WATER_ALPHA * breathe, 0.0, 1.0)

func _glow(pos: Vector2, scl: float, tint: Color) -> Sprite2D:
	var g := Sprite2D.new()
	g.texture = PixelArt.glow_texture()
	g.position = pos
	g.scale = Vector2(scl, scl)
	g.modulate = tint
	g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _glow_mat == null:
		_glow_mat = CanvasItemMaterial.new()
		_glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	g.material = _glow_mat
	add_child(g)
	return g

func _flicker(g: Sprite2D, base: float) -> void:
	var wobble := 1.0 - FLICKER_AMPLITUDE + FLICKER_AMPLITUDE * sin(
			_time * FLICKER_SPEED + float(g.get_meta("ph")))
	g.modulate.a = clampf(base * LAMP_ALPHA * wobble, 0.0, 1.0)
