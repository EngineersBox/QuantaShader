#version 120

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

varying vec4 color;
varying vec2 coord0;
varying vec3 lightVector;

void main() {
    gl_Position = ftransform();

    color = gl_Color.rgba;
    coord0 = (gl_MultiTexCoord0).xy;

    if (worldTime < 12700 || worldTime > 23250) {
        lightVector = normalize(sunPosition);
    } else {
        lightVector = normalize(moonPosition);
    }
}