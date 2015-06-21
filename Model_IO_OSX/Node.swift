//
//  Node.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import MetalKit

class Node: NSObject {
  
  var vertexBuffer: MTLBuffer?
  var vertexCount = 0
  
  var metalKitMeshes = [MTKMesh]()
  
  init(device: MTLDevice) {
    
  }
  
  func render(renderEncoder: MTLRenderCommandEncoder) {
    
  }
  
}
