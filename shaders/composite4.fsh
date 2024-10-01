#version 460 compatibility

#include "settings.glsl"

//Bloom tall layer

in vec2 texCoord;
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //edge data
uniform sampler2D colortex3;    //edge blending

/* RENDERTARGETS: 0,2,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 detectionData;
layout(location = 2) out vec4 edge_blend;

const float search_kernel[] = float[](0.1, 0.2, 0.3, 0.4, 0.5, 1.0, 0.5, 0.4, 0.3, 0.2, 0.1);
// const float search_kernel[] = float[](0.9, 0.9, 0.9, 0.9, 0.5, 1.0, 0.5, 0.9, 0.9, 0.9, 0.9);


void main() {
    // Read the base color from colortex0
    color = texture(colortex0, texCoord);

    //ignore edges themselves
    detectionData = texture(colortex2, texCoord);
    if(detectionData.r == 1.0){
        return;
    }

    #ifndef EDGE_BLOOM
    return;
    #endif

    edge_blend = texture(colortex3,texCoord);
    for(int i = 0; i < 11; i++){
        vec2 offset = pixelSize * vec2(0,i - 5);

        float sample_edge_data = texture(colortex2,texCoord + offset).r;
        vec4 sample_color = texture(colortex0, texCoord + offset);

        detectionData.r = mix(detectionData.r, sample_edge_data.r, search_kernel[i] * sample_edge_data.r);

        edge_blend = mix(edge_blend, sample_color, search_kernel[i] * sample_edge_data.r);
    
    }
    
}