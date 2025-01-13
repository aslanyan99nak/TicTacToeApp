//
//  FlipCardGameView.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 18.12.24.
//

import RealityKit
import SwiftUI

struct FlipCardGameView: View {

  @StateObject private var viewModel = FlipCardViewModel()

  var body: some View {
    content
  }

}

extension FlipCardGameView {

  private var content: some View {
    VStack(spacing: 0) {
      RealityView { content in
        viewModel.content = content
        drawMatrix()
        content.camera = .spatialTracking
      } update: { content in
        if !viewModel.isWin {
          contentUpdated(content: content)
        }
      }
      .onTapGesture { point in
        viewModel.point = point
      }
      gameInfoView
    }
    .edgesIgnoringSafeArea(.all)
    .blur(radius: viewModel.isWin ? 5 : 0)
    .overlay {
      winnerInfo
    }
  }
  
  private var gameInfoView: some View {
    VStack(spacing: 0) {
      matrixView
    }
    .gradientBackground()
    .frame(maxHeight: 150)
  }

  private var matrixView: some View {
    VStack(alignment: .leading, spacing: 10) {
      Spacer()
      Text("Choose Size for Flip Card Game")
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal)

      Picker("", selection: $viewModel.matrixType) {
        ForEach(MatrixType.allCases, id: \.self) { matrixSize in
          Text("\(matrixSize.rawValue)x\(matrixSize.rawValue)")
            .tag(matrixSize)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()
      .disabled(viewModel.isStarted)
      .onChange(of: viewModel.matrixType) { oldValue, newValue in
        if oldValue != newValue {
          redraw()
        }
      }
      
      Spacer()
    }
  }

}

extension FlipCardGameView {
  
  @ViewBuilder
  private var winnerInfo: some View {
    if viewModel.isWin {
      VStack(spacing: 0) {
        Spacer()
        
        Text("You Win 🎉")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding()
        
        Spacer()
        
        Button {
          redraw()
        } label: {
          Text("Restart")
            .font(.title)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.yellow)
            .clipShape(Capsule())
        }
        
        Spacer()
      }
      .padding()
      .gradientBackground()
      .background(.purple.opacity(0.5))
      .frame(height: 200)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal, 24)
    }
  }

}

extension FlipCardGameView {
  
  private func redraw() {
    viewModel.reset()
    drawMatrix()
  }
  
  private func animatedEntity() -> Entity {
    let particles = ParticleEmitterComponent.Presets.sparks
    let model = Entity()
    model.components.set(particles)
    return model
  }

  private func flipCardBack(content: RealityViewCameraContent) {
    guard viewModel.threadSafeCardModels.count(where: { $0.isRotated }) > 1 else { return }

    for index in 0..<viewModel.threadSafeCardModels.count {
      if viewModel.threadSafeCardModels[index].isRotated {
        viewModel.threadSafeCardModels[index].isRotated = false
        let name = viewModel.threadSafeCardModels[index].card.name
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

  private func deleteSameCards(content: RealityViewCameraContent) {
    guard viewModel.threadSafeCardModels.count(where: { $0.isRotated }) > 1 else { return }
    let cards = viewModel.threadSafeCardModels.filter { $0.isRotated }.map { $0.card }
    guard cards.count > 1 else { return }
    let firstName = String(cards[0].name)
    let secondName = String(cards[1].name)
    let firstCardSuffix = firstName.suffix(6)
    let secondCardSuffix = secondName.suffix(6)

    if firstCardSuffix == secondCardSuffix && firstCardSuffix.contains("photo") {
      content.entities.forEach { entity in
        deleteEntity(by: firstName, entity: entity)
        deleteEntity(by: secondName, entity: entity)
      }
    }
  }

  private func deleteEntity(by name: String, entity: Entity) {
    if let firstEntity = entity.findEntity(named: name) as? ModelEntity {
      firstEntity.addChild(animatedEntity())
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        if let index = viewModel.threadSafeCardModels.firstIndex(where: { $0.card.name == name }) {
          viewModel.threadSafeCardModels[index].isDeleted = true
          viewModel.checkForWinner()
        }
        firstEntity.removeFromParent()
      }
    }
  }
  
  private func drawMatrix() {
    let modelEntity = create3DCards(
      matrixType: viewModel.matrixType,
      width: viewModel.width,
      height: viewModel.height,
      spacing: viewModel.spacing
    )
    viewModel.content?.add(modelEntity)
  }
  
  private func create3DCards(
    matrixType: MatrixType = .x2,
    width: Float,
    height: Float,
    spacing: Float
  ) -> ModelEntity {
    let gridSize = matrixType.rawValue
    let spacingDistance = Float(gridSize - 1) * spacing
    let planeWidth: Float = (width - spacingDistance) / Float(gridSize)
    let planeHeight: Float = (height - spacingDistance) / Float(gridSize)
    let parentEntity = ModelEntity()
    parentEntity.position = [0, height / 2, -1]

    viewModel.imageNames = viewModel.getImageNames(for: matrixType).shuffled()

    for index in 0..<gridSize * gridSize {
      let model = createCard(
        matrixType: matrixType,
        planeWidth: planeWidth,
        planeHeight: planeHeight,
        spacing: spacing,
        index: index
      )
      let cardModel = CardModel(card: model)
      viewModel.threadSafeCardModels.append(cardModel)
      parentEntity.addChild(model)
    }
    return parentEntity
  }
  
  private func cardSelected(content: RealityViewCameraContent, entity: ModelEntity) {
    if let index = viewModel.threadSafeCardModels.firstIndex(where: {
      $0.card.name == entity.name
    }) {

      flipCardBack(content: content)
      viewModel.threadSafeCardModels[index].isRotated.toggle()
      
      let isRotated = viewModel.threadSafeCardModels[index].isRotated
      let rotationValue = simd_quatf(angle: isRotated ? .pi : -2 * .pi, axis: [0, 1, 0])
      
      entity.rotateAnimation(with: rotationValue, duration: 2) {
        if !viewModel.isStarted {
          viewModel.isStarted = true
        }
        deleteSameCards(content: content)
      }
    }
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

    let frontImageName = viewModel.randomImageName()
    card.name = "card\(index)\(frontImageName)"
    setupCardImages(card: card, mesh: mesh)
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
    //    card.transform.rotation = .init(angle: .pi, axis: .init(0, 1, 0))  //
    card.generateCollisionShapes(recursive: false)  // Necessary for tap detection

    return card
  }
  
  private func setupCardImages(card: ModelEntity, mesh: MeshResource) {
    guard let frontImageName = viewModel.separateCardAndPhoto(from: card.name)?.1 else { return }
    let frontImage = UIImage(named: frontImageName) ?? UIImage()

    let defaultImageName = "cardTexture"
    let defaultImage = UIImage(named: defaultImageName) ?? UIImage()

    let cardDefaultMaterial = createCardMaterial(from: defaultImage)
    let frontMaterial = createCardMaterial(from: frontImage)

    card.components.set(
      ModelComponent(
        mesh: mesh,
        materials: [
          cardDefaultMaterial, cardDefaultMaterial, frontMaterial, cardDefaultMaterial,
          cardDefaultMaterial, cardDefaultMaterial,
        ]
      )
    )
  }
  
  private func createCardMaterial(from image: UIImage) -> UnlitMaterial {
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

      cardSelected(content: content, entity: entity)
    }
  }
  
}

#Preview {
  FlipCardGameView()
}
