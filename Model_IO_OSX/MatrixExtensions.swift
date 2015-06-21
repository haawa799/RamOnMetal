//
//  MatrixExtensions.swift
//  Model_IO_OSX
//
//  Created by Andriy K. on 6/20/15.
//  Copyright © 2015 Andriy K. All rights reserved.
//

import Cocoa
import simd

extension float4x4 {
  
  static func matrixFromPerspective(fieldOfView : Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> float4x4 {
    
    let yScale = 1 / tanf(fieldOfView * 0.5)
    let xScale = yScale / aspectRatio
    let q = farZ / (farZ - nearZ)
    
    let column0 = float4(xScale, 0, 0, 0)
    let column1 = float4(0, yScale, 0, 0)
    let column2 = float4(0, 0, q, 1)
    let column3 = float4(0, 0, q * -nearZ, 0)
    let m = float4x4()
    var p = m.cmatrix
    p.columns = (column0 , column1 , column2 , column3)
    let pew = float4x4(p)
    return pew
  }
  
  static func makeIdentity() -> float4x4 {
    return float4x4(diagonal: float4(1))
  }
  
  static func makeScale(scale: Float) -> float4x4 {
    let vec = float3(scale)
    return makeScale(vec)
  }
  
  static func makeScale(scale: float3) -> float4x4 {
    return float4x4(diagonal: float4(scale.x, scale.y, scale.z, 1))
  }
  
  mutating func scale(scale: Float) {
    let col = cmatrix.columns
    let column0 = float4(scale,        col.0.y,      col.0.z,      col.0.w)
    let column1 = float4(col.1.x,      scale,        col.1.z,      col.1.w)
    let column2 = float4(col.2.x,      col.2.y,      scale,        col.2.w)
    let column3 = float4(col.3.x,      col.3.y,      col.3.z,      col.3.w)
    
    let m = float4x4()
    var p = m.cmatrix
    p.columns = (column0 , column1 , column2 , column3)
    let pew = float4x4(p)
    self = pew
  }
  
//  static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z) {
  
//  vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
//  float cos = cosf(radians);
//  float cosp = 1.0f - cos;
//  float sin = sinf(radians);
//  
//  return (matrix_float4x4) {
//  .columns[0] = {
//  cos + cosp * v.x * v.x,
//  cosp * v.x * v.y + v.z * sin,
//  cosp * v.x * v.z - v.y * sin,
//  0.0f,
//  },
//  
//  .columns[1] = {
//  cosp * v.x * v.y - v.z * sin,
//  cos + cosp * v.y * v.y,
//  cosp * v.y * v.z + v.x * sin,
//  0.0f,
//  },
//  
//  .columns[2] = {
//  cosp * v.x * v.z + v.y * sin,
//  cosp * v.y * v.z - v.x * sin,
//  cos + cosp * v.z * v.z,
//  0.0f,
//  },
//  
//  .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
//  }
//  };
//  }
  
}