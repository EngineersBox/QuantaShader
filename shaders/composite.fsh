#version 120

#include "lib/framebuffer.glsl"

varying vec4 color;
varying vec2 coord0;
varying vec3 lightVector;


void main() {
    vec3 albedo = getAlbedo(coord0);
    vec3 normal = getNormal(coord0);
    float emission = getEmission(coord0);

    float sunlightStrength = dot(normal, lightVector);
    sunlightStrength = max(0.0, sunlightStrength);

    float ambientLightStrength = 0.3;

    vec3 litColor = albedo * (sunlightStrength + ambientLightStrength);
    vec3 finalColor = mix(litColor, albedo, emission);

    GCOLOR_OUT = vec4(litColor, 1.0);
}