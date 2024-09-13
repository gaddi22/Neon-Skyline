#version 460 
//VSH files are processed per vertex. 
//Position inputs start in model space while the render wants them in clip space

//fttransform() is a shorthand to do this conversion
uniform mat3 normalMatrix;;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;
uniform vec3 chunkOffset;               //required to render terrain textures. if it is not terrain, this is zero making it safe for other vsh files

in vec3 vaPosition; //vertex position
in vec2 vaUV0;      //texture coordinates
in vec4 vaColor;    //Biome based colors
in ivec2 vaUV2;     //lighting information, ivec is int instead of float

out vec2 texCoord;
out vec4 foliageColor; 
out vec2 lightMapCoords;
out vec3 viewSpacePosition;

//Entity checking
#ifdef GBUFFERS_ENTITIES
uniform int entityId;
in uniform vec3 shadowLightPosition;

out float shadow_light_strength;
flat out int entityMask;
#endif

void main(){

    texCoord = vaUV0;       //pass texture locations to fragment
    foliageColor = vaColor; //pass biome color to fragment
    lightMapCoords = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);

    //convert from model space to clip space
    // gl_Position = ftransform();
    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition + chunkOffset,1);   //gl_position: expected output of vsh file. position on screen //1: perspective
    viewSpacePosition = gl_Position.xyz;

    #ifdef GBUFFERS_ENTITIES
    shadow_light_strength = max(dot(shadowLightPosition, vec3(0, 1, 0)), 0.1);
	entityMask = entityId;
    #else

	#endif
    
}