shader_type spatial;

// Depth colors
uniform vec4 primary_color: source_color;
uniform vec4 secondary_color: source_color;

uniform float roughness = 0.2;

// Wave Normal Maps
uniform sampler2D normalmap_a : hint_normal;
uniform sampler2D normalmap_b : hint_normal;
uniform float normalmap_a_strength : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float normalmap_b_strength : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform vec2 movement_direction = vec2(0.2, 0.1);
uniform float movement_strength = 0.12;
uniform float uv_scale = 1.0;

// Water textures?
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// Depth Value
uniform float depth_distance : hint_range(0.0, 200.0, 0.1) = 4.0;
uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float water_opacity : hint_range(0.0, 1.0, 0.01) = 0.05;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	float basic_fresnel = fresnel(3.0, NORMAL, VIEW);
	
	vec2 uv = UV * uv_scale;
	vec2 uv_movement = movement_direction * TIME * movement_strength;
	
	vec3 normalmap = texture(normalmap_a, uv + uv_movement).rgb * normalmap_a_strength;
	normalmap += texture(normalmap_b, uv - uv_movement).rgb * normalmap_b_strength;
	
	// Get Depth and Screen Textures
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec3 screen = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;

	// Get Depth in World Position (Y)
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	
	// Set Depth Blend and adjust with Beer's Law
	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);
	
	// Set depth color mix from depth blend and get final color mix using screen texture
	vec3 depth_color = mix(secondary_color, primary_color, depth_blend).rgb;
	vec3 final_color = mix(depth_color.rgb, screen, water_opacity);
	
	//ALBEDO = primary_color.rgb + (0.2 * basic_fresnel);
	ALBEDO = mix(final_color, screen, depth_blend * (1.0 - basic_fresnel));
	ROUGHNESS = roughness * (1.0 - basic_fresnel);
	NORMAL_MAP = normalmap;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
