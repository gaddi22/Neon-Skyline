#version 460 compatibility

//VSH files are processed per vertex. 
//Position inputs start in model space while the render wants them in clip space

out vec4 blockColor; 
out vec3 viewSpacePosition;
out vec2 lightMapCoords;

out vec3 normal;

void main(){

    // normal = gl_NormalMatrix * gl_Normal;
    normal = gl_Normal;
    blockColor = gl_Color;  //pass color to fragment
    lightMapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    viewSpacePosition = (gl_ModelViewMatrix * gl_Vertex).xyz;

    //convert from model space to clip space
    gl_Position = ftransform();

}