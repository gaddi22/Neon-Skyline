#version 460 compatibility

//FSH runs for each "pixel"
uniform sampler2D gtexture; //gives the textures for all objects
uniform sampler2D lightmap; //texture of the lighting applied
uniform float rainStrength;
uniform float alphaTestRef;

in vec2 texCoord;
in vec4 foliageColor;
in vec2 lightMapCoords;

// out vec4 fragColor;
/* RENDERTARGETS: 0,2,3 */

//entities
#ifdef GBUFFERS_ENTITIES
in float shadow_light_strength;
flat in int entityMask;
#endif

void main() {

    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec4 lightColor = pow(texture(lightmap,lightMapCoords),vec4(2.2));

    vec4 lightIntensityVec = lightColor / vec4(1/2.2);  //we can use this intensity for edge detection
    float lightIntensity = (lightIntensityVec.r + lightIntensityVec.g + lightIntensityVec.b) / 3.0;
    float lightIntensityInv = 1 - lightIntensity;

    //apply colors from texture location
    vec4 outputColorData = texture(gtexture,texCoord) * foliageColor * lightColor;

    float entity = 0;
    
    vec4 lightColorData;

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
    lightColorData =  vec4(lightIntensityInv);

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(outputColorData.a < alphaTestRef){
        discard;
    }

    #ifdef GBUFFERS_WEATHER 
        entity = 1;
    #endif

    //fade sun with rain
    #ifdef GBUFFERS_SKYTEXTURED
        entity = 1;
    #endif

    gl_FragData[0] = outputColorData;           //original
    gl_FragData[1] = lightColorData;            //Alt lighting
    gl_FragData[2] = vec4(entity,vec2(0.0),1.0);       //fragment type
}
