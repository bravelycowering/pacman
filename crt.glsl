// based on https://github.com/vrld/moonshine/blob/master/crt.lua

uniform vec2 distortionFactor;
uniform vec2 scaleFactor;
uniform float feather;
uniform float featheropacity;
uniform vec2 dimensions;
uniform Image prev;
uniform Image prev2;
uniform Image prev3;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
	// to barrel coordinates
	uv = uv * 2.0 - vec2(1.0);

	// distort
	uv *= scaleFactor;
	uv += (uv.yx*uv.yx) * uv * (distortionFactor - 1.0);
	float mask	= (1.0 - smoothstep(1.0-feather,1.0,abs(uv.x)))
				* (1.0 - smoothstep(1.0-feather,1.0,abs(uv.y)));
	if (mask == 0.0) {
		discard;
	} else {
		// to cartesian coordinates
		uv = (uv + vec2(1.0)) / 2.0;
		// scanlines
		float scanlinepos = mod(uv.y * dimensions.y, 1.0);
		float dim;
		if (scanlinepos < 0.5)
			dim = scanlinepos + 0.5;
		else
			dim = (1.0 - scanlinepos) + 0.5;
		return (dim * 0.125 + 0.9) * Texel(tex, uv) * (mask * featheropacity + (1.0 - featheropacity));
	}
}