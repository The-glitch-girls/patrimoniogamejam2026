shader_type canvas_item;

uniform float intensidad = 0.0;
uniform float radio_claro = 0.25;
uniform float radio_sombra = 0.55;

void fragment() {
	float aspecto = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 centro = (UV - vec2(0.5)) * vec2(aspecto, 1.0);
	float distancia = length(centro);
	float sombra = smoothstep(radio_claro, radio_sombra, distancia);

	COLOR = vec4(0.0, 0.0, 0.0, sombra * intensidad);
}
