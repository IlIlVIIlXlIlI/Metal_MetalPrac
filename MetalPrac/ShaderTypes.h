#ifndef SHADER_TYPES_H
#define SHADER_TYPES_H

#include <simd/simd.h>

enum
{
    kShaderVertexInputIndexVertices       = 0,
    kShaderVertexInputIndexViewportSize   = 1,
};

typedef struct
{
    vector_float2 position;
    vector_float4 color;
    
} ShaderVertex;

#endif /* SHADER_TYPES_H */
