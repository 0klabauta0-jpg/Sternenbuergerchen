extends RefCounted
## Deterministic spherical surface maps, generated once and cached by body.
static var _cache: Dictionary={}
static func texture(body: String) -> Texture2D:
	if _cache.has(body):return _cache[body]
	var noise:=FastNoiseLite.new()
	noise.seed={"star":182,"rust":921,"moon":925,"ice":311,"basalt":614,"mineral":710}.get(body,912)
	noise.frequency=0.018
	noise.fractal_octaves=5
	var image:=Image.create(256,256,false,Image.FORMAT_RGBA8)
	var base: Color={"star":Color("ffb346"),"rust":Color("c67b49"),"moon":Color("aea58c"),"ice":Color("b8d7db"),"basalt":Color("555263"),"mineral":Color("7b9a6c")}.get(body,Color("aa7351"))
	var light:=Vector3(-0.55,-0.45,0.68).normalized()
	var rng:=RandomNumberGenerator.new();rng.seed=noise.seed
	var craters: Array[Vector3]=[]
	for i in 32:craters.append(Vector3(rng.randf_range(-0.8,0.8),rng.randf_range(-0.8,0.8),rng.randf_range(0.035,0.15)))
	for y in 256:
		for x in 256:
			var p:=Vector2((x-127.5)/126.0,(y-127.5)/126.0)
			var d:=p.length_squared()
			if d>=1.0:continue
			var n:=Vector3(p.x,p.y,sqrt(1.0-d))
			var terrain:=noise.get_noise_3dv(n*190.0)
			var detail:=noise.get_noise_3dv(n*600.0)
			var color:=base.lerp(base.darkened(0.52),clampf(0.4+terrain*1.6,0,1))
			var lighting:=maxf(0.07,n.dot(light))
			var bump:=1.0
			if body in ["moon","rust","basalt"]:
				for crater: Vector3 in craters:
					var distance:=p.distance_to(Vector2(crater.x,crater.y))/crater.z
					if distance<1.0:bump*=0.74+0.26*distance
					elif distance<1.12:bump*=1.18
			if body=="star":
				color=Color("f56715").lerp(Color("ffdf85"),clampf(0.5+terrain*1.5+detail*0.45,0,1))
				lighting=0.78+0.22*n.z
			else:
				color=color.lightened(detail*0.16)
			color=Color(color.r*lighting*bump,color.g*lighting*bump,color.b*lighting*bump,clampf((1.0-d)*95,0,1))
			image.set_pixel(x,y,color)
	_cache[body]=ImageTexture.create_from_image(image)
	return _cache[body]
