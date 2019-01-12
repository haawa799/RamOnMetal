//
//  Scene.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import Foundation
import MetalKit
import GLKit.GLKMath

class Scene: NSObject, Transformable {
    
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float     = 1.0
    
    var children: [Node]
    var projectionMatrix = GLKMatrix4Identity
    var bufferProvider: BufferProvider
    
    var useTexture = false
    var useOcclusion = false
    
    private var triangleVertexBuffer: MTLBuffer!
    
    init(device: MTLDevice) {
        bufferProvider = BufferProvider(inFlightBuffers: 3, device: device)
        children = [Node]()
    }
    
    func render(commandQ: MTLCommandQueue,
                renderPassDescriptor: MTLRenderPassDescriptor,
                depthStencilState: MTLDepthStencilState?,
                pipelineState: MTLRenderPipelineState,
                drawable: CAMetalDrawable,
                viewMatrix: GLKMatrix4?,
                completionBlock: MTLCommandBufferHandler?) {
        
        bufferProvider.avaliableResourcesSemaphore.wait()
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        let commandBuffer = commandQ.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        renderEncoder.setRenderPipelineState(pipelineState)
        if let depthStencilState = depthStencilState {
            renderEncoder.setDepthStencilState(depthStencilState)
        }
        renderEncoder.setCullMode(MTLCullMode.front)
        
        var sceneModelViewMatrix = modelMatrix()
        if let viewMatrix = viewMatrix {
            sceneModelViewMatrix = GLKMatrix4Multiply(viewMatrix, sceneModelViewMatrix)
        }
        
        for child in children {
            var modelViewMatrix = child.modelMatrix()
            modelViewMatrix = GLKMatrix4Multiply(sceneModelViewMatrix, modelViewMatrix)
            let uniformsBuffer = bufferProvider.bufferWithMatrices(projectionMatrix: projectionMatrix,
                                                                   modelViewMatrix: modelViewMatrix,
                                                                   b0: useOcclusion,
                                                                   b1: useTexture)
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
            child.render(renderEncoder: renderEncoder)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.addCompletedHandler({ (buffer) -> Void in
            self.bufferProvider.avaliableResourcesSemaphore.signal()
            if let completionBlock = completionBlock {
                completionBlock(buffer)
            }
        })
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}
