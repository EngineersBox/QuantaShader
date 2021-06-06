#version 120

#include "lib/framebuffer.glsl"

uniform sampler2D texture;
uniform float viewWidth;
uniform float viewHeight; 

varying vec4 color;
varying vec2 coord0;

// Radius of the vignette, where 0.5 results in a circle fitting the screen [Default: 0.85]
#define VIGNETTE_RADIUS 0.85
// Softness of the vignette, between 0.0 and 1.0 [Default: 0.45]
#define VIGNETTE_SOFTNESS 0.45
// Opacity of the vignette between 0.0 and 1.0 [Default: 0.5]
#define VIGNETTE_OPACITY 0.5

#define HDR_OVER_EXPOSE_STRENGTH 1.2
#define HDR_UNDER_EXPOSE_STRENGTH 1.5

vec4 vignette(in vec4 c) {
	vec2 center = (gl_FragCoord.xy / vec2(viewWidth, viewHeight)) - vec2(0.5);
	float vignette = smoothstep(VIGNETTE_RADIUS, VIGNETTE_RADIUS - VIGNETTE_SOFTNESS, length(center));
	c.rgb = mix(c.rgb, c.rgb * vignette, VIGNETTE_OPACITY);
    return c;
}

vec4 convertToHDR(in vec4 color) {
    vec4 hdrImage;

    vec4 overExposed = color * HDR_OVER_EXPOSE_STRENGTH;
    vec4 underExposed = color / HDR_UNDER_EXPOSE_STRENGTH;

    hdrImage = mix(underExposed, overExposed, color);

    return hdrImage;
}

void main() {
    vec4 newcolor = color;
    newcolor = vignette(newcolor);

    GCOLOR_OUT = newcolor * texture2D(texture, coord0);
}
