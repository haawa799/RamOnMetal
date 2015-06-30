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

class Scene: NSObject, Transformable {
  
  var positionX:Float = 0.0
  var positionY:Float = 0.0
  var positionZ:Float = 0.0
  
  var rotationX:Float = 0.0
  var rotationY:Float = 0.0
  var rotationZ:Float = 0.0
  var scale:Float     = 1.0
  
  var children: [Node]
  var projectionMatrix = Matrix4()
  var bufferProvider: BufferProvider
  private var triangleVertexBuffer: MTLBuffer!
  
  init(device: MTLDevice) {
    bufferProvider = BufferProvider(inFlightBuffers: 3, device: device)
    children = [Node]()
  }
  
  func render(commandQ: MTLCommandQueue, renderPassDescriptor: MTLRenderPassDescriptor, depthStencilState: MTLDepthStencilState?, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentMVMatrix: float4x4, viewMatrix: Matrix4?, completionBlock: MTLCommandBufferHandler?) {
    
    dispatch_semaphore_wait(bufferProvider.avaliableResourcesSemaphore, DISPATCH_TIME_FOREVER)
    
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    let commandBuffer = commandQ.commandBuffer()
    let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
    //
    renderEncoder.setRenderPipelineState(pipelineState)
    if let depthStencilState = depthStencilState {
      renderEncoder.setDepthStencilState(depthStencilState)
    }
    renderEncoder.setCullMode(MTLCullMode.Front)
    
    let sceneModelViewMatrix = modelMatrix()
    if let viewMatrix = viewMatrix {
      sceneModelViewMatrix.multiplyLeft(viewMatrix)
    }
    
    for child in children {
      let modelViewMatrix = child.modelMatrix()
      modelViewMatrix.multiplyLeft(sceneModelViewMatrix)
      let uniformsBuffer = bufferProvider.bufferWithMatrices(projectionMatrix, modelViewMatrix: modelViewMatrix)
      renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, atIndex: 1)
      child.render(renderEncoder)
    }
    
    renderEncoder.endEncoding()
    commandBuffer.addCompletedHandler({ (buffer) -> Void in
      dispatch_semaphore_signal(self.bufferProvider.avaliableResourcesSemaphore)
      if let completionBlock = completionBlock {
        completionBlock(buffer)
      }
    })
    
    
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
    
  }
  
}
