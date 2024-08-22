#version 460 

uniform sampler2D depthtex0;    //depthmap
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //lighting/edge data
uniform sampler2D colortex3;    //fragment type
uniform float viewHeight;
uniform float viewWidth;

uniform mat4 gbufferProjection;

in vec2 texCoord;

/* DRAWBUFFERS */
layout(location = 0) out vec4 color;

/*  Radar Colors */
vec3 ENEMY = vec3(1.0,0.0,0.0);
vec3 PLAYER = vec3(0.0,1.0,0.0); 
vec3 FRIENDLY = vec3(0.0,1.0,1.0); 
vec3 ENTITY_DEFAULT = vec3(1.0,1.0,0.0); 
vec3 TERRAIN = vec3(.3,.15,0.0);

void make_kernel(inout vec4 n[9], sampler2D tex, vec2 coord, float width, float height)
{
	float w = 1.0 / width;
	float h = 1.0 / height;

	n[0] = texture2D(tex, coord + vec2( -w, -h));
	n[1] = texture2D(tex, coord + vec2(0.0, -h));
	n[2] = texture2D(tex, coord + vec2(  w, -h));
	n[3] = texture2D(tex, coord + vec2( -w, 0.0));
	n[4] = texture2D(tex, coord);
	n[5] = texture2D(tex, coord + vec2(  w, 0.0));
	n[6] = texture2D(tex, coord + vec2( -w, h));
	n[7] = texture2D(tex, coord + vec2(0.0, h));
	n[8] = texture2D(tex, coord + vec2(  w, h));
}

// depth is the value you read from the depth buffer
// near is the near plane distance
// far is the far plane distance
// Ideally the last two should come from the projection matrix
float linearizeDepthFast(float depth, float near, float far) {
    return (near * far) / (depth * (near - far) + far);
}

void main() {

    float entity_min = 0.05;
    float entity_max = 0.6;

    // Set the color based on the edge intensity
    float entity = texture(colortex3,texCoord).r;
    vec4 lightData = texture(colortex2,texCoord);
    float depth = texture(depthtex0, texCoord).r;

    //get far and near from projection matrix
    float far = gbufferProjection[3][2] / (gbufferProjection[2][2] + 1.0);
    float near = far * (gbufferProjection[2][2] + 1.0) / (gbufferProjection[2][2] - 1.0);

    depth = linearizeDepthFast(depth, near, far);

    if (entity > entity_max){ //things that should not be edgedetected (sky, weather)
        color = texture(colortex0,texCoord);
        return;
    }
    // Edge detection from Hebali/GlslSobel.frag
    vec4 n[9];
    if(entity > entity_min && entity < entity_max) {
        make_kernel(n, colortex2, texCoord, viewWidth, viewHeight);
        // for(int i = 0; i<9;i++){
        //     n[i] *= pow(2,2) * (lightData.r + .001);
        // }
    }
    else{
        make_kernel(n, depthtex0, texCoord, viewWidth, viewHeight);
        for(int i = 0; i<9;i++){
            // n[i] = (n[i] * (lightData.r) + ( n[i] * (depth))  );
            n[i] *= ((lightData.r)) * (depth/2);
            // n[i] = (n[i] * (lightData.r) * (depth));

        }
    }

    vec4 sobel_edge_h = n[2] + (2.0 * n[5]) + n[8] - (n[0] + (2.0 * n[3]) + n[6]);
    vec4 sobel_edge_v = n[0] + (2.0 * n[1]) + n[2] - (n[6] + (2.0 * n[7]) + n[8]);

    // Calculate the magnitude of the gradient
    vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));

    // Threshold to determine if an edge is present
    float edge_threshold; // You can adjust this value
    if(entity > entity_min && entity < entity_max) edge_threshold = 0.2;
    else edge_threshold = .01;

    float edge_intensity = length(sobel.rgb);


    if (edge_intensity > edge_threshold) {// Edge detected
        if(entity > .05 && entity < 0.15) color = vec4(ENTITY_DEFAULT, 1.0);
        else if(entity > .15 && entity < 0.25)color = vec4(ENEMY, 1.0);
        else if(entity > .25 && entity < 0.35)color = vec4(FRIENDLY, 1.0);
        else if(entity > .35 && entity < 0.45)color = vec4(PLAYER, 1.0);
        else if(entity > .45 && entity < 0.55)color = vec4(0.0);            //shadow
        else color = vec4(TERRAIN,1.0);
    } else {
        color = texture(colortex0,texCoord); // No edge detected
        // color = texture(depthtex2,texCoord); // No edge detected
    }

    
}