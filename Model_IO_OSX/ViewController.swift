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

class ViewController: NSViewController, MTKViewDelegate {

  @IBOutlet var metalView: MTKView! {
    didSet {
      metalView.delegate = self
      metalView.preferredFramesPerSecond = 60
      metalView.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
    }
  }
  
  var device: MTLDevice!
  var commandQ: MTLCommandQueue!
  var scene: MyScene!
  var pipelineState: MTLRenderPipelineState!
  var depthStencilState: MTLDepthStencilState!
  
  var viewMatrix = Matrix4()
  
  func setupMetal() {
    let newDevice = MTLCreateSystemDefaultDevice()
    assert(newDevice != nil, "MTLCreateSystemDefaultDevice failed to create MTLDevice instance")
    device = newDevice!
    
    metalView.device = device
    commandQ = device.newCommandQueue()
  }
  
  func myVertexDescriptor() -> MTLVertexDescriptor {
    // This vertex descriptor should map to to Model I/O vertex descriptor, this order is how vertices are alligned in memory
    let metalVertexDescriptor = MTLVertexDescriptor()
    if let attribute = metalVertexDescriptor.attributes[0] {
      attribute.format = MTLVertexFormat.Float3
      attribute.offset = 0
      attribute.bufferIndex = 0
    }
    if let attribute = metalVertexDescriptor.attributes[1] {
      attribute.format = MTLVertexFormat.Float
      attribute.offset = sizeof(Float) * 3
      attribute.bufferIndex = 0
    }
    if let attribute = metalVertexDescriptor.attributes[2] {
      attribute.format = MTLVertexFormat.Float3
      attribute.offset = sizeof(Float) * (3 + 1)
      attribute.bufferIndex = 0
    }
    if let attribute = metalVertexDescriptor.attributes[3] {
      attribute.format = MTLVertexFormat.Float2
      attribute.offset = sizeof(Float) * (3 + 1 + 3)
      attribute.bufferIndex = 0
    }
    
    if let layout = metalVertexDescriptor.layouts[0] {  // this zero correspons to  buffer index
      layout.stride = sizeof(Float) * (3 + 1 + 3 + 2)
    }
    return metalVertexDescriptor
  }
  
  // Compile vertex descriptor, vertex and fragment shaders into pipelineState, when using multiple shaders, you precompile them like the one below, and use coresponding one in draw call
  func compiledPipelineStateFrom(vertexShader vertexShader: MTLFunction, fragmentShader: MTLFunction, vertexDescriptor: MTLVertexDescriptor) -> MTLRenderPipelineState {
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexDescriptor = vertexDescriptor
    pipelineStateDescriptor.vertexFunction = vertexShader
    pipelineStateDescriptor.fragmentFunction = fragmentShader
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
    pipelineStateDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
    pipelineStateDescriptor.stencilAttachmentPixelFormat = metalView.depthStencilPixelFormat
    
    let compiledState = try! device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
    return compiledState
  }
  
  func compiledDepthState() -> MTLDepthStencilState {
    let depthStencilDesc = MTLDepthStencilDescriptor()
    depthStencilDesc.depthCompareFunction = MTLCompareFunction.Less
    depthStencilDesc.depthWriteEnabled = true
    
    return device.newDepthStencilStateWithDescriptor(depthStencilDesc)
  }
  
  func setupScene() {
    scene = MyScene(device: device)
    viewMatrix.translate(0.0, y: 0.0, z: -2)
    scene.ram.rotationX = -Matrix4.degreesToRad(90)
    scene.ram.rotationZ = -Matrix4.degreesToRad(45)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupMetal()
    
    let defaultLibrary = device.newDefaultLibrary()
    let vertexProgram = defaultLibrary!.newFunctionWithName("vertexShader")!
    let fragmentProgram = defaultLibrary!.newFunctionWithName("fragmentShader")!
    
    let metalVertexDescriptor = myVertexDescriptor()
    
    pipelineState = compiledPipelineStateFrom(vertexShader: vertexProgram, fragmentShader: fragmentProgram, vertexDescriptor: metalVertexDescriptor)
    depthStencilState = compiledDepthState()
    setupScene()
  }
  
  
  
  // MARK: - MTKViewDelegate
  
  var inflightDrawablesSemaphore = dispatch_semaphore_create(3)
  
  func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
    // Change projection matrix, based on window size
    let matrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(size.width / size.height), nearZ: 0.01, farZ: 100)
    scene.projectionMatrix = matrix
  }
  
  
  func drawInMTKView(view: MTKView) {
    if let renderPassDescriptor = view.currentRenderPassDescriptor {
      renderPassDescriptor.colorAttachments[0].loadAction = .Clear
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
      renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.Store
      
      dispatch_semaphore_wait(inflightDrawablesSemaphore, DISPATCH_TIME_FOREVER)
      if let drawable = view.currentDrawable {
        // Actual rendering
        scene.render(commandQ, renderPassDescriptor: renderPassDescriptor, depthStencilState: depthStencilState, pipelineState: pipelineState, drawable: drawable, parentMVMatrix: float4x4(0.0), viewMatrix: viewMatrix){ (buffer) -> Void in
          dispatch_semaphore_signal(self.inflightDrawablesSemaphore)
        }
      }
    }
  }
  
  
  
  // MARK: - OS X 
  
  private var deltaX: Float = 0
  private var deltaY: Float = 0
  private var lastPanLocation = NSPoint(x: 0, y: 0)
  let panSensivity: Float = 5.0
  override func mouseDragged(theEvent: NSEvent) {
    super.mouseDragged(theEvent)
    
    
    
    let pointInWindow = theEvent.locationInWindow
    
    let xDelta = Float((lastPanLocation.x - pointInWindow.x)/self.view.bounds.width) * panSensivity
    let yDelta = Float((lastPanLocation.y - pointInWindow.y)/self.view.bounds.height) * panSensivity
    
    print("x: \(xDelta)")
    print("y: \(yDelta)")
    print("")
    
    scene.ram.rotationZ -= yDelta
    scene.ram.rotationY -= xDelta
    
    lastPanLocation = pointInWindow
  }
  
}

extension ViewController {
  
  @IBAction func occlusionSwitchValueChanged(sender: NSButton) {
    scene.useOcclusion = sender.state != 0
  }
  
  @IBAction func texturesSwitchValueChanged(sender: NSButton) {
    scene.useTexture = sender.state != 0
  }
  
}
