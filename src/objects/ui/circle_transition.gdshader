//based on https://gl-transitions.com/editor/circle

shader_type canvas_item;
render_mode unshaded;

uniform vec2 close_position = vec2(0.5, 0.5);
uniform float progress : hint_range(0.0, 1.0);
uniform float multiplier;
uniform float screen_ratio = 0.75;

void fragment(){
	float _distance = length(vec2((UV.x)/screen_ratio, UV.y) - vec2(close_position.x/screen_ratio, close_position.y));
	float radius = multiplier * abs(progress - 0.5);
	if (_distance < radius) {
		COLOR = vec4(COLOR.rgb, 0.0);
	}
}
