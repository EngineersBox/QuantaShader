#version 120

#include "lib/distort.glsl"

varying vec2 texCoord;

uniform vec3 sunPosition;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

const float sunPathRotation = -40.0f;
const float ambient = 0.1f;
const int shadowMapResolution = 2048;
const int noiseTextureResolution = 64;

#define SHADOW_POISSON_SAMPLES 4
#define SHADOW_SAMPLES 2
const int shadowSamplesPerSize = 2 * SHADOW_SAMPLES + 1;
const int totalSamples = shadowSamplesPerSize * shadowSamplesPerSize;

float adjustLightmapTorch(in float torch) {
    const float K = 2.0f;
    const float P = 5.06f;
    return K * pow(torch, P);
}

float adjustLightmapSky(in float sky){
    float sky_2 = sky * sky;
    return sky_2 * sky_2;
}

vec2 adjustLightmap(in vec2 lightmap){
    vec2 newLightMap;
    newLightMap.x = adjustLightmapTorch(lightmap.x);
    newLightMap.y = adjustLightmapSky(lightmap.y);
    return newLightMap;
}

// Input is not adjusted lightmap coordinates
vec3 getLightmapColor(in vec2 lightmap){
    // First adjust the lightmap
    lightmap = adjustLightmap(lightmap);
    // Color of the torch and sky. The sky color changes depending on time of day but I will ignore that for simplicity
    const vec3 torchColor = vec3(1.0f, 0.25f, 0.08f);
    const vec3 skyColor = vec3(0.05f, 0.15f, 0.3f);
    // Multiply each part of the light map with it's color
    vec3 torchLighting = lightmap.x * torchColor;
    vec3 skyLighting = lightmap.y * skyColor;
    // Add the lighting togther to get the total contribution of the lightmap the final color.
    vec3 lightmapLighting = torchLighting + skyLighting;
    // Return the value
    return lightmapLighting;
}

float visibility(in sampler2D shadowMap, in vec3 sampleCoord) {
    return step(sampleCoord.z - 0.001f, texture2D(shadowMap, sampleCoord.xy).r);
}

vec3 transparentShadow(in vec3 sampleCoord) {
	float shadowVisibility0 = visibility(shadowtex0, sampleCoord);
    float shadowVisibility1 = visibility(shadowtex1, sampleCoord);
    vec4 shadowColor0 = texture2D(shadowcolor0, sampleCoord.xy);
    vec3 transmittedColor = shadowColor0.rgb * (1.0f - shadowColor0.a); // Perform a blend operation with the sun color
    return mix(transmittedColor * shadowVisibility1, vec3(1.0f), shadowVisibility0);	
}

// TODO: Swap out PCF for Vogel or Poisson disk in spherical sampling
vec3 getShadow(float depth) {
	vec3 clipSpace = vec3(texCoord, depth) * 2.0f - 1.0f;
	vec4 viewW = gbufferProjectionInverse * vec4(clipSpace, 1.0f);
	vec3 view = viewW.xyz / viewW.w;
	vec4 world = gbufferModelViewInverse * vec4(view, 1.0f);
	vec4 shadowSpace = shadowProjection * shadowModelView * world;
	shadowSpace.xy = distortPosition(shadowSpace.xy);
	vec3 sampleCoord = shadowSpace.xyz * 0.5f + 0.5f;
	float randomAngle = texture2D(noisetex, texCoord * 20.0f).r * 100.0f;
    float cosTheta = cos(randomAngle);
	float sinTheta = sin(randomAngle);
    mat2 rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; // We can move our division by the shadow map resolution here for a small speedup
    vec3 shadowAccum = vec3(0.0f);
    for(int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++){
        for(int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++){
            vec2 offset = rotation * vec2(x, y);
            vec3 currentSampleCoordinate = vec3(sampleCoord.xy + offset, sampleCoord.z);
            shadowAccum += transparentShadow(currentSampleCoordinate);
        }
    }
    shadowAccum /= totalSamples;
    return shadowAccum;
}

vec2 poissonDisk[16] = vec2[]( 
   vec2( -0.94201624, -0.39906216 ), 
   vec2( 0.94558609, -0.76890725 ), 
   vec2( -0.094184101, -0.92938870 ), 
   vec2( 0.34495938, 0.29387760 ), 
   vec2( -0.91588581, 0.45771432 ), 
   vec2( -0.81544232, -0.87912464 ), 
   vec2( -0.38277543, 0.27676845 ), 
   vec2( 0.97484398, 0.75648379 ), 
   vec2( 0.44323325, -0.97511554 ), 
   vec2( 0.53742981, -0.47373420 ), 
   vec2( -0.26496911, -0.41893023 ), 
   vec2( 0.79197514, 0.19090188 ), 
   vec2( -0.24188840, 0.99706507 ), 
   vec2( -0.81409955, 0.91437590 ), 
   vec2( 0.19984126, 0.78641367 ), 
   vec2( 0.14383161, -0.14100790 ) 
);

float random(vec3 seed, int i){
	vec4 seed4 = vec4(seed,i);
	float dot_product = dot(seed4, vec4(12.9898,78.233,45.164,94.673));
	return fract(sin(dot_product) * 43758.5453);
}

vec3 getShadowPoisson(float ndotL, float depth) {
	vec3 clipSpace = vec3(texCoord, depth) * 2.0f - 1.0f;
	vec4 viewW = gbufferProjectionInverse * vec4(clipSpace, 1.0f);
	vec3 view = viewW.xyz / viewW.w;
	vec4 world = gbufferModelViewInverse * vec4(view, 1.0f);
	vec4 shadowSpace = shadowProjection * shadowModelView * world;
	shadowSpace.xy = distortPosition(shadowSpace.xy);
	vec3 sampleCoord = shadowSpace.xyz * 0.5f + 0.5f;
	float randomAngle = texture2D(noisetex, texCoord * 20.0f).r * 100.0f;
    float cosTheta = cos(randomAngle);
	float sinTheta = sin(randomAngle);
    mat2 rotation =  mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution; // We can move our division by the shadow map resolution here for a small speedup
	vec3 shadowAccum = vec3(1.0f);
	float bias = 0.001;
	bias *= tan(acos(clamp(ndotL, 0, 1)));
	bias = clamp(bias, 0,0.01);
	for (int i = 0; i < SHADOW_POISSON_SAMPLES; i++) {
		int index = int(16.0 * random(floor(world.xyz * 1000.0), i)) % 16;
		shadowAccum -= 0.2 * (1.0 - transparentShadow(vec3(
			sampleCoord.xy + (poissonDisk[index] / 700.0),
			(sampleCoord.z) / shadowSpace.w
		)));
	}
	return shadowAccum;
}

void main(){
    // Account for gamma correction
    vec3 albedo = pow(texture2D(colortex0, texCoord).rgb, vec3(2.2f));
	float depth = texture2D(depthtex0, texCoord).r;
	if (depth == 1.0f){
		gl_FragData[0] = vec4(albedo, 1.0f);
		return;
	}
    // Get the normal
    vec3 normal = normalize(texture2D(colortex1, texCoord).rgb * 2.0f - 1.0f);
	// Get lightmap
	vec2 lightmap = texture2D(colortex2, texCoord).rg;
	// Get lightmap color
	vec3 lightmapColor = getLightmapColor(lightmap);
    // Compute cos theta between the normal and sun directions
    float ndotL = max(dot(normal, normalize(sunPosition)), 0.0f);
    // Do the lighting calculations
    vec3 diffuse = albedo * (lightmapColor + ndotL * getShadowPoisson(ndotL, depth) + ambient);
    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(diffuse, 1.0f);
}
