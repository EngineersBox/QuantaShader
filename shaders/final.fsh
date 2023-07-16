#version 120

varying vec2 texCoord;

uniform sampler2D colortex0;

void main() {
	vec3 color = pow(texture2D(colortex0, texCoord).rgb, vec3(1.0f / 2.2f));
	gl_FragColor = vec4(color, 1.0f);
}
