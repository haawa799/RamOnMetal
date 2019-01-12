//
//  Node.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import MetalKit
import GLKit.GLKMath

protocol Transformable {
    var positionX: Float { get set }
    var positionY: Float { get set }
    var positionZ: Float { get set }
    
    var rotationX: Float { get set }
    var rotationY: Float { get set }
    var rotationZ: Float { get set }
    var scale: Float { get set }
    
    func modelMatrix() -> GLKMatrix4
}

extension Transformable {
    func modelMatrix() -> GLKMatrix4 {
        var matrix = GLKMatrix4Identity
        matrix = GLKMatrix4Translate(matrix, positionX, positionY, positionZ)
        matrix = GLKMatrix4Rotate(matrix, rotationX, 1, 0, 0)
        matrix = GLKMatrix4Rotate(matrix, rotationY, 0, 1, 0)
        matrix = GLKMatrix4Rotate(matrix, rotationZ, 0, 0, 1)
        matrix = GLKMatrix4Scale(matrix, scale, scale, scale)
        return matrix
    }
}

class Node: NSObject, Transformable {
    
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float     = 1.0
    
    var vertexBuffer: MTLBuffer?
    var vertexCount = 0
    
    var metalKitMeshes = [MTKMesh]()
    
    init(device: MTLDevice) {
        
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder) {
        
    }
    
}
