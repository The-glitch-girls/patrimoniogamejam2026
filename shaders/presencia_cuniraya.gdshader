shader_type canvas_item;

uniform float intensidad = 0.0;

void fragment() {
	vec2 uv = UV;
	
	float distancia_borde = min(
		min(uv.x, 1.0 - uv.x),
		min(uv.y, 1.0 - uv.y)
	);

	float borde = 1.0 - smoothstep(0.0, 0.35, distancia_borde);

	COLOR = vec4(0.0, 0.0, 0.0, borde * intensidad);
}