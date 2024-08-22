#version 460 compatibility

//FSH runs for each "pixel"

uniform sampler2D gtexture; //gives the textures for all objects
uniform sampler2D lightmap; //texture of the lighting applied
uniform float rainStrength;
uniform float alphaTestRef;

in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;

// out vec4 fragColor;
/* RENDERTARGETS: 0,2,3 */

//entities
#ifdef GBUFFERS_ENTITIES
flat in int entityMask;
#endif

void main() {

    
    
    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));
    vec3 lightIntensityVec = lightColor / vec3(1/2.2);
    float lightIntensity = (lightIntensityVec.r + lightIntensityVec.g + lightIntensityVec.b) / 3.0;
    float lightIntensityInv = 1 - lightIntensity;
    // float lightFinal = max(lightIntensity,lightIntensityInv);
    float lightFinal;
    // float lightFinal = lightIntensity;


    //apply colors from texture location
    vec4 outputColorData = pow(texture(gtexture,texCoord),vec4(2.2));
    vec3 outputColor = outputColorData.rgb * pow(foliageColor * lightColor,vec3(2.2));
    float transparency = outputColorData.a;

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(transparency < alphaTestRef){
        discard;
    }

    float entity = 0;
    
    vec4 lightColorData;
    #ifdef GBUFFERS_ENTITIES
    // lightFinal = lightIntensity;   //exagerate light difference to make them more obvious
    lightFinal = lightIntensityInv / 10;   //exagerate light difference to make them more obvious
    lightColorData = vec4(vec3(lightFinal),1.0);

    if(entityMask == 4) transparency = 0.3;


    entity = 0.1;
    entity = entityMask == 1 ? 0.2 : entity; // Hostile mobs
    entity = entityMask == 2 ? 0.3 : entity; // Friendly mobs
    entity = entityMask == 3 ? 0.4 : entity; // Players
    entity = entityMask == 4 ? 0.5 : entity; // Shadows

    #else
    lightColorData =  vec4(lightIntensityInv);
    // lightColorData = vec4(vec3((lightIntensityInv * outputColor)),1.0) ;
    // lightColorData = outputColorData;
	#endif

    #ifdef GBUFFERS_SKYTEXTURED
    entity = 0.4;
    #endif

    #ifdef GBUFFERS_WEATHER 
    entity = 1;
    #endif

    #ifdef GBUFFERS_BEAM
    transparency = 0.03;
    #endif

    //scale sun with rain
    #ifdef GBUFFERS_SKYTEXTURED
    transparency *= (1/rainStrength) - 3;
    #endif
    // outColor0 = vec4(1);    //puts 1 for all values, creating a white pixel with full visibility
    gl_FragData[0] = pow(vec4(outputColor,transparency),vec4(1/2.2));   //original
    gl_FragData[1] = lightColorData;                                   //Alt lighting
    gl_FragData[2] = vec4(entity,0.0,0.0,1.0);                          //entity data

}
