//
//  Node.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import MetalKit

protocol Transformable {
  var positionX:Float { get set }
  var positionY:Float { get set }
  var positionZ:Float { get set }
  
  var rotationX:Float { get set }
  var rotationY:Float { get set }
  var rotationZ:Float { get set }
  var scale:Float { get set }
  
  func modelMatrix() -> Matrix4
}

extension Transformable {
  func modelMatrix() -> Matrix4 {
    let matrix = Matrix4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }
}

class Node: NSObject, Transformable {
  
  var positionX:Float = 0.0
  var positionY:Float = 0.0
  var positionZ:Float = 0.0
  
  var rotationX:Float = 0.0
  var rotationY:Float = 0.0
  var rotationZ:Float = 0.0
  var scale:Float     = 1.0
  
  var vertexBuffer: MTLBuffer?
  var vertexCount = 0
  
  var metalKitMeshes = [MTKMesh]()
  
  init(device: MTLDevice) {
    
  }
  
  func render(renderEncoder: MTLRenderCommandEncoder) {
    
  }
  
}
