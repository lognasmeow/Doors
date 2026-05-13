shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Virtual resolution used for the pixelation effect
uniform vec2 virtual_resolution = vec2(640.0, 480.0);

// Strength of the LCD/subpixel grid effect
uniform float grid_strength : hint_range(0.0, 1.0) = 0.15;

// Grid frequency multiplier
uniform float grid_scale : hint_range(0.1, 10.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;

	// Snap UVs to a low-resolution grid to create a pixelated look
	vec2 pixel_uv = floor(uv * virtual_resolution) / virtual_resolution;

	vec3 col = textureLod(screen_texture, pixel_uv, 0.0).rgb;

	// Subpixel/LCD-style horizontal grid
	float grid = 0.5 + 0.5 * sin(uv.x * virtual_resolution.x * 3.14159 * grid_scale);
	col *= mix(1.0, grid, grid_strength);

	COLOR = vec4(col, 1.0);
}