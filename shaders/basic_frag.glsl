#version 460 compatibility

//FSH runs for each "pixel"

uniform sampler2D gtexture; //gives the textures for all objects
uniform sampler2D lightmap; //texture of the lighting applied

in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;

// out vec4 fragColor;

//entities
#ifdef GBUFFERS_ENTITIES
flat in int entityMask;
#endif

void main() {
    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));

    //apply colors from texture location
    vec4 outputColorData = pow(texture(gtexture,texCoord),vec4(2.2));
    vec3 outputColor = outputColorData.rgb * pow(foliageColor * lightColor,vec3(2.2));
    float transparency = outputColorData.a;

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(transparency < 0.1){
        discard;
    }

    float entity = 0;
    #ifdef GBUFFERS_ENTITIES
    entity = entityMask == 1 ? 0.1 : entity; // Hostile mobs
    entity = entityMask == 2 ? 0.2 : entity; // Friendly mobs
    entity = entityMask == 3 ? 0.3 : entity; // Players
	#endif

    // outColor0 = vec4(1);    //puts 1 for all values, creating a white pixel with full visibility
    gl_FragData[0] = pow(vec4(outputColor,transparency),vec4(1/2.2));
    gl_FragData[1] = vec4(entity);
}
