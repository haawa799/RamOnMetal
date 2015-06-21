//
//  Scene.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import Foundation
import MetalKit
import simd

class Scene: NSObject {
  
  var children: [Node]
  var projectionMatrix = float4x4.makeIdentity()
  var bufferProvider: BufferProvider
  private var triangleVertexBuffer: MTLBuffer!
  
  init(device: MTLDevice) {
    bufferProvider = BufferProvider(inFlightBuffers: 3, device: device)
    children = [Node]()
  }
  
  func render(commandQ: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentMVMatrix: float4x4, completionBlock: MTLCommandBufferHandler?) {
    
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    let commandBuffer = commandQ.commandBuffer()
    let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
    //
    renderEncoder.setRenderPipelineState(pipelineState)
    
    let modelViewMatrix = float4x4.makeIdentity()
    let uniformsBuffer = bufferProvider.bufferWithMatrices(projectionMatrix, modelViewMatrix: modelViewMatrix)
    
    renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, atIndex: 1)
    
    for child in children {
      child.render(renderEncoder)
    }
    
    renderEncoder.endEncoding()
    if let completionBlock = completionBlock {
      commandBuffer.addCompletedHandler(completionBlock)
    }
    
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
    
  }
  
}
