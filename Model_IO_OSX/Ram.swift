//
//  Ram.swift
//  Model_IO
//
//  Created by Andriy K. on 6/12/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import Cocoa
import MetalKit
import ModelIO

class Ram: Node {
  
  override init(device: MTLDevice) {
    super.init(device: device)
    load(device)
  }
  
  func load(device: MTLDevice) {
    
    let modelIOVertexDesc = MDLVertexDescriptor()
    if let attribute = modelIOVertexDesc.attributes[0] as? MDLVertexAttribute {
      attribute.name = MDLVertexAttributePosition
      attribute.format = MDLVertexFormat.Float3
      //        attribute.bufferIndex = 0
    }
    if let layout = modelIOVertexDesc.layouts[0] as? MDLVertexBufferLayout {  // this zero correspons to  buffer index
      layout.stride = sizeof(Float) * 3
    }
    
    let url = NSBundle.mainBundle().URLForResource("ram", withExtension: "obj")!
    let asset = MDLAsset(URL: url, vertexDescriptor: modelIOVertexDesc, bufferAllocator: nil)
    
    metalKitMeshes = MTKMesh.meshesFromAsset(asset, device: device)
    for mesh in metalKitMeshes {
    }
  }
  
  override func render(renderEncoder: MTLRenderCommandEncoder) {
    for mesh in metalKitMeshes {
      if let vertexBuf = mesh.vertexBuffers.first {
        renderEncoder.setVertexBuffer(vertexBuf.buffer, offset: vertexBuf.offset, atIndex: 0)
        for submesh in mesh.submeshes {
          renderEncoder.drawIndexedPrimitives(submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
      }
    }
  }
  
}
