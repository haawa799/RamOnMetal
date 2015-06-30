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
  float  occlusion;
  float3 normal;
  float2 texCoords;
};

struct Vertex {
  float3 position  [[attribute(0)]];
  float  occlusion [[attribute(1)]];
  float3 normal    [[attribute(2)]];
  float2 texCoords [[attribute(3)]];
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
  
  float4 fragmentPosition = float4(position, 1.0);
  
  VertexOut vertexOut;
  vertexOut.position = projectionMatrix * modelViewMatrix * fragmentPosition;
  vertexOut.color = float4(1.0);
  vertexOut.occlusion = vertexIn.occlusion;
  vertexOut.normal = vertexIn.normal;
  vertexOut.texCoords = vertexIn.texCoords;
  return vertexOut;
}


fragment float4 fragmentShader(VertexOut interpolated [[stage_in]], texture2d<float>  tex2D     [[ texture(0) ]],
                               // 4
                               sampler           sampler2D [[ sampler(0) ]])
{
  float3 lightDirection = normalize(float3(0.0, 0.0, 1.0));
  float3 normal = normalize(interpolated.normal);
  
  //Get diffuse color
  float diffuseFactor = max(-dot(normal,lightDirection),0.0);
  float4 diffuseColor = {1.0,1.0,1.0,1.0};
  for (int i = 0; i<3; i++)
  {
    diffuseColor[i] *= diffuseFactor * 1.0;
  }
  
  float4 q = interpolated.color * interpolated.occlusion;
  q.a = 1.0;
  
  return q;//tex2D.sample(sampler2D, interpolated.texCoords);
}