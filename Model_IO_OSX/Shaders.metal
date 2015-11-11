//
//  Shaders.metal
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

//#include <metal_stdlib>
#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_texture>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_graphics>

using namespace metal;

struct VertexOut {
  float4 position [[position]];
  float4 color;
  float  occlusion;
  float2 texCoords;
  
  bool occlusionEnabled;
  bool textureEnabled;
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
  bool occlusionEnabled;
  bool textureEnabled;
};

vertex VertexOut vertexShader(const    Vertex    vertexIn      [[stage_in]],
                              constant Uniforms &uniformBuffer [[buffer(1)]],
                              unsigned int       vid           [[vertex_id]])
{
  float4x4 projectionMatrix = uniformBuffer.projectionMatrix;
  float4x4 modelViewMatrix = uniformBuffer.modelViewMatrix;
  float3 position = vertexIn.position;
  
  float4 fragmentPosition = float4(position, 1.0);
  
  VertexOut vertexOut;
  vertexOut.position = projectionMatrix * modelViewMatrix * fragmentPosition;
  vertexOut.occlusion = vertexIn.occlusion;
  vertexOut.texCoords = vertexIn.texCoords;
  vertexOut.color = float4(1.0,1.0,1.0,1.0);
  
  vertexOut.occlusionEnabled = uniformBuffer.occlusionEnabled;
  vertexOut.textureEnabled = uniformBuffer.textureEnabled;
  
  return vertexOut;
}


fragment float4 fragmentShader(VertexOut         interpolated [[stage_in]],
                               texture2d<float>  tex2D        [[texture(0)]],
                               sampler           sampler2D    [[sampler(0)]])
{
  float4 finalColor = interpolated.color;
  if (interpolated.occlusionEnabled) {
    finalColor *= interpolated.occlusion;
  }
  if (interpolated.textureEnabled) {
    finalColor *= tex2D.sample(sampler2D, interpolated.texCoords);
  }
  
  return finalColor;
}