shader_type canvas_item;
render_mode unshaded;

void fragment(){
	float sum = FRAGCOORD.x + FRAGCOORD.y;
	bool even = mod(sum, 2.0) < 0.0001; //gd4 why
	vec4 solid = COLOR.rgba;
	vec4 transparent = vec4(COLOR.rgb, 0.0);
	COLOR = (even)? transparent : solid;
}