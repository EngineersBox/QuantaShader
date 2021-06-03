#version 450 compatibility

varying vec4 texcoord;

void main() {
    gl_Position = ftransform();

    texcoord = gl_MultiTexCoord0;
}