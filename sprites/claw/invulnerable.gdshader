shader_type canvas_item;
render_mode unshaded;

uniform float switcher;
const vec4 red = vec4(1.0, 0.0, 0.0, 0.4);
const vec4 blue = vec4(0.0, 0.0, 1.0, 0.4);
const vec4 yellow = vec4(1.0, 1.0, 0.0, 0.4);
const vec4 violet = vec4(1.0, 0.0, 1.0, 0.4);
const vec4 green = vec4(0.0, 1.0, 0.0, 0.4);

//not sure how to do this without the branching
void fragment(){
	if (texture(TEXTURE, UV).a > 0.0001){ //gd4 why
		switch(int(switcher)){
			case 0:
				COLOR = red; 
				break;
			case 1:
				COLOR = blue;
				break;
			case 2:
				COLOR = yellow;
				break;
			case 3:
				COLOR = violet;
				break;
			case 4:
				COLOR = green;
				break;
		}
	}
	else{
		discard;
	}
}
