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

vec3 getShadow(float depth) {
	vec3 clipSpace = vec3(texCoord, depth) * 2.0f - 1.0f;
	vec4 viewW = gbufferProjectionInverse * vec4(clipSpace, 1.0f);
	vec3 view = viewW.xyz / viewW.w;
	vec4 world = gbufferModelViewInverse * vec4(view, 1.0f);
	vec4 shadowSpace = shadowProjection * shadowModelView * world;
	shadowSpace.xy = distortPosition(shadowSpace.xy);
	vec3 sampleCoord = shadowSpace.xyz * 0.5f + 0.5f;
	return transparentShadow(sampleCoord);
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
    vec3 diffuse = albedo * (lightmapColor + ndotL * getShadow(depth) + ambient);
    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4(diffuse, 1.0f);
}
