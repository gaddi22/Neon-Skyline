#version 460 compatibility

#include "settings.glsl"

//static Layer

in vec2 texCoord;
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //edgeData, lightData
uniform float frameTimeCounter;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 color;

// random pixel noiose based on time
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123 + frameTimeCounter);
}

void main() {
    
    color = texture(colortex0, texCoord);
    vec4 e_l_Data = texture(colortex2, texCoord);

    #ifdef EDGE_STATIC
    if(e_l_Data.r < 0.25){
        return;
    }

    float noiseStrength = 0.1;
    float noise = random(texCoord);

    // Adjust noise strength
    noise = (noise * 2.0 - 1.0) * noiseStrength * (e_l_Data.r + .25);


    vec3 staticColor = color.rgb + vec3(noise);
    color = vec4(clamp(staticColor, 0.0, 1.0), color.a);
    #endif
}