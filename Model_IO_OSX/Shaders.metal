//
//  Shaders.metal
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  float4 position [[position]];
  float4 color;
};

struct Vertex {
  float3 position [[attribute(0)]];
};

struct Uniforms {
  float4x4 projectionMatrix;
  float4x4 modelViewMatrix;
};

vertex VertexOut vertexShader(const Vertex vertexIn [[stage_in]],
                              constant Uniforms& uniformBuffer [[buffer(1)]],
                                unsigned        int        vid           [[vertex_id]])
{
  float4x4 projectionMatrix = uniformBuffer.projectionMatrix;
  float4x4 modelViewMatrix = uniformBuffer.modelViewMatrix;
  float3 position = vertexIn.position;
  position.z = 5;
  
  float4 fragmentPosition = modelViewMatrix * float4(position, 1.0);
  
  VertexOut vertexOut;
  vertexOut.position = projectionMatrix * fragmentPosition;
  vertexOut.color = float4(1.0);
  return vertexOut;
}


fragment float4 fragmentShader(VertexOut interpolated [[stage_in]])
{
  return interpolated.color;
}