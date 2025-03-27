shader_type spatial;

uniform sampler2D base_texture : hint_normal;
uniform vec3 fresnel_color: source_color;

vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}

void fragment()
{
	vec4 texture_color = texture(base_texture, UV);
	vec3 fresnel = fresnel_glow(4.0, 4.5, fresnel_color, NORMAL, VIEW);
	ALBEDO = texture_color.rgb + fresnel;
}
