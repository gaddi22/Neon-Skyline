#version 460 

#include "settings.glsl"

uniform sampler2D depthtex0;    //depthmap
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //lighting/edge data
uniform sampler2D colortex3;    //fragment type

uniform float far;
uniform float near;

in vec2 texCoord;

/* RENDERTARGETS: 0,2 */

/* DRAWBUFFERS */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 detectionData;


/*  Radar Colors */
const float entity_min = 0.05;
const float entity_max = 0.7;
vec4 TERRAIN = GRND_COLOR;
vec4 ENTITY_DEFAULT = UNKN_COLOR;
vec4 PLAYER = PLYR_COLOR;
vec4 FRIENDLY = FRND_COLOR;
vec4 ENEMY = ENMY_COLOR;
vec4 PICKUP = PKUP_COLOR;

float linearizeDepth(float depth, float near, float far) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

const float color_kernel[9] = float[](-1.0, -1.0, -1.0, -1.0, 8.0, -1.0, -1.0, -1.0, -1.0);
const float depth_kernel[9] = float[](1.0, 1.0, 1.0, 1.0, -8.0, 1.0, 1.0, 1.0, 1.0);

#define DH_FRAG 1
#define ENT_FRAG 2

void main() {
    vec4 lightData = texture(colortex2,texCoord);

    float entity = texture2D(colortex3,texCoord).r;
    if (entity > entity_max){ //things that should not be edgedetected (sky, weather)
        color = texture(colortex0,texCoord);
        return;
    }
    int type = 0;
    if(entity > .005 && entity < 0.015) type = DH_FRAG;
    if(entity > .05 && entity < 0.65) type = ENT_FRAG;

    //edge detection adapted from vector shaders by WoMspace (https://github.com/WoMspace/VECTOR/tree/main/shaders)
    //check color against line detector kernel
	vec3 color_vec = vec3(0.0);
    for(int y = 0; y < 3; y++) {
		for(int x = 0; x < 3; x++) {
			vec2 offset = pixelSize * vec2(x - 1, y - 1) * 1.0;
			color_vec += texture2D(colortex0, texCoord + offset).rgb * color_kernel[y * 3 + x];
		}
	}
	color_vec /= 4.5;

    //check depth against line detector kernel
	float depth = 0.0;
	for(int y = 0; y < 3; y++) {
		for(int x = 0; x < 3; x++) {
			vec2 offset = pixelSize * vec2(float(x) - 1.0, float(y) - 1.0) * 1.0;
            float rawDepth = 0;
            if(type == DH_FRAG) {
                rawDepth = texture2D(colortex3, texCoord+offset).g;
                depth += rawDepth * depth_kernel[y * 3 + x];
            }
            else {
                rawDepth = texture2D(depthtex0, texCoord + offset).r;
			    depth += linearizeDepth(rawDepth,near,far) * depth_kernel[y * 3 + x];
            }
		}
	}
	depth *= 0.8;

    float grey = dot(color_vec, vec3(0.21, 0.72, 0.07));

    // Set the color based on the edge intensity

    //special multipliers for different fragment types
    if(type == ENT_FRAG) grey *= pow(ENTITY_COLOR_SENS,4);
    if(type == DH_FRAG) grey *= pow(DH_COLOR_SENS,4);
    if(type == ENT_FRAG) depth *= ENTITY_DEPTH_SENS;
    if(type == DH_FRAG) depth *= DH_DEPTH_SENS;

    float sobelLine = grey > COLOR_SENS ? 1.0 : 0.0;          //color sensitivity
	float depthLine = depth > DEPTH_SENS ? 1.0 : 0.0;         //depth sensitivity

	float edge_intensity = max(depthLine, sobelLine);

    if(LIGHT_STYLE == 1){
        edge_intensity *= pow(lightData.r,0.5 * LIGHT_FACTOR);
    }
    else if(LIGHT_STYLE == 2){
        edge_intensity *= 1 - pow(lightData.r,0.5 * LIGHT_FACTOR);
    }else if(LIGHT_STYLE == 3){
        //nothing
    }

    detectionData = vec4(0.0);
    if (edge_intensity > 0.5) {// Edge detected
        if(entity > .05 && entity < 0.15) color = ENTITY_DEFAULT;
        else if(entity > .15 && entity < 0.25)color = ENEMY;
        else if(entity > .25 && entity < 0.35)color = FRIENDLY;
        else if(entity > .35 && entity < 0.45)color = PLAYER;
        else if(entity > .45 && entity < 0.55)color = PICKUP;
        else if(entity > .55 && entity < 0.65)color = vec4(0.0);    //shadow
        else color = TERRAIN;
        detectionData.r = 1.0;
    } 
 
    color = mix(texture(colortex0,texCoord), color, color.a);
    
}