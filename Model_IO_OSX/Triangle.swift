//
//  Triangle.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import MetalKit

class Triangle: Node {
  override init(device: MTLDevice) {
    super.init(device: device)

    let A = Vertex(x: -1.0, y: -1.0, z: 5.5)
    let B = Vertex(x: 0.0, y: 1.0, z: 5.5)
    let C = Vertex(x: 1.0, y: -1.0, z: 5.5)
    
    var vertices = [A, B, C]
    vertexCount = vertices.count
    vertexBuffer = device.newBufferWithBytes(&vertices, length: vertices.count * sizeof(Vertex), options: MTLResourceOptions.CPUCacheModeDefaultCache)
  }
}
