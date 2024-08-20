#version 460 compatibility

uniform sampler2D colortex0;
in vec4 colortex1; //entity
uniform float viewHeight;
uniform float viewWidth;

in vec2 texCoord;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 color;


/*  Radar Colors */
vec3 ENEMY = vec3(1.0,0.0,0.0);
vec3 FRIENDLY = vec3(0.0,1.0,0.0); 
vec3 PLAYER = vec3(0.0,1.0,.4); 
vec3 TERRAIN = vec3(1.0,.4,0.0);

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

void main() {

    // Edge detection from Hebali/GlslSobel.frag
    vec4 n[9];
    make_kernel(n, colortex0, texCoord, viewWidth, viewHeight);

    vec4 sobel_edge_h = n[2] + (2.0 * n[5]) + n[8] - (n[0] + (2.0 * n[3]) + n[6]);
    vec4 sobel_edge_v = n[0] + (2.0 * n[1]) + n[2] - (n[6] + (2.0 * n[7]) + n[8]);

    // Calculate the magnitude of the gradient
    vec4 sobel = sqrt((sobel_edge_h * sobel_edge_h) + (sobel_edge_v * sobel_edge_v));

    // Threshold to determine if an edge is present
    float edge_threshold = .6; // You can adjust this value
    float edge_intensity = length(sobel.rgb);

    // Set the color based on the edge intensity
    int entity = int(colortex1.a);

    if (edge_intensity > edge_threshold) {// Edge detected
        if(entity == 1) {
            color = vec4(ENEMY, 1.0);
        }
        else if(entity == 2) {
            color = vec4(FRIENDLY, 1.0);
        }
        else if(entity == 3) {
            color = vec4(PLAYER, 1.0);
        } else {
            color = vec4(TERRAIN,1.0);
        }
    } else {
        color = texture(colortex0,texCoord); // No edge detected, transparent
    }
}