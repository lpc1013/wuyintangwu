extends SceneTree

## 导出版自检：确认 animals 贴图在 pck 里真的取得到。
## 用法：godot --headless --path godot --script res://tools/_packcheck.gd

const PK := "D:/朝花夕拾 闲暇随笔/李沁玲/大二上/SpringAnimal/web/index.pck"

func _init() -> void:
	print("pck exists: ", FileAccess.file_exists(PK))
	print("pack loaded: ", ProjectSettings.load_resource_pack(PK, true))

	var species := ["capy", "bear", "badg", "cat3", "chick"]
	var poses := ["walk", "sit", "soak", "rest", "hop", "stepL", "stepR"]
	var got := 0
	var miss := 0
	for sp in species:
		for pose in poses:
			var path := "res://assets/animals/%s_%s.png" % [sp, pose]
			var t: Texture2D = null
			if FileAccess.file_exists(path):
				var img := Image.load_from_file(path)
				if img != null:
					t = ImageTexture.create_from_image(img)
			if t == null:
				t = ResourceLoader.load(path, "Texture2D") as Texture2D
			if t != null:
				got += 1
			else:
				miss += 1
				print("MISS ", path)
	print("sample got=", got, " miss=", miss)

	var one := "res://assets/animals/capy_walk.png"
	print("file_exists: ", FileAccess.file_exists(one))
	print("Image.load_from_file: ", Image.load_from_file(one))
	var t0 := ResourceLoader.load(one, "Texture2D") as Texture2D
	print("ResourceLoader: ", t0, " size=", t0.get_size() if t0 else Vector2.ZERO)
	quit()
