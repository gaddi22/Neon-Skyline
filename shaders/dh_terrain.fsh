#version 460 compatibility

//FSH runs for each "pixel"

//Drawbuffers store data for our shader going forward\
/* RENDERTARGETS: 0,2,3*/
out vec4 fragColor;

uniform sampler2D lightmap; //texture of the lighting applied
uniform sampler2D depthtex0;
uniform float viewHeight;
uniform float viewWidth;
uniform vec3 fogColor;

in vec2 lightMapCoords;
in vec4 blockColor;
in vec3 viewSpacePosition;

void main() {

    //lookup lightcolor in the light map and apply that color to the object
    //pow operations linearize the values
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));
    vec3 lightIntensityVec = lightColor / vec3(1/2.2);
    float lightIntensityInv = 1 - ((lightIntensityVec.r + lightIntensityVec.g + lightIntensityVec.b) / 3.0);



    //apply colors from texture location
    vec4 outputColorData = blockColor;
    vec3 outputColor = pow(outputColorData.rgb, vec3(2.2)) * (lightColor - 0.04 );
    float transparency = outputColorData.a;

    //if transparency is low, throw this fragment out so the one behind can be drawn
    if(transparency < .1){
        discard;
    }

    // outColor0 = vec4(1);    //puts 1 for all values, creating a white pixel with full visibility

    //through out dh_blocks if they are not exposed
    vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth,viewHeight);
    float depth = texture(depthtex0,texCoord).r;
    if(depth != 1.0){
        discard;
    }

    // Sample the depth texture at the fragment's screen-space coordinates
    // vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    // float depth = texture(depthtex0, texCoord).r;

    // // Compare the sampled depth with the current fragment's depth
    // // This assumes the depth values are linear and comparable directly
    // if (depth != gl_FragCoord.z) {
    //     discard;  // Discard fragments that are behind others
    // }

    //use fog to maske the off color from distant horizons
    float distanceFromCamera = distance(vec3(0), viewSpacePosition);

    float maxFogDistance = 4000;
    float minFogDistance = 300;
    // float maxFogDistance = 400;
    // float minFogDistance = 300;


    float fogBlendValue = clamp((distanceFromCamera - minFogDistance)/ (maxFogDistance - minFogDistance),0,1);

    outputColor = mix(outputColor, pow(fogColor, vec3(2.2)), fogBlendValue);

    fragColor = pow(vec4(outputColor, transparency),vec4(1.0 / 2.2));

    outputColorData = vec4(vec3((lightIntensityInv * outputColor)),1.0);


    gl_FragData[0] = pow(vec4(outputColor,transparency),vec4(1/2.2));   //original
    gl_FragData[1] = outputColorData;                                   //no lighting
    gl_FragData[2] = vec4(0.0,0.0,0.0,1.0);               //entity data

}
