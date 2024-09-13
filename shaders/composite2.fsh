#version 460 compatibility

#include "settings.glsl"

//Thickness layer

in vec2 texCoord;
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //edge data


/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 detectionData;


void main() {
	vec4 edgeColor = vec4(0.0);

	// vec4 detectionData = texture(colortex2,texCoord);
	#ifdef THICKER_LINES
		vec4[4] adjacentDetection;
		vec4[4] adjacentColor;
		vec2 offset = pixelSize * vec2(0, 1);	//up
		adjacentDetection[0] = texture(colortex2,texCoord + offset);
		adjacentColor[0] = texture(colortex0,texCoord + offset);
		offset = pixelSize * vec2(0, -1);	//down
		adjacentDetection[1] = texture(colortex2,texCoord + offset);
		adjacentColor[1] = texture(colortex0,texCoord + offset);
		offset = pixelSize * vec2(-1, 0);	//left
		adjacentDetection[2] = texture(colortex2,texCoord + offset);
		adjacentColor[2] = texture(colortex0,texCoord + offset);
		offset = pixelSize * vec2(1, 0);	//right
		adjacentDetection[3] = texture(colortex2,texCoord + offset);
		adjacentColor[3] = texture(colortex0,texCoord + offset);

		for(int i = 0; i < 4; i++){
			if(adjacentDetection[i].r > 0.5){
				edgeColor = adjacentColor[i];
				detectionData.r = 1.0;	//now this fragment is also an edge
				break;
			}
		}

	#endif
    color = mix(texture(colortex0,texCoord), edgeColor, edgeColor.a);
}