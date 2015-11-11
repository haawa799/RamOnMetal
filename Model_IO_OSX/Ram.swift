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
    let path = NSBundle.mainBundle().pathForResource("ram", ofType: "png")!
    let data = NSData(contentsOfFile: path)!
    samplerState = Ram.defaultSampler(device)
    super.init(device: device)
    
    texture = try! textureLoader.newTextureWithData(data, options: nil)
    load(device)
  }
  
  var texture: MTLTexture?
  var textureLoader: MTKTextureLoader
  var samplerState: MTLSamplerState
  
  func load(device: MTLDevice) {
    
    let modelIOVertexDesc = MDLVertexDescriptor()
    if let attribute = modelIOVertexDesc.attributes[0] as? MDLVertexAttribute {
      attribute.name = MDLVertexAttributePosition
      attribute.offset = 0
      attribute.format = MDLVertexFormat.Float3
      //        attribute.bufferIndex = 0
    }
    if let attribute = modelIOVertexDesc.attributes[1] as? MDLVertexAttribute {
      attribute.name = MDLVertexAttributeOcclusionValue
      attribute.offset = sizeof(Float) * 3
      attribute.format = MDLVertexFormat.Float
      //        attribute.bufferIndex = 0
    }
    if let attribute = modelIOVertexDesc.attributes[2] as? MDLVertexAttribute {
      attribute.name = MDLVertexAttributeNormal
      attribute.offset = sizeof(Float) * (3 + 1)
      attribute.format = MDLVertexFormat.Float3
      //        attribute.bufferIndex = 0
    }
    if let attribute = modelIOVertexDesc.attributes[3] as? MDLVertexAttribute {
      attribute.name = MDLVertexAttributeTextureCoordinate
      attribute.offset = sizeof(Float) * (3 + 1 + 3)
      attribute.format = MDLVertexFormat.Float2
      //        attribute.bufferIndex = 0
    }
    
    if let layout = modelIOVertexDesc.layouts[0] as? MDLVertexBufferLayout {  // this zero correspons to  buffer index
      layout.stride = sizeof(Float) * (3 + 1 + 3 + 2)
    }
    
    let url = NSBundle.mainBundle().URLForResource("ram", withExtension: "obj")!
    
    let allocator = MTKMeshBufferAllocator(device: device)
    let asset = MDLAsset(URL: url, vertexDescriptor: modelIOVertexDesc, bufferAllocator: allocator)
    
    if let mesh = asset.objectAtIndex(0) as? MDLMesh {
      
      var subs = [MDLObject]()
      for obj in mesh.submeshes {
        if let sub = obj as? MDLObject {
          subs.append(sub)
        }
      }
      mesh.generateAmbientOcclusionVertexColorsWithQuality(1.0, attenuationFactor: 0.1, objectsToConsider: [mesh], vertexAttributeNamed: MDLVertexAttributeOcclusionValue)
    }
    
    do {
      metalKitMeshes = try MTKMesh.newMeshesFromAsset(asset, device: device, sourceMeshes: nil)
      
//      MTKMesh.new
    } catch _ {
      print("problm")
    }
    
//    metalKitMeshes = try! MTKMesh.newMeshesFromAsset(asset, device: device, sourceMeshes: nil)//meshesFromAsset(asset, device: device)
    
  }
  
  class func defaultSampler(device: MTLDevice) -> MTLSamplerState
  {
    let pSamplerDescriptor:MTLSamplerDescriptor? = MTLSamplerDescriptor();
    
    if let sampler = pSamplerDescriptor
    {
      sampler.minFilter             = MTLSamplerMinMagFilter.Nearest
      sampler.magFilter             = MTLSamplerMinMagFilter.Nearest
      sampler.mipFilter             = MTLSamplerMipFilter.Nearest
      sampler.maxAnisotropy         = 1
      sampler.sAddressMode          = MTLSamplerAddressMode.ClampToEdge
      sampler.tAddressMode          = MTLSamplerAddressMode.ClampToEdge
      sampler.rAddressMode          = MTLSamplerAddressMode.ClampToEdge
      sampler.normalizedCoordinates = true
      sampler.lodMinClamp           = 0
      sampler.lodMaxClamp           = FLT_MAX
    }
    else
    {
      print(">> ERROR: Failed creating a sampler descriptor!")
    }
    return device.newSamplerStateWithDescriptor(pSamplerDescriptor!)
  }
  
  override func render(renderEncoder: MTLRenderCommandEncoder) {
    
    guard metalKitMeshes.count != 0 else {return}
    
    for obj in metalKitMeshes {
      if let mesh = obj as? MTKMesh {
        if let vertexBuf = mesh.vertexBuffers.first {
          renderEncoder.setVertexBuffer(vertexBuf.buffer, offset: vertexBuf.offset, atIndex: 0)
          if let texture = texture {
            renderEncoder.setFragmentTexture(texture, atIndex: 0)
          }
          renderEncoder.setFragmentSamplerState(samplerState, atIndex: 0)
          for submesh in mesh.submeshes {
            renderEncoder.drawIndexedPrimitives(submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
          }
        }
      }
    }
  }
  
}
