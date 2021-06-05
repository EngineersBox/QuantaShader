#version 120

varying vec3 normal;
varying vec3 tintColor;
varying vec2 coord0;

void main() {
    gl_Position = ftransform();

    coord0 = gl_MultiTexCoord0.xy;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}