extends Node
## Equirectangular cloud cover on the existing weather-compatible procedural sky.
## Generated once per palette; no texture generation, particles or geometry per frame.
const Birds = preload("res://scripts/worlds/birds.gd")
const Aircraft = preload("res://scripts/worlds/aircraft.gd")
static var covers: Dictionary = {}
static var images: Dictionary = {}
var environment: Environment
var world_index: int
var connected_weather: Node

static func install(env: Environment, world: int, track: Node3D = null) -> Node:
 if world==5 or env.sky==null: return null
 var sky = env.sky.sky_material as ProceduralSkyMaterial
 if sky==null: return null
 sky.sky_top_color = Color("6296be") if world!=1 else Color("101b39")
 sky.sky_horizon_color = Color("cfdeDF") if world!=0 else Color("e3bc9f")
 if world==1: sky.sky_horizon_color = Color("354767")
 sky.sky_curve = 0.2
 sky.sun_angle_max = 1.8 if world!=1 else 0.0
 sky.sun_curve = 0.07
 sky.sky_cover = panorama(world==1)
 sky.sky_cover_modulate = Color("c8c0b4") if world==0 else Color("b9c5cd")
 sky.set_meta("dutch_cloud_cover",true)
 env.sky.radiance_size = Sky.RADIANCE_SIZE_128
 if track==null: return null
 var controller = new()
 controller.name = "DutchSky"
 controller.environment = env
 controller.world_index = world
 controller.set_meta("panorama_resolution",Vector2i(1024,512))
 controller.set_meta("weather_compatible",true)
 if track!=null:
  track.add_child(controller)
  Aircraft.install(track)
  Birds.install(track)
 controller.sync_weather()
 return controller

func _process(_delta: float) -> void:
 sync_weather()

func _weather_changed(_event: String) -> void:
 sync_weather()

func sync_weather() -> void:
 if environment==null or environment.sky==null: return
 var sky = environment.sky.sky_material as ProceduralSkyMaterial
 if sky==null: return
 var weather = get_parent().get_node_or_null("Weather") if get_parent()!=null else null
 if weather!=null and connected_weather!=weather:
  connected_weather = weather
  weather.changed.connect(_weather_changed)
 var night = 1.0 if world_index==1 else 0.0
 var rain = 0.0
 if weather!=null:
  night = maxf(night,float(weather.night_amount))
  rain = float(weather.rain_amount)
 var cover = panorama(night>0.5)
 if sky.sky_cover!=cover: sky.sky_cover = cover
 var day = Color("d4bda2") if world_index==0 else Color("bdcbd1")
 var tint = day.lerp(Color("8496a9"),rain*0.7).lerp(Color("a6b9d0"),night)
 if sky.sky_cover_modulate!=tint: sky.sky_cover_modulate = tint
 var sun_angle = 0.0 if night>0.5 else 1.8
 if not is_equal_approx(sky.sun_angle_max,sun_angle): sky.sun_angle_max = sun_angle
 sky.set_meta("weather_night",night)
 sky.set_meta("weather_rain",rain)

static func panorama(night: bool) -> Texture2D:
 var key = "night" if night else "day"
 if covers.has(key): return covers[key]
 var width = 1024
 var height = 512
 var image = Image.create(width,height,false,Image.FORMAT_RGBA8)
 image.fill(Color(0,0,0,0))
 var broad = FastNoiseLite.new()
 broad.seed = 8417
 broad.frequency = 0.16
 broad.fractal_octaves = 3
 var detail = FastNoiseLite.new()
 detail.seed = 715
 detail.frequency = 0.7
 detail.fractal_octaves = 2
 # Projection onto a high flat cloud layer gives broad low-horizon cumulus banks.
 # Direction-based noise is continuous at the equirectangular longitudinal seam.
 for y in height/2:
  var elevation = cos(PI*(y+0.5)/height)
  var latitude_factor = sin(PI*(y+0.5)/height)
  var fade = smoothstep(0.025,0.12,elevation)*(1.0-smoothstep(0.82,0.99,elevation))
  for x in width:
   var angle = TAU*x/(width-1.0)
   var px = cos(angle)*latitude_factor/(elevation+0.13)*14
   var pz = sin(angle)*latitude_factor/(elevation+0.13)*14
   var noise = broad.get_noise_2d(px,pz)*0.8+detail.get_noise_2d(px,pz)*0.22
   var cloud = smoothstep(-0.06,0.25,noise)*fade
   var luminance = 0.13 if night else 0.88+0.12*smoothstep(-0.2,0.4,noise)
   image.set_pixel(x,y,Color(luminance*0.92,luminance*0.97,luminance,cloud*0.76))
 if night:
  var rng = RandomNumberGenerator.new()
  rng.seed = 26672
  for index in 420:
   var x = rng.randi_range(0,width-1)
   var y = rng.randi_range(9,height/2-35)
   var glow = rng.randf_range(0.3,0.9)
   image.set_pixel(x,y,Color(glow*0.87,glow*0.94,glow,1))
  # Round moon corrected for longitude stretching at this elevation.
  var center = Vector2(700,135)
  for y in range(125,146):
   for x in range(685,716):
    var dx = (x-center.x)*0.72
    var dy = y-center.y
    var distance = Vector2(dx,dy).length()
    if distance<8.5:
     var crater = 0.12 if Vector2(dx-2,dy+2).length()<2.8 or Vector2(dx+3,dy-1).length()<1.6 else 0.0
     image.set_pixel(x,y,Color(0.88-crater,0.90-crater,0.87-crater,smoothstep(8.5,7.7,distance)))
 var texture = ImageTexture.create_from_image(image)
 texture.set_meta("generated_cloud_panorama",true)
 texture.set_meta("night",night)
 texture.set_meta("source","original code-native equirectangular cumulus, no external image")
 images[key] = image
 covers[key] = texture
 return texture
