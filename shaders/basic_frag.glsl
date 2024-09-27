#version 460 compatibility

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
/* RENDERTARGETS: 0,4,2,3 */

layout(location = 0) out vec4 color;
layout(location = 1) out vec4 normalData;
layout(location = 2) out vec4 lightColorData;
layout(location = 3) out vec4 fragData;


//entities
#ifdef GBUFFERS_ENTITIES
in float shadow_light_strength;
flat in int entityMask;
#endif

void main() {
    color = texture(gtexture,texCoord);
    color.rgb = pow(color.rgb, vec3(2.2));
    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec4 lightColor = pow(texture(lightmap,lightMapCoords),vec4(2.2));

    vec4 lightIntensityVec = lightColor;  //we can use this intensity for edge detection
    float lightIntensity = (lightIntensityVec.r + lightIntensityVec.g + lightIntensityVec.b) / 3.0;
    float lightIntensityInv = 1 - lightIntensity;

    //apply colors from texture location
    color *= foliageColor * lightColor;

    float entity = 0;
    
    vec4 lightColorData;

    #ifdef GBUFFERS_ENTITIES

        //Entity lighting
        color.rgb *= shadow_light_strength;
        // outputColorData.rgb *= shadow_light_strength;

        entity = 0.1;
        entity = entityMask == 1 ? 0.2 : entity; // Hostile mobs
        entity = entityMask == 2 ? 0.3 : entity; // Friendly mobs
        entity = entityMask == 3 ? 0.4 : entity; // Players
        entity = entityMask == 4 ? 0.5 : entity; // Pickups
        entity = entityMask == 5 ? 0.6 : entity; // Shadows


    #endif
    lightColorData =  vec4(lightIntensityInv);

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(color.a < alphaTestRef){
        discard;
    }

    #ifdef GBUFFERS_WEATHER 
        entity = 1;
    #endif

    float fogBlendValue = 0;
    //fade sun with rain
    #ifdef GBUFFERS_SKYTEXTURED
        entity = 1;
    #else
        //fog
        float distanceFromCamera = distance(vec3(0), viewSpacePosition);
        fogBlendValue = clamp((distanceFromCamera - fogStart)/ (fogEnd - fogStart),0,1);
        color.rgb = mix(color.rgb, fogColor, fogBlendValue);
    #endif

    normalData = vec4(normal,(1.0));        //normal
    fragData = vec4(entity,0.0,fogBlendValue,1.0);       //fragment type, fog
}
