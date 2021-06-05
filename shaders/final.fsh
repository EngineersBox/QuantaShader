#version 120

#include "lib/framebuffer.glsl"

uniform sampler2D texture;

varying vec4 color;
varying vec2 coord0;

#define VIGNETTE_STRENGTH 1.0
#define VIGNETTE_THRESHOLD 1.5142

#define HDR_OVER_EXPOSE_STRENGTH 1.2
#define HDR_UNDER_EXPOSE_STRENGTH 1.5

vec4 vignette(in vec4 c) {
    float dist = distance(coord0, vec2(0.5)) * 2.0;
    dist /= VIGNETTE_THRESHOLD;

    dist = pow(dist, 1.1);

    c.rgb *= (1.0 - dist) * VIGNETTE_STRENGTH;
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
    // newcolor = vignette(newcolor);

    GCOLOR_OUT = newcolor * texture2D(texture, coord0);
}
