shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment(){
	vec4 inverted_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = vec4(1.0-inverted_color.rgb, inverted_color.a);
}