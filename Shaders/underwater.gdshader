shader_type canvas_item;

uniform vec4 color : source_color;
uniform sampler2D fast_noise : repeat_enable;
uniform sampler2D screen_content : hint_screen_texture;
uniform vec2 speed = vec2(0.03, 0.07);
uniform float wave_strength = 2;

uniform float opacity : hint_range(0.0, 1.0, 0.01) = 0.5;

void fragment(){
	vec2 uv = UV + speed * TIME;
	vec2 noise = texture(fast_noise, uv).rg;

	//COLOR = vec4(color.r, color.g, color.b, 1) + vec4(noise.x, noise.y, 1, 1);
	// Replacement of the line above but without the noise calculation, it darkens the colors instead
	COLOR = vec4(color.r, color.g, color.b, 1);

	// Simulate refraction
	//COLOR *= texture(screen_content, SCREEN_UV + noise * (wave_strength/ 100.0));
	// Replacement of the line above but without the wave calculation
	COLOR *= texture(screen_content, SCREEN_UV);
}