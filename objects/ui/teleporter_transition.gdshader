//based on https://github.com/GDQuest/godot-demos/tree/master/2018/09-20-shaders/shaders

shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(0.0, 1.0);
uniform float smoothRange : hint_range(0.0, 1.0);
uniform sampler2D mask : source_color;
void fragment(){
	float value = texture(mask, UV).g;
	float alpha = smoothstep(cutoff, cutoff - smoothRange * 2.0, value * (1.0 - smoothRange*2.0));
	COLOR = vec4(COLOR.rgb, alpha);
}
