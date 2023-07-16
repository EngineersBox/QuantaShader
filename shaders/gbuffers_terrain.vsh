#version 120

varying vec2 texCoord;
varying vec3 normal;
varying vec4 color;
varying vec2 lightmapCoord;

void main() {
    gl_Position = ftransform();
    texCoord = gl_MultiTexCoord0.st;
    normal = gl_NormalMatrix * gl_Normal;
	color = gl_Color;
	// Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    lightmapCoord = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
	lightmapCoord = (lightmapCoord * 33.05f / 32.0f) - (1.05f / 32.0f);
}
