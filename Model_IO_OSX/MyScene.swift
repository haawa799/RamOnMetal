//
//  MyScene.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import MetalKit

class MyScene: Scene {
  
  var ram: Node
  
  override init(device: MTLDevice) {
    ram = Ram(device: device)
    super.init(device: device)
    children = [ram]
  }
  
}
