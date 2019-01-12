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
        textureLoader = MTKTextureLoader(device: device)
        let url = Bundle.main.url(forResource: "ram", withExtension: "png")!
        let data = try! Data(contentsOf: url)
        samplerState = Ram.defaultSampler(device: device)
        super.init(device: device)
        
        texture = try! textureLoader.newTexture(data: data, options: nil)
        load(device)
    }
    
    var texture: MTLTexture?
    var textureLoader: MTKTextureLoader
    var samplerState: MTLSamplerState
    
    func load(_ device: MTLDevice) {
        
        let modelIOVertexDesc = MDLVertexDescriptor()
        let sizeOfFloat = MemoryLayout<Float>.size
        
        if let attribute = modelIOVertexDesc.attributes[0] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributePosition
            attribute.offset = 0
            attribute.format = MDLVertexFormat.float3
        }
        if let attribute = modelIOVertexDesc.attributes[1] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributeOcclusionValue
            attribute.offset = sizeOfFloat * 3
            attribute.format = MDLVertexFormat.float
        }
        if let attribute = modelIOVertexDesc.attributes[2] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributeNormal
            attribute.offset = sizeOfFloat * (3 + 1)
            attribute.format = MDLVertexFormat.float3
        }
        if let attribute = modelIOVertexDesc.attributes[3] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributeTextureCoordinate
            attribute.offset = sizeOfFloat * (3 + 1 + 3)
            attribute.format = MDLVertexFormat.float2
        }
        
        if let layout = modelIOVertexDesc.layouts[0] as? MDLVertexBufferLayout {
            layout.stride = sizeOfFloat * (3 + 1 + 3 + 2)
        }
        
        let url = Bundle.main.url(forResource: "ram", withExtension: "obj")!
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: url, vertexDescriptor: modelIOVertexDesc, bufferAllocator: allocator)
        
        if let mesh = asset.object(at: 0) as? MDLMesh {
            
            var subs = [MDLObject]()
            for obj in mesh.submeshes! {
                if let sub = obj as? MDLObject {
                    subs.append(sub)
                }
            }
            mesh.generateAmbientOcclusionVertexColors(withQuality: 1.0,
                                                      attenuationFactor: 0.1,
                                                      objectsToConsider: [mesh],
                                                      vertexAttributeNamed: MDLVertexAttributeOcclusionValue)
        }
        
        metalKitMeshes = try! MTKMesh.newMeshes(asset: asset, device: device).metalKitMeshes
    }
    
    class func defaultSampler(device: MTLDevice) -> MTLSamplerState {
        
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.nearest
        sampler.magFilter             = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter             = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
        
        return device.makeSamplerState(descriptor: sampler)!
    }
    
    override func render(renderEncoder: MTLRenderCommandEncoder) {
        
        guard !metalKitMeshes.isEmpty else {
            return
        }
        
        // Draw each mesh
        for mesh in metalKitMeshes {
            
            if let vertexBuf = mesh.vertexBuffers.first {
                
                // Set vertices
                renderEncoder.setVertexBuffer(vertexBuf.buffer, offset: vertexBuf.offset, index: 0)
                
                // Set texture
                if let texture = texture {
                    renderEncoder.setFragmentTexture(texture, index: 0)
                }
                
                renderEncoder.setFragmentSamplerState(samplerState, index: 0)
                
                // Draw submeshes
                mesh.submeshes.forEach { (submesh) in
                    renderEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                        indexCount: submesh.indexCount,
                                                        indexType: submesh.indexType,
                                                        indexBuffer: submesh.indexBuffer.buffer,
                                                        indexBufferOffset: submesh.indexBuffer.offset)
                }
            }
        }
    }
    
}
