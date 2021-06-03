#version 450 compatibility
#extension GL_GOOGLE_include_directive: require

#include "lib/framebuffer.glsl"

varying vec3 tintColor;

void main() {
    GCOLOR_OUT = vec4(tintColor, 1.0);
    GDEPTH_OUT = vec4(0.0, 0.0, 0.0, 1.0);
}