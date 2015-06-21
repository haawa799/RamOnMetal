//
//  MyScene.swift
//  Model_IO
//
//  Created by Andriy K. on 6/10/15.
//  Copyright © 2015 Andrew  K. All rights reserved.
//

import MetalKit

class MyScene: Scene {
  
  override init(device: MTLDevice) {
    super.init(device: device)
    children = [Ram(device: device)]
  }
  
}
