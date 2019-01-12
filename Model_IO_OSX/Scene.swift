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
                parentMVMatrix: float4x4,
                viewMatrix: Matrix4?,
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
        
        let sceneModelViewMatrix = modelMatrix()
        if let viewMatrix = viewMatrix {
            sceneModelViewMatrix.multiplyLeft(viewMatrix)
        }
        
        for child in children {
            let modelViewMatrix = child.modelMatrix()
            modelViewMatrix.multiplyLeft(sceneModelViewMatrix)
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
