const int RGBA16 = 1;
const int gcolorFormat = RGBA16;

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

#define GCOLOR_OUT gl_FragData[0]
#define GDEPTH_OUT gl_FragData[1]
#define GNORMAL_OUT gl_FragData[2]
#define GSPECULAR_OUT gl_FragData[3]
#define GSHADOW_TEX_0_OUT gl_FragData[4]
#define GSHADOW_TEX_1_OUT gl_FragData[5]
#define GDEPTH_TEX_0_OUT gl_FragData[6]
#define GDEPTH_TEX_1_OUT gl_FragData[12]
#define GSHADOW_COLOR_0_OUT gl_FragData[13]
#define GSHADOW_COLOR_1_OUT gl_FragData[14]
#define GNOISE_TEX_OUT gl_FragData[15]

vec3 getAlbedo(in vec2 coord) {
    return texture2D(gcolor, coord).rgb;
}

vec3 getNormal(in vec2 coord) {
    // When sampling normals we need to return them to the original state they were passed as initially
    // To do this we multiple by 2.0 and minus 1.0
    return texture2D(gnormal, coord).rgb * 2.0 - 1.0;
}

vec3 getDepth(in vec2 coord) {
    return texture2D(gdepth, coord).rgb;
}

float getEmission(in vec2 coord) {
    return texture2D(gdepth, coord).a;
}