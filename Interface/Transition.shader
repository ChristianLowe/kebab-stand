shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_albedo;
uniform bool fade_in;

void fragment()
{
	float value = texture(mask, UV).r;
	float alpha;
	if (fade_in) {
		alpha = step(cutoff, value);
	} else {
		alpha = step(value, cutoff);
	}
	COLOR = vec4(COLOR.rgb, alpha);
}
