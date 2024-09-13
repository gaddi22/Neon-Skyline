#version 460 compatibility

#include "settings.glsl"

//Bloom Layer

in vec2 texCoord;
uniform sampler2D colortex0;    //vanilla-like
uniform sampler2D colortex2;    //edge data


/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 detectionData;


// Function to compute the direction vectors for circular expansion
vec2 getDirectionVector(float angle) {
    return vec2(cos(angle), sin(angle));
}

void main() {
    //ignore edges themselves
    vec4 thisEdgeData = texture(colortex2, texCoord);
    detectionData = thisEdgeData;
    if(thisEdgeData.r > 0.5){
        color = texture(colortex0,texCoord);
        return;
    }

    #ifndef EDGE_BLOOM
    else{
        color = texture(colortex0,texCoord);
        return;
    }
    #endif

// Read the base color from colortex0
    vec4 baseColor = texture(colortex0, texCoord);
    vec4 edgeColor = vec4(0.0);

    int maxRadius = 10;
    float closestDistance = maxRadius + 1.0;

    // search from pixel outwards
    for (float r = 1.0; r <= maxRadius; r++) {
        // Calculate the number of samples for this radius
        int samples = int(2.0 * 3.141592 * r);
        
        // Loop over the samples (points on the circle)
        for (int i = 0; i < samples; i++) {

            float angle = (float(i) / float(samples)) * 2.0 * 3.141592;  // Calculate the angle for this sample
            vec2 direction = getDirectionVector(angle);  // Get the direction vector for this angle
            vec2 offset = direction * r * pixelSize;     // Offset by the radius and pixel size
            vec4 edgeData = texture(colortex2, texCoord + offset);  // Sample the edge texture at the offset
            
            // edge found
            if (edgeData.r > 0.5) {
                closestDistance = r;   // Save the distance
                edgeColor = texture(colortex0, texCoord + offset);
                break;
            }
        }

        if (closestDistance <= r) {
            break;  // Edge is found, stop searching
        }
    }

    // Blend the colors based on the distance to the closest edge
    if (closestDistance <= maxRadius) {
        float blendFactor = 0.75 - clamp(closestDistance/maxRadius,0.0,.75);
        color = mix(baseColor, edgeColor, blendFactor);
        detectionData.r = blendFactor;
    } else {
        color = baseColor;  // No edge found, use the base color
    }
    
}