//
//  FlipCardGameView2.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 10.01.25.
//

import RealityKit
import SwiftUI

struct FlipCardGameView2: View {

  @StateObject var manager: MultipeerManager
  @StateObject var viewModel = FlipCardGameViewModel2()

  var body: some View {
    VStack {
      //      winnerInfo
      realityView
      peers
        .onChange(of: manager.receivedMessages) { _, newValue in
          viewModel.updateMatrixData(newValue: newValue)
        }
    }
  }

}

extension FlipCardGameView2 {

  //  @ViewBuilder
  //  private var winnerInfo: some View {
  //    if let iswin = viewModel.iswin {
  //      HStack {
  //        Spacer()
  //        Text(iswin.rawValue)
  //          .font(.title)
  //          .foregroundColor(iswin == .win ? .green : viewModel.iswin == .draw ? .blue : .red)
  //          .padding()
  //        Spacer()
  //        Button("Restart") {
  //          restart()
  //        }
  //        .padding(4)
  //        .background(Color.yellow)
  //        .padding(6)
  //      }
  //    }
  //  }

  private var peers: some View {
    AvailablePeersView(peerManager: manager)
      .gradientBackground()
      .frame(height: 200)
  }

  private var realityView: some View {
    RealityView { content in
      viewModel.content = content
      drawMatrix(with: viewModel.matrixType)
      content.camera = .spatialTracking
    } update: { content in
      //      if viewModel.iswin == nil {
      draw(content: content)
      //        DispatchQueue.main.async {
      //          viewModel.checkForWinner()
      //        }
      //      }
    }
    .onTapGesture(perform: { point in
      //      if viewModel.isMyTurn && manager.connectedPeers.count > 0 {
      viewModel.point = point
      //      }
    })
    .edgesIgnoringSafeArea(.all)
  }

  func drawMatrix(with matrixType: MatrixType) {
    let modelEntity = create3DCards(
      matrixType: matrixType,
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
      let cardModel = CardModel(card: model, isRotated: false)
      viewModel.threadSafeCardModels.append(cardModel)
      parentEntity.addChild(model)
    }
    return parentEntity
  }

  private func draw(content: RealityViewCameraContent) {
    if viewModel.updatedMatrixData != nil {
      drawUpdates(content: content)
      return
    } else {  // if viewModel.isMyTurn {
      drawGestures(content: content)
      return
    }
  }

  private func drawUpdates(content: RealityViewCameraContent) {
    let models = viewModel.updatedMatrixData?.cardInfoModels ?? []
    for carInfoModel in models {
      guard !carInfoModel.cardName.isEmpty else { continue }
      let name = carInfoModel.cardName
      let isCardRotated = carInfoModel.isRotated
      let isCardDeleted = carInfoModel.isDeleted

      guard let cardName = viewModel.separateCardAndPhoto(from: name)?.0,
        let photoName = viewModel.separateCardAndPhoto(from: name)?.1
      else { continue }

      for entity in content.entities {
        guard
          let card = entity.children.first(where: {
            (viewModel.separateCardAndPhoto(from: $0.name)?.0 ?? "") == cardName
          }) as? ModelEntity
        else { continue }

        if let cardPhotoName = viewModel.separateCardAndPhoto(from: card.name)?.1,
          cardPhotoName != photoName
        {

          card.name = cardName + photoName
          let mesh =
            card.model?.mesh
            ?? MeshResource.generateBox(
              width: 0,
              height: 0,
              depth: 0,
              cornerRadius: 0,
              splitFaces: true
            )
          setupCardImages(card: card, mesh: mesh)
        }

        // TODO: - Rotation

        guard
          let index = viewModel.threadSafeCardModels.firstIndex(where: { $0.card.name == card.name }
          )
        else { continue }

        if viewModel.threadSafeCardModels[index].isRotated != isCardRotated {
          viewModel.threadSafeCardModels[index].isRotated = isCardDeleted

          let rotationValue = simd_quatf(angle: isCardRotated ? .pi : -2 * .pi, axis: [0, 1, 0])
          card.rotateAnimation(with: rotationValue, duration: 2) { /*[weak self] in*/
            //            guard let self else { return }
            //            deleteSameCards(content: content)
          }
        }
        DispatchQueue.main.async { /*[weak self] in*/
          //      guard let self else { return }
          viewModel.updatedMatrixData = nil
          //          viewModel.isMyTurn = true
        }
      }
    }
  }

  private func drawGestures(content: RealityViewCameraContent) {
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

  private func cardSelected(content: RealityViewCameraContent, entity: ModelEntity) {
    if let index = viewModel.threadSafeCardModels.firstIndex(where: {
      $0.card.name == entity.name
    }) {
      flipCardBack(content: content)
      viewModel.threadSafeCardModels[index].isRotated.toggle()
      let isRotated = viewModel.threadSafeCardModels[index].isRotated

      viewModel.sendMatrixData(manager: manager)

      let rotationValue = simd_quatf(angle: isRotated ? .pi : -2 * .pi, axis: [0, 1, 0])
      entity.rotateAnimation(with: rotationValue, duration: 2) { /*[weak self] in*/
        //        guard let self else { return }
        deleteSameCards(content: content)
      }
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
        firstEntity.removeFromParent()
      }
    }
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

  private func restart() {
    guard let content = viewModel.content else { return }
    content.entities.removeAll()
    viewModel.point = nil
    //    viewModel.reset()
    drawMatrix(with: viewModel.matrixType)
  }

}


extension FlipCardGameView2 {

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

}

#Preview {
  FlipCardGameView2(manager: MultipeerManager(userName: "Test"))
}
