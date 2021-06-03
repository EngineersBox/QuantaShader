#version 450 compatibility

varying vec3 tintColor;

void main() {
    gl_Position = ftransform();

    tintColor = gl_Color.rgb;
}