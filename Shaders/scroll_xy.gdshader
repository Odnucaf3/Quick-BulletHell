shader_type canvas_item;
//------------------------------------------------------------------------------
uniform float speed_x = 0.1;
uniform float speed_y = 0.1;
//------------------------------------------------------------------------------
void vertex() {
	UV.x += TIME * speed_x;
	UV.y += TIME * speed_y;
}