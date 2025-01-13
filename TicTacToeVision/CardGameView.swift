//
//  FlipCardGameView.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 18.12.24.
//

import SwiftUI
import RealityKit

struct CardGameView: View {

  @State var anchor = AnchorEntity()
  @State var point: CGPoint? = nil

  var body: some View {
    content
  }
  
  private var content: some View {
    RealityView { content in
      // Create a cube model

      let width: Float = 0.5
      let height: Float = 0.5
      let model = Entity()

      let mesh = MeshResource.generatePlane(width: width, height: height)
      let material = UnlitMaterial(color: .red)
      
      model.components.set(ModelComponent(mesh: mesh, materials: [material]))
      model.components.set(InputTargetComponent(allowedInputTypes: .all))
      model.position = [0, 0.5, -1]
      model.name = "card"
      model.generateCollisionShapes(recursive: true)  // Necessary for tap detection
      content.add(model)
    } update: { content in
      guard let point else {
        print("no point")
        return
      }
      print(point)
//      let entities = content.entities
//      let entities = content.entities(at: point, in: .local)
//      entities.forEach { entity in
//        guard let entity = entity as? ModelEntity else {
//          print("No ModelEntity")
//          return
//        }
//        print(entity.name)
//        let meshEnt = MeshResource.generatePlane(width: 0.2, height: 0.2)
//        let materialEnt = UnlitMaterial(color: .green)
//        entity.components.set(ModelComponent(mesh: meshEnt, materials: [materialEnt]))
//      }
    }
    .onTapGesture { point in
      self.point = point
    }
    .edgesIgnoringSafeArea(.all)
  }

}

#Preview {
  CardGameView()
}
