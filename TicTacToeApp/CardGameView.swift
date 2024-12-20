//
//  CardGameView.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 18.12.24.
//

import RealityKit
import SwiftUI

struct CardGameView: View {

  enum MatrixType: Int {

    case four = 4
    case sixTeen = 16
    case thirtySix = 25

  }

  @State private var viewModel = CarGameViewModel()

  var body: some View {
    content
  }

}

extension CardGameView {

  private var content: some View {
    RealityView { content in
      modelEntity = create3DCards(
        matrixType: viewModel.matrixType,
        width: viewModel.width,
        height: viewModel.height,
        spacing: viewModel.spacing
      )
      content.add(modelEntity)
      content.camera = .spatialTracking
    } update: { content in
      contentUpdated(content: content)
    }
    .onTapGesture { point in
      viewModel.point = point
    }
    .edgesIgnoringSafeArea(.all)
  }

  private func create3DCards(
    matrixType: MatrixType = .sixTeen,
    width: Float,
    height: Float,
    spacing: Float
  ) -> ModelEntity {
    let gridSize = Int(sqrt(Double(matrixType.rawValue)))
    let spacingDistance = Float(gridSize - 1) * spacing
    let planeWidth: Float = (width - spacingDistance) / Float(gridSize)
    let planeHeight: Float = (height - spacingDistance) / Float(gridSize)
    let parentEntity = ModelEntity()
    parentEntity.position = [0, height / 2, -1]

    for index in 0..<matrixType.rawValue {
      let model = createCard(
        matrixType: matrixType,
        planeWidth: planeWidth,
        planeHeight: planeHeight,
        spacing: spacing,
        index: index
      )
      let cardModel = CardModel(card: model, isRotated: false)
      viewModel.cardModels.append(cardModel)
      parentEntity.addChild(model)
    }
    return parentEntity
  }

  private func createCard(
    matrixType: MatrixType,
    planeWidth: Float,
    planeHeight: Float,
    spacing: Float,
    index: Int
  ) -> ModelEntity {
    let card = ModelEntity()
    let mesh = MeshResource.generateBox(
      width: planeWidth,
      height: planeHeight,
      depth: 0.01,
      cornerRadius: 0.05,
      splitFaces: true
    )

    let frontImageName = randomImageName()
    let defaultImageName = "cardTexture"

    let frontImage = UIImage(named: frontImageName) ?? UIImage()
    let defaultImage = UIImage(named: defaultImageName) ?? UIImage()

    let cardDefaultMaterial = createCartMaterial(from: defaultImage)
    let frontMaterial = createCartMaterial(from: frontImage)

    card.components.set(
      ModelComponent(
        mesh: mesh,
        materials: [
          cardDefaultMaterial, cardDefaultMaterial, frontMaterial, cardDefaultMaterial,
          cardDefaultMaterial, cardDefaultMaterial,
        ]
      )
    )
    let position = viewModel.getCardPosition(
      index: index,
      matrixType: matrixType,
      spacing: spacing,
      width: planeWidth,
      height: planeHeight
    )
    let relativePosition = SIMD3<Float>(
      position.x - planeWidth - spacing,
      position.y - planeHeight - spacing,
      position.z
    )
    card.position = relativePosition
    card.name = "card\(index)\(frontImageName)"
    card.generateCollisionShapes(recursive: false)  // Necessary for tap detection
    return card
  }

  private func contentUpdated(content: RealityViewCameraContent) {
    guard let point = viewModel.point else {
      print("no point")
      return
    }
    let entities = content.entities(at: point, in: .local)
    entities.forEach { entity in
      guard let entity = entity as? ModelEntity else {
        print("No ModelEntity")
        return
      }
      //      entity.model?.materials[0] = UnlitMaterial(color: .blue)
      if let index = viewModel.cardModels.firstIndex(where: { $0.card.name == entity.name }) {
        deleteSameCards(content: content)
        flipCardBack(content: content)
        viewModel.cardModels[index].isRotated.toggle()
        let isRotated = viewModel.cardModels[index].isRotated
        let rotationValue = simd_quatf(angle: isRotated ? .pi : -2 * .pi, axis: [0, 1, 0])
        entity.rotateAnimation(with: rotationValue, duration: 2)
      }
    }
  }

  private func randomImageName() -> String {
    var names: [String] = []
    for index in 1..<9 {
      names.append("photo\(index)")
    }
    return names.randomElement() ?? "photo1"
  }

  private func flipCardBack(content: RealityViewCameraContent) {
    guard viewModel.cardModels.count(where: { $0.isRotated }) > 1 else { return }
    for index in 0..<viewModel.cardModels.count {
      if viewModel.cardModels[index].isRotated {
        viewModel.cardModels[index].isRotated = false
        let name = viewModel.cardModels[index].card.name
        rotateEntityBy(name: name, content: content)
      }
    }
  }

  private func rotateEntityBy(name: String, content: RealityViewCameraContent) {
    content.entities.forEach { entity in
      guard let cardEntity = entity.findEntity(named: name) as? ModelEntity else { return }
      let rotationValue = simd_quatf(angle: -2 * .pi, axis: [0, 1, 0])
      cardEntity.rotateAnimation(with: rotationValue, duration: 2)
    }
  }

  private func createCartMaterial(from image: UIImage) -> UnlitMaterial {
    guard let cgImage = image.cgImage,
      let textureResource = try? TextureResource(
        image: cgImage,
        options: .init(semantic: .normal)
      )
    else {
      return UnlitMaterial()
    }
    var material = UnlitMaterial()
    material.color = .init(
      tint: .white.withAlphaComponent(0.999),
      texture: .init(textureResource)
    )
    return material
  }
  
  private func deleteSameCards(content: RealityViewCameraContent) {
    guard viewModel.cardModels.count(where: { $0.isRotated }) > 1 else { return }
    let cards = viewModel.cardModels.filter { $0.isRotated }.map { $0.card }
    guard cards.count > 1 else { return }
    let firstName = String(cards[0].name)
    let secondName = String(cards[1].name)
    let firstCardSuffix = firstName.suffix(6)
    let secondCardSuffix = secondName.suffix(6)
        
    if firstCardSuffix == secondCardSuffix && firstCardSuffix.contains("photo") {
      content.entities.forEach { entity in
        if let cardEntity = entity.findEntity(named: firstName) as? ModelEntity {
          cardEntity.removeFromParent()
        }
        if let cardEntity = entity.findEntity(named: secondName) as? ModelEntity {
          cardEntity.removeFromParent()
        }
      }
    }
  }

}

#Preview {
  CardGameView()
}
