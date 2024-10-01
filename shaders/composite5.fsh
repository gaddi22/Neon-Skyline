#version 460 compatibility

#include "settings.glsl"

//Bloom merge layer

in vec2 texCoord;
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //edge data
uniform sampler2D colortex3;    //edge blending

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 detectionData;

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
    vec4 edge_blend = texture(colortex3, texCoord);

    color = mix(color, edge_blend, detectionData.r);

}