#version 460 compatibility

//FSH runs for each "pixel"

#include "settings.glsl"

//Drawbuffers store data for our shader going forward\
/* RENDERTARGETS: 0,2,3,4 */
out vec4 fragColor;

uniform sampler2D lightmap; //texture of the lighting applied
uniform sampler2D depthtex0;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

in vec2 lightMapCoords;
in vec4 blockColor;
in vec3 viewSpacePosition;
in vec3 normal;

void main() {

    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));

    lightColor = max(lightColor,ambient_min.rgb);

    vec3 lightIntensityVec = lightColor / vec3(1/2.2);
    float lightIntensity = ((lightIntensityVec.r + lightIntensityVec.g + lightIntensityVec.b) / 3.0);
    float lightIntensityInv = 1 - lightIntensity;


    //apply colors from texture location
    vec4 outputColorData = blockColor;
    vec3 outputColor = pow(outputColorData.rgb, vec3(2.2)) * pow(lightColor,vec3(2.2));
    float transparency = outputColorData.a;

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(transparency < .1){
        discard;
    }

    //throw out dh_blocks if they are not exposed
    vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth,viewHeight);
    float depth = texture(depthtex0,texCoord).r;
    if(depth != 1.0){
        discard;
    }

    //fog effect
    float distanceFromCamera = distance(vec3(0), viewSpacePosition);

    float maxFogDistance = fogEnd;
    float minFogDistance = fogStart;

    float maxDepthDistance = 4000;
    float minDepthDistance = 80;

    float fogBlendValue = clamp((distanceFromCamera - minFogDistance)/ (maxFogDistance - minFogDistance),0,1);

    float depthLineValue = clamp((distanceFromCamera - minDepthDistance)/ (maxDepthDistance - minDepthDistance),0,1);

    if(depthLineValue < 0.01) discard;

    outputColor = mix(outputColor, pow(fogColor, vec3(2.2)), fogBlendValue);

    fragColor = pow(vec4(outputColor, transparency),vec4(1.0 / 2.2));

    float fragmentType = 0.01;

    gl_FragData[0] = pow(vec4(outputColor,transparency),vec4(1/2.2));   //original
    gl_FragData[1] = vec4(lightIntensityInv,0.0,0.0,1.0);                           //Light Data
    gl_FragData[2] = vec4(fragmentType,depthLineValue,fogBlendValue,1.0);   //frag data
    gl_FragData[3] = vec4(normal,1.0);   //normal data

}
