uniform Image palette;
uniform vec2 palette_size;
uniform int index;
uniform bool opaque;

vec4 PalTexel(Image tex, vec2 texture_coords) {
	vec4 texcolor = Texel(tex, texture_coords);
	float x = (float(index) + 0.5) / palette_size.x;
	vec4 finalcolor = vec4(0.0, 0.0, 0.0, 0.0);
	for (float i = 0.0; i < 256.0; i++) {
		if (i >= palette_size.y)
			break;
		vec2 palette_coords = vec2(x, (i + 0.5) / palette_size.y);
		vec4 matchcolor = Texel(palette, vec2(0.0, palette_coords.y));
		vec4 palcolor = Texel(palette, palette_coords);
		if (texcolor == matchcolor) {
			finalcolor = palcolor;
		}
	}
	if (opaque) {
		finalcolor[3] = 1.0;
	}
	return finalcolor;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
	if (index == 0) {
		return color * Texel(tex, uv);
	} else {
		return color * PalTexel(tex, uv);
	}
}