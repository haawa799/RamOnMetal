//
//  ViewController.swift
//  Model_IO_OSX
//
//  Created by Andriy K. on 6/12/15.
//  Copyright © 2015 Andriy K. All rights reserved.
//

import MetalKit
import ModelIO
import simd

final class ViewController: NSViewController, MTKViewDelegate {
    
    @IBOutlet var metalView: MTKView! {
        didSet {
            metalView.delegate = self
            metalView.preferredFramesPerSecond = 60
            metalView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        }
    }
    
    private var device: MTLDevice!
    private var commandQ: MTLCommandQueue!
    private var scene: MyScene!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private var viewMatrix = Matrix4()
    private let sizeOfFloat = MemoryLayout<Float>.size
    
    func setupMetal() {
        let newDevice = MTLCreateSystemDefaultDevice()
        assert(newDevice != nil, "MTLCreateSystemDefaultDevice failed to create MTLDevice instance")
        device = newDevice!
        
        metalView.device = device
        commandQ = device.makeCommandQueue()
    }
    
    func myVertexDescriptor() -> MTLVertexDescriptor {
        // This vertex descriptor should map to to Model I/O vertex descriptor, this order is how vertices are alligned in memory
        let metalVertexDescriptor = MTLVertexDescriptor()
        
        if let attribute = metalVertexDescriptor.attributes[0] {
            attribute.format = MTLVertexFormat.float3
            attribute.offset = 0
            attribute.bufferIndex = 0
        }
        if let attribute = metalVertexDescriptor.attributes[1] {
            attribute.format = MTLVertexFormat.float
            attribute.offset = sizeOfFloat * 3
            attribute.bufferIndex = 0
        }
        if let attribute = metalVertexDescriptor.attributes[2] {
            attribute.format = MTLVertexFormat.float3
            attribute.offset = sizeOfFloat * (3 + 1)
            attribute.bufferIndex = 0
        }
        if let attribute = metalVertexDescriptor.attributes[3] {
            attribute.format = MTLVertexFormat.float2
            attribute.offset = sizeOfFloat * (3 + 1 + 3)
            attribute.bufferIndex = 0
        }
        
        if let layoutDescriptor = metalVertexDescriptor.layouts[0] {
            layoutDescriptor.stride = sizeOfFloat * (3 + 1 + 3 + 2)
            layoutDescriptor.stepRate = 1
            layoutDescriptor.stepFunction = .perVertex// this zero correspons to  buffer index
        }
        
        return metalVertexDescriptor
    }
    
    // Compile vertex descriptor, vertex and fragment shaders into pipelineState, when using multiple shaders, you precompile them like the one below, and use coresponding one in draw call
    func compiledPipelineStateFrom(vertexShader: MTLFunction,
                                   fragmentShader: MTLFunction,
                                   vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState {
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
        pipelineStateDescriptor.vertexFunction = vertexShader
        pipelineStateDescriptor.fragmentFunction = fragmentShader
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = metalView.depthStencilPixelFormat
        
        let compiledState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        return compiledState
    }
    
    func compiledDepthState() -> MTLDepthStencilState {
        let depthStencilDesc = MTLDepthStencilDescriptor()
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.less
        depthStencilDesc.isDepthWriteEnabled = true
        
        return device.makeDepthStencilState(descriptor: depthStencilDesc)!
    }
    
    func setupScene() {
        scene = MyScene(device: device)
        viewMatrix!.translate(0.0, y: 0.0, z: -2)
        scene.ram.rotationX = -Matrix4.degrees(toRad: 90)
        scene.ram.rotationZ = -Matrix4.degrees(toRad: 45)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: "vertexShader")!
        let fragmentProgram = defaultLibrary.makeFunction(name: "fragmentShader")!
        
        let metalVertexDescriptor = myVertexDescriptor()
        
        pipelineState = compiledPipelineStateFrom(vertexShader: vertexProgram, fragmentShader: fragmentProgram, vertexDescriptor: metalVertexDescriptor)
        depthStencilState = compiledDepthState()
        setupScene()
    }
    
    
    
    // MARK: - MTKViewDelegate
    
    private var inflightDrawablesSemaphore = DispatchSemaphore(value: 3)
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Change projection matrix, based on window size
        let matrix = Matrix4.makePerspectiveViewAngle(Matrix4.degrees(toRad: 85.0),
                                                      aspectRatio: Float(size.width / size.height),
                                                      nearZ: 0.01,
                                                      farZ: 100)
        scene.projectionMatrix = matrix
    }
    
    func draw(in view: MTKView) {
        if let renderPassDescriptor = view.currentRenderPassDescriptor {
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
            renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
            
            inflightDrawablesSemaphore.wait()
            if let drawable = view.currentDrawable {
                // Actual rendering
                scene.render(commandQ: commandQ,
                             renderPassDescriptor: renderPassDescriptor,
                             depthStencilState: depthStencilState,
                             pipelineState: pipelineState,
                             drawable: drawable,
                             parentMVMatrix: float4x4(0.0),
                             viewMatrix: viewMatrix){ (buffer) -> Void in
                    self.inflightDrawablesSemaphore.signal()
                }
            }
        }
    }
    
    
    
    // MARK: - OS X
    
    override func rotate(with event: NSEvent) {
        scene.rotationY -= event.rotation
    }
    
}

extension ViewController {
    
    @IBAction func occlusionSwitchValueChanged(sender: NSButton) {
        scene.useOcclusion = sender.state.rawValue != 0
    }
    
    @IBAction func texturesSwitchValueChanged(sender: NSButton) {
        scene.useTexture = sender.state.rawValue != 0
    }
    
}
