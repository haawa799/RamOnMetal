//
//  ViewController.swift
//  Model_IO_OSX
//
//  Created by Andriy K. on 6/12/15.
//  Copyright © 2015 Andriy K. All rights reserved.
//

import Cocoa
import MetalKit
import ModelIO
import simd

class ViewController: NSViewController, MTKViewDelegate {

  @IBOutlet var metalView: MTKView! {
    didSet {
      metalView.delegate = self
      metalView.preferredFramesPerSecond = 60
    }
  }
  
  var device: MTLDevice!
  var commandQ: MTLCommandQueue!
  var scene: MyScene!
  var pipelineState: MTLRenderPipelineState!
  
  var viewMatrix = Matrix4()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
    device = MTLCreateSystemDefaultDevice()!
    metalView.device = device
    commandQ = device.newCommandQueue()
    
    scene = MyScene(device: device)
    
    let defaultLibrary = device.newDefaultLibrary()
    let fragmentProgram = defaultLibrary!.newFunctionWithName("fragmentShader")!
    let vertexProgram = defaultLibrary!.newFunctionWithName("vertexShader")!
    
    let metalVertexDescriptor = MTLVertexDescriptor()
    if let attribute = metalVertexDescriptor.attributes[0] {
      attribute.format = MTLVertexFormat.Float3
      attribute.offset = 0
      //        attribute.bufferIndex = 0
    }
    if let attribute = metalVertexDescriptor.attributes[1] {
      attribute.format = MTLVertexFormat.Float3
      attribute.offset = sizeof(Float) * 3
      //        attribute.bufferIndex = 0
    }
    
    if let layout = metalVertexDescriptor.layouts[0] {  // this zero correspons to  buffer index
      layout.stride = sizeof(Float) * (3 + 3)
    }
    
    
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexDescriptor = metalVertexDescriptor
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
    
    pipelineState = try! device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
    
    viewMatrix.translate(0.0, y: 0.0, z: -2)
    scene.ram.rotationX = -Matrix4.degreesToRad(90)
    scene.ram.rotationZ = -Matrix4.degreesToRad(45)
  }
  
  
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
  
  
  // MARK: - MTKViewDelegate
  
  var inflightDrawablesSemaphore = dispatch_semaphore_create(3)
  
  func view(view: MTKView, willLayoutWithSize size: CGSize) {
    let matrix = Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0), aspectRatio: Float(size.width / size.height), nearZ: 0.01, farZ: 100)
    scene.projectionMatrix = matrix
  }
  
  
  func drawInView(view: MTKView) {
    
    if let renderPassDescriptor = view.currentRenderPassDescriptor {
      renderPassDescriptor.colorAttachments[0].loadAction = .Clear
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
      renderPassDescriptor.colorAttachments[0].storeAction = .Store
      dispatch_semaphore_wait(inflightDrawablesSemaphore, DISPATCH_TIME_FOREVER)
      
      if let drawable = view.currentDrawable {
        scene.render(commandQ, renderPassDescriptor: renderPassDescriptor, pipelineState: pipelineState, drawable: drawable, parentMVMatrix: float4x4(0.0), viewMatrix: viewMatrix){ (buffer) -> Void in
          dispatch_semaphore_signal(self.inflightDrawablesSemaphore)
        }
      }
    }
  }
  
}
