#version 120

#include "lib/framebuffer.glsl"

uniform int worldTime;

varying vec4 color;
varying vec2 coord0;
varying vec3 lightVector;

#define DAYTIME_AMBIENT_LIGHT_STRENGTH 0.3
#define NIGHTTIME_AMBIENT_LIGHT_STRENGTH 0.1

#define PI 3.141592653589793

#define DAY_CYCLE_LENGTH 24000

#define LIGHT_TIME_OFFSET (PI / 3.0)

void main() {
    vec3 albedo = getAlbedo(coord0);
    vec3 normal = getNormal(coord0);
    float emission = getEmission(coord0);

    float sunlightStrength = dot(normal, lightVector);
    sunlightStrength = max(0.0, sunlightStrength);

    // Use a cosine wave that oscillates with a period of 24000 to lerp between daylight and nighttime ambient light based on the current world time
    float lightDiffMedian = (DAYTIME_AMBIENT_LIGHT_STRENGTH - NIGHTTIME_AMBIENT_LIGHT_STRENGTH) / 2.0;
    float lerpedTime = cos(((PI * worldTime) / (DAY_CYCLE_LENGTH * 2)) - LIGHT_TIME_OFFSET);
    float ambientLightStrength = ((lightDiffMedian / 2.0) * lerpedTime) + lightDiffMedian;

    vec3 litColor = albedo * (sunlightStrength + ambientLightStrength);
    vec3 finalColor = mix(litColor, albedo, emission * 0.5);

    GCOLOR_OUT = vec4(finalColor, 1.0);
}