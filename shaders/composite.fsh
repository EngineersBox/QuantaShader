#version 120

#include "lib/framebuffer.glsl"

uniform int worldTime;
uniform float zNear; // Near viewing plane distance (not normalised)
uniform float zFar; // Far viewing plane distance (not normalised)
uniform float viewWidth;
uniform float viewHeight;

float width = viewWidth;
float height = viewHeight;

varying vec4 color;
varying vec2 coord0;
varying vec3 lightVector;

#define DAYTIME_AMBIENT_LIGHT_STRENGTH 0.3
#define NIGHTTIME_AMBIENT_LIGHT_STRENGTH 0.1

#define PI 3.141592653589793

#define DAY_CYCLE_LENGTH 24000

#define LIGHT_TIME_OFFSET (PI / 3.0)

#define AO_STRENGTH 1000.0
#define DEPTH_TOLERANCE 0.0001

#define strength 0.1

/* User Defined */

uniform int samples; //ao sample count //64.0
uniform float radius; //ao radius //5.0

float aoclamp = 0.125; //depth clamp - reduces haloing at screen edges
bool noise = true; //use noise instead of pattern for sample dithering
float noiseamount = 0.0002; //dithering amount

float diffarea = 0.3; //self-shadowing reduction
float gdisplace = 0.4; //gauss bell center //0.4

bool mist = false; //use mist?
float miststart = 0.0; //mist start
float mistend = zFar; //mist end

bool onlyAO = false; //use only ambient occlusion pass?
float lumInfluence = 0.7; //how much luminance affects occlusion

float worldTimeAmbientLight() {
    // Use a cosine wave that oscillates with a period of 24000 to lerp between daylight and nighttime ambient light based on the current world time
    float lightDiffMedian = (DAYTIME_AMBIENT_LIGHT_STRENGTH - NIGHTTIME_AMBIENT_LIGHT_STRENGTH) / 2.0;
    float lerpedTime = cos(((PI * worldTime) / (DAY_CYCLE_LENGTH * 2)) - LIGHT_TIME_OFFSET);
    return ((lightDiffMedian / 2.0) * lerpedTime) + lightDiffMedian;
}

//generating noise/pattern texture for dithering
vec2 rand(vec2 coord) {
    float noiseX = ((fract(1.0-coord.s*(width/2.0))*0.25)+(fract(coord.t*(height/2.0))*0.75))*2.0-1.0;
    float noiseY = ((fract(1.0-coord.s*(width/2.0))*0.75)+(fract(coord.t*(height/2.0))*0.25))*2.0-1.0;

    if (noise) {
        noiseX = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233))) * 43758.5453),0.0,1.0)*2.0-1.0;
        noiseY = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233)*2.0)) * 43758.5453),0.0,1.0)*2.0-1.0;
    }
    return vec2(noiseX,noiseY)*noiseamount;
}

float doFog() {
    float zdepth = getDepth(coord0).x;
    float depth = -zFar * zNear / (zdepth * (zFar - zNear) - zFar);
    return clamp((depth - miststart)/mistend, 0.0, 1.0);
}

float readDepth(vec2 coord) {
    if (coord0.x < 0.0 || coord0.y < 0.0) {
        return 1.0;
    }
    float z_b = getDepth(coord0).x;
    float z_n = 2.0 * z_b - 1.0;
    return (2.0 * zNear) / (zFar + zNear - z_n * (zFar - zNear));
}

int compareDepthsFar(float depth1, float depth2) {
    float garea = 2.0; //gauss bell width
    float diff = (depth1 - depth2)*100.0; //depth difference (0-100)
    //reduce left bell width to avoid self-shadowing
    return diff < gdisplace ? 0 : 1;
}

float compareDepths(float depth1, float depth2) {
    float garea = 2.0; //gauss bell width
    float diff = (depth1 - depth2) * 100.0; //depth difference (0-100)
    //reduce left bell width to avoid self-shadowing
    if (diff < gdisplace) {
        garea = diffarea;
    }

    float gauss = pow(2.7182, -2.0 * (diff - gdisplace) * (diff - gdisplace) / (garea * garea));
    return gauss;
}

float calAO(float depth,float dw, float dh) {
    float dd = (1.0 - depth) * radius;

    float temp = 0.0;
    float temp2 = 0.0;
    float coordw = coord0.x + dw * dd;
    float coordh = coord0.y + dh * dd;
    float coordw2 = coord0.x - dw * dd;
    float coordh2 = coord0.y - dh * dd;

    vec2 coord = vec2(coordw , coordh);
    vec2 coord2 = vec2(coordw2, coordh2);

    float cd = readDepth(coord);
    int far = compareDepthsFar(depth, cd);
    temp = compareDepths(depth, cd);
    //DEPTH EXTRAPOLATION:
    if (far > 0) {
        temp2 = compareDepths(readDepth(coord2),depth);
        temp += (1.0 - temp) * temp2;
    }

    return temp;
}

vec3 applyAO(in vec3 c) {
    vec2 noise = rand(coord0);
    float depth = readDepth(coord0);

    float w = (1.0 / width) / clamp(depth, aoclamp, 1.0) + (noise.x * (1.0 - noise.x));
    float h = (1.0 / height) / clamp(depth, aoclamp, 1.0) + (noise.y * (1.0 - noise.y));

    float pw = 0.0;
    float ph = 0.0;

    float ao = 0.0;

    float dl = PI * (3.0 - sqrt(5.0));
    float dz = 1.0 / float(samples);
    float l = 0.0;
    float z = 1.0 - dz / 2.0;

    for (int i = 0; i < 64; i++) {
        if (i > samples) break;
        float r = sqrt(1.0 - z);

        pw = cos(l) * r;
        ph = sin(l) * r;
        ao += calAO(depth, pw * w, ph * h);
        z = z - dz;
        l = l + dl;
    }


    ao /= float(samples);
    ao *= strength;
    ao = 1.0 - ao;

    if (mist) {
        ao = mix(ao, 1.0, doFog());
    }

    return vec3(depth);
}

void main() {
    vec3 albedo = getAlbedo(coord0);
    vec3 normal = getNormal(coord0);
    float emission = getEmission(coord0);

    float sunlightStrength = dot(normal, lightVector);
    sunlightStrength = max(0.0, sunlightStrength);

    vec3 litColor = albedo * (sunlightStrength + worldTimeAmbientLight());
    vec3 finalColor = mix(litColor, albedo, emission * 0.5);

    GCOLOR_OUT = vec4(finalColor, 1.0);
}