#version 460 compatibility

#include "settings.glsl"

//FSH runs for each "pixel"
uniform sampler2D gtexture; //gives the textures for all objects
uniform sampler2D lightmap; //texture of the lighting applied
uniform float rainStrength;
uniform float alphaTestRef;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;


in vec2 texCoord;
in vec4 foliageColor;
in vec2 lightMapCoords;
in vec3 viewSpacePosition;
in vec3 normal;

// out vec4 fragColor;
/* RENDERTARGETS: 0,2,3,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightColorData;
layout(location = 2) out vec4 fragData;
layout(location = 3) out vec4 normalData;

//entities
#ifdef GBUFFERS_ENTITIES
in float shadow_light_strength;
flat in int entityMask;
#endif

void main() {

    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec4 lightColor = pow(texture(lightmap,lightMapCoords),vec4(2.2));
    lightColor.rgb = max(lightColor.rgb,ambient_min.rgb);

    vec4 lightIntensityVec = lightColor / vec4(1/2.2);  //we can use this intensity for edge detection
    float lightIntensity = (lightIntensityVec.r + lightIntensityVec.g + lightIntensityVec.b) / 3.0;
    float lightIntensityInv = 1 - lightIntensity;

    //apply colors from texture location
    vec4 outputColorData = texture(gtexture,texCoord) * foliageColor * lightColor;

    float entity = 0;

    #ifdef GBUFFERS_ENTITIES

        //Entity lighting
        outputColorData.rgb = pow(pow(outputColorData.rgb,vec3(2.2)) * pow(shadow_light_strength,1/2.2),vec3(1/2.2));

        entity = 0.1;
        entity = entityMask == 1 ? 0.2 : entity; // Hostile mobs
        entity = entityMask == 2 ? 0.3 : entity; // Friendly mobs
        entity = entityMask == 3 ? 0.4 : entity; // Players
        entity = entityMask == 4 ? 0.5 : entity; // Pickups
        entity = entityMask == 5 ? 0.6 : entity; // Shadows


    #endif
    lightColorData =  vec4(lightIntensityInv,0.0,0.0,1.0);

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(outputColorData.a < alphaTestRef){
        discard;
    }

    #ifdef GBUFFERS_WEATHER 
        entity = 1;
    #endif

    float fogBlendValue = 0;
    #ifdef GBUFFERS_SKYTEXTURED
        entity = 1;
    #else
        //fog
        float distanceFromCamera = distance(vec3(0), viewSpacePosition);
        fogBlendValue = clamp((distanceFromCamera - fogStart)/ (fogEnd - fogStart),0,1);
        outputColorData.rgb = mix(outputColorData.rgb, fogColor, fogBlendValue);
    #endif

    color = outputColorData;           //original
    normalData = vec4(normal,1.0);
    fragData = vec4(entity,0.0,fogBlendValue,1.0);       //fragment type
}
