//
//  ContentView.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 17.12.24.
//

import RealityKit
import SwiftUI

struct ContentView: View {
  
  @State var anchor = AnchorEntity()

  var body: some View {
    content
  }
  
  private var content: some View {
    RealityView { content in
      // Create a cube model
      let size: Float = 0.1
      let model = Entity()
      let mesh = MeshResource.generateBox(size: size, cornerRadius: 0.005)
      let material = SimpleMaterial(color: .red, roughness: 0.15, isMetallic: true)
      model.components.set(ModelComponent(mesh: mesh, materials: [material]))
      model.position = [0, size / 2, 0]
    
      // Create horizontal plane anchor for the content
      anchor = AnchorEntity(
        .plane(
          .horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)
        )
      )
      anchor.addChild(model)

      // Add the horizontal plane anchor to the scene
      content.add(anchor)
//      content.camera = .spatialTracking
    }
    .edgesIgnoringSafeArea(.all)
  }

}

#Preview {
  ContentView()
}
