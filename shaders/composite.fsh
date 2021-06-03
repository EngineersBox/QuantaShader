#version 120

#include "lib/framebuffer.glsl"

varying vec4 texcoord;
varying vec3 lightVector;

/* DRAWBUFFERS:012 */

void main() {
    vec3 albedo = getAlbedo(texcoord.st);
    vec3 normal = getNormal(texcoord.st);
    float emission = getEmission(texcoord.st);

    float sunlightStrength = dot(normal, lightVector);
    sunlightStrength = max(0.0, sunlightStrength);

    float ambientLightStrength = 0.3;

    vec3 litColor = albedo * (sunlightStrength + ambientLightStrength);
    vec3 finalColor = mix(litColor, albedo, emission);

    GCOLOR_OUT = vec4(finalColor, 1.0);
}