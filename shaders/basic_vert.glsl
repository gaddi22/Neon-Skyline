#version 460 compatibility
//VSH files are processed per vertex. 
//Position inputs start in model space while the render wants them in clip space

//fttransform() is a shorthand to do this conversion
uniform vec3 cameraPosition;
uniform mat3 normalMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;

out vec2 texCoord;
out vec4 foliageColor; 
out vec2 lightMapCoords;
out vec3 viewSpacePosition;


//Entity checking
#ifdef GBUFFERS_ENTITIES
uniform int entityId;

out float shadow_light_strength;
flat out int entityMask;
#endif

out vec3 normal;

void main(){

    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;       //pass texture locations to fragment
    foliageColor = gl_Color; //pass biome color to fragment
    lightMapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    //convert from model space to clip space
    // gl_Position = ftransform();
    gl_Position = ftransform();   //gl_position: expected output of vsh file. position on screen //1: perspective
    viewSpacePosition = gl_Position.xyz;

    normal = gl_Normal;
    #ifdef GBUFFERS_ENTITIES
    //entities are brightest on top, brighter in z directions, and darker in x directions
    const float light_dir_min = 0.02;
    shadow_light_strength = max(dot(normal, vec3(0, 6.00, 0)), light_dir_min) + 
                        max(dot(normal, vec3(0, 0, 0.95)), light_dir_min) + 
                        max(dot(normal, vec3(0, 0, -0.95)), light_dir_min);
    shadow_light_strength = clamp(shadow_light_strength / 3.0, light_dir_min+0.03, 1.0);

	entityMask = entityId;
	#endif

}