//
//  BufferProvider.swift
//  Model_IO_OSX
//
//  Created by Andriy K. on 6/20/15.
//  Copyright © 2015 Andriy K. All rights reserved.
//

import Cocoa
import GLKit.GLKMath

/// This class is responsible for providing a uniformBuffer which will be passed to vertex shader. It holds n buffers. In case n == 3 for frame0 it will give buffer0 for frame1 - buffer1 for frame2 - buffer2 for frame3 - buffer0 and so on. It's user responsibility to make sure that GPU is not using that buffer before use. For details refer to wwdc session 604 (18:00).

class BufferProvider: NSObject {
    
    static let floatSize = MemoryLayout<Float>.size
    static let floatsPerMatrix = 16
    static let numberOfMatrices = 2
    
    static let boolSize = MemoryLayout<Bool>.size
    
    static var bufferSize: Int {
        return (matrixSize * numberOfMatrices) + (16)
    }
    
    static var matrixSize: Int {
        return floatSize * floatsPerMatrix
    }
    
    private(set) var indexOfAvaliableBuffer = 0
    private(set) var numberOfInflightBuffers: Int
    private var buffers: [MTLBuffer]
    
    private(set) var avaliableResourcesSemaphore: DispatchSemaphore
    
    init(inFlightBuffers: Int, device: MTLDevice) {
        
        avaliableResourcesSemaphore = DispatchSemaphore(value: inFlightBuffers)
        
        numberOfInflightBuffers = inFlightBuffers
        buffers = [MTLBuffer]()
        for _ in 0...inFlightBuffers {
            let buffer = device.makeBuffer(length: BufferProvider.bufferSize, options: [])!
            buffer.label = "Uniform buffer"
            buffers.append(buffer)
        }
    }
    
    deinit{
        for _ in 0...numberOfInflightBuffers{
            avaliableResourcesSemaphore.signal()
        }
    }
    
    func bufferWithMatrices(projectionMatrix: GLKMatrix4,
                            modelViewMatrix: GLKMatrix4,
                            b0: Bool,
                            b1: Bool) -> MTLBuffer {
        
        let uniformBuffer = self.buffers[indexOfAvaliableBuffer]
        indexOfAvaliableBuffer += 1
        if indexOfAvaliableBuffer == numberOfInflightBuffers {
            indexOfAvaliableBuffer = 0
        }
        
        let size = BufferProvider.matrixSize
        memcpy(uniformBuffer.contents(), projectionMatrix.raw, size)
        memcpy(uniformBuffer.contents() + size, modelViewMatrix.raw, size)
        
        let params = [b0, b1]
        memcpy(uniformBuffer.contents() + 2*size, params, BufferProvider.boolSize * params.count)
        
        return uniformBuffer
    }
    
}

extension GLKMatrix4 {
    
    var raw: [Float] {
//        var tmp = self.m
//
//        let q = tmp.0
//
//        let pointer = UnsafeBufferPointer(start: &tmp.0,
//                                          count: MemoryLayout.size(ofValue: tmp)/MemoryLayout<Float>.size)
//
//
//        let array = [Float](pointer)
        return [m.0, m.1, m.2, m.3, m.4, m.5, m.6, m.7, m.8, m.9, m.10, m.11, m.12, m.13, m.14, m.15]
    }
    
}
