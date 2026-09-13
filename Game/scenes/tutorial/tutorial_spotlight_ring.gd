extends Control
## Anel retangular pulsante em volta do alvo do TutorialSpotlight — mesma
## matemática de pulsação de engine/presentation/hotspot_glow.gd
## (Time.get_ticks_msec(), sem Tween), só que desenhando um retângulo
## arredondado em vez de um círculo (o alvo aqui é sempre um Control
## retangular, nunca um ícone circular de mapa).

const GLOW_COLOR: Color = Color(0.86, 0.74, 0.42)
const PULSE_SPEED: float = 2.0
const BASE_ALPHA: float = 0.75
const PULSE_RANGE: float = 0.20
const RING_WIDTH: float = 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(t * PULSE_SPEED)
	var alpha: float = BASE_ALPHA + PULSE_RANGE * pulse
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, alpha), false, RING_WIDTH)
