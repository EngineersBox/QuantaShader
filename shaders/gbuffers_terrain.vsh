#version 120

varying vec3 normal;
varying vec3 tintColor;
varying vec4 textcoord;

void main() {
    gl_Position = ftransform();

    textcoord = gl_MultiTexCoord0;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}