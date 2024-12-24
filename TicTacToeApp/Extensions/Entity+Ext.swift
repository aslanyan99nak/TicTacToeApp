//
//  Entity+Ext.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 20.12.24.
//

import RealityKit
import SwiftUI

extension Entity {

  func rotateAnimation(with value: simd_quatf, duration: CGFloat) {
    var currentTransform = transform
    currentTransform.rotation = value
    move(to: currentTransform, relativeTo: self.parent, duration: duration)
    
    print("SelfTransform: \(currentTransform.rotation) \n CurrentTransform: \(currentTransform.rotation)")
  }
  
  func rotateAnimation(from: Transform, to: simd_quatf, duration: CGFloat) {
    var currentTransform = from
    currentTransform.rotation = to
    move(to: currentTransform, relativeTo: self.parent, duration: duration)
    transform = currentTransform
  }

}
