#version 120
#extension GL_GOOGLE_include_directive: require

#include "lib/framebuffer.glsl"

varying vec3 normal;
varying vec3 tintColor;
varying vec4 texcoord;

uniform sampler2D texture;

void main() {
    vec4 blockColor = texture2D(texture, texcoord.st);
    blockColor.rgb *= tintColor;

    GCOLOR_OUT = blockColor;
    // Normals are within range 0-1, but we need zero centered normals.
    // Do achieve this we multiple by 0.5 then add 0.5
    GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
}