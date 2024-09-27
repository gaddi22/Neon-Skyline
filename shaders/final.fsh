#version 460 compatibility

#include "settings.glsl"

//final Layer

in vec2 texCoord;
uniform sampler2D colortex0;    //vanilla-like
uniform float frameTimeCounter;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    
    color.rgb = pow(color.rgb, vec3(1.0/2.2));
}