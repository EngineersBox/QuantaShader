#version 120

#include "lib/framebuffer.glsl"

varying vec3 normal;
varying vec3 tintColor;
varying vec2 coord0;

uniform sampler2D texture;

void main() {
    vec4 blockColor = texture2D(texture, coord0);
    blockColor.rgb *= tintColor;

    GCOLOR_OUT = blockColor;
    // Normals are within range -1 to 1, but we need zero centered unit normals.
    // Do achieve this we multiple by 0.5 then add 0.5
    GNORMAL_OUT = vec4(normal * 0.5 + 0.5, 1.0);
}