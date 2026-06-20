extends PointLight2D
class_name DeepSeaLight

var base_scale: Vector2
var base_energy: float
var time_passed: float = 0.0
var noise: FastNoiseLite

@export var pulse_speed: float = 1.0
@export var scale_jitter: float = 0.1
@export var energy_jitter: float = 0.2

func _ready() -> void:
	base_scale = scale
	base_energy = energy
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02

func _process(delta: float) -> void:
	time_passed += delta * pulse_speed * 100.0
	
	var n1 = noise.get_noise_1d(time_passed)
	var n2 = noise.get_noise_1d(time_passed + 1000.0)
	
	scale = base_scale + Vector2(n1, n2) * scale_jitter
	energy = base_energy + n1 * energy_jitter

func update_base_energy(new_val: float) -> void:
	base_energy = new_val
