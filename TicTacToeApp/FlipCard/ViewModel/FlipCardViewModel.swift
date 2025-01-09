//
//  FlipCardViewModel.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 19.12.24.
//

import Combine
import RealityKit
import SwiftUI

@MainActor
final class FlipCardViewModel: ObservableObject, Sendable {

  @Synchronized var threadSafeCardModels: [CardModel] = []
  @Published var content: RealityViewCameraContent? = nil
  @Published var point: CGPoint? = nil
  @Published var width: Float = 0.5
  @Published var height: Float = 0.5
  @Published var spacing: Float = 0.01
  @Published var matrixType: MatrixType = .x4
  @Published var imageNames: [String] = []
//  @Published var cardNames: [String] = []
  @Published var updatedMatrixData: MatrixModel? = nil
  @Published var isMyTurn: Bool = true
  @Published var selectedCardModels: [CardModel] = []
  @Published var isStarted: Bool = false
  @Published var updateCount: Int = 0
  
//  var manager: MultipeerManager?

  private var cancellables = Set<AnyCancellable>()

  init() {
    listenMatrixSizeChanges()
  }

  func matrixRowColumn(for index: Int, in gridSize: Int) -> (Int, Int) {
    guard index >= 0 && index < gridSize * gridSize else {
      fatalError("Index out of bounds for the given grid size")
    }
    let row = Int(index / gridSize)
    let column = Int(index - (row * gridSize))

    return (row, column)
  }

  func calculatePosition(
    row: Int,
    column: Int,
    modelHeight: Float = 0.1,
    modelWidth: Float = 0.1,
    spacing: Float = 0.01
  ) -> (Float, Float) {
    let horizontalOffset: Float = (modelWidth + spacing) * Float(column)
    let verticalOffset: Float = (modelHeight + spacing) * Float(row)
    return (horizontalOffset, verticalOffset)
  }

  func getCardPosition(
    index: Int,
    matrixType: MatrixType,
    spacing: Float = 0.01,
    width: Float = 0.1,
    height: Float = 0.1
  ) -> SIMD3<Float> {
    let (row, column) = matrixRowColumn(
      for: index,
      in: matrixType.rawValue
    )
    let (postitionX, positionY) = calculatePosition(
      row: row,
      column: column,
      modelHeight: width,
      modelWidth: height,
      spacing: spacing
    )

    return .init(x: postitionX, y: positionY, z: 0.01)
  }

  private func listenMatrixSizeChanges() {
    $matrixType
      .sink { [weak self] matrixSize in
        guard let self, let content else { return }
        content.entities.removeAll()
        point = nil
        imageNames = []
//        cardNames = []
        //        updatedMatrixData = nil
        threadSafeCardModels.removeAll()
        drawMatrix(with: matrixSize)
      }
      .store(in: &cancellables)
  }

  func drawMatrix(with matrixType: MatrixType) {
    let modelEntity = create3DCards(
      matrixType: matrixType,
      width: width,
      height: height,
      spacing: spacing
    )
    content?.add(modelEntity)
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
    card.name = "card\(index)\(frontImageName)"
//    cardNames.append(card.name)
    setupCardImages(card: card, mesh: mesh)
    let position = getCardPosition(
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
    guard let frontImageName = separateCardAndPhoto(from: card.name)?.1 else { return }
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

  private func randomImageName() -> String {
    let imageName = imageNames.randomElement() ?? "photo1"
    if let index = imageNames.firstIndex(of: imageName) {
      imageNames.remove(at: index)
    }
    return imageName
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

    imageNames = getImageNames(for: matrixType).shuffled()

    for index in 0..<gridSize * gridSize {
      let model = createCard(
        matrixType: matrixType,
        planeWidth: planeWidth,
        planeHeight: planeHeight,
        spacing: spacing,
        index: index
      )
      let cardModel = CardModel(card: model, isRotated: false)
      threadSafeCardModels.append(cardModel)
      parentEntity.addChild(model)
    }
    return parentEntity
  }

  func contentUpdated(content: RealityViewCameraContent, manager: MultipeerManager) {
    if updatedMatrixData != nil {
      drawUpdates(content: content)
      return
    } else if isMyTurn {
      drawGestures(content: content, manager: manager)
      return
    }
  }

  private func drawUpdates(content: RealityViewCameraContent) {
//    guard updateCount < 2 else { return }
    let models = updatedMatrixData?.cardInfoModels ?? []
    for carInfoModel in models {
      guard !carInfoModel.cardName.isEmpty else { continue }
      let name = carInfoModel.cardName
      let isCardRotated = carInfoModel.isRotated
      let isCardDeleted = carInfoModel.isDeleted

      guard let cardName = separateCardAndPhoto(from: name)?.0,
            let photoName = separateCardAndPhoto(from: name)?.1
      else { continue }

      for entity in content.entities {
        guard
          let card = entity.children.first(where: {
            (separateCardAndPhoto(from: $0.name)?.0 ?? "") == cardName
          }) as? ModelEntity
        else { continue }
        
        if let cardPhotoName = separateCardAndPhoto(from: card.name)?.1,
           cardPhotoName != photoName {
          
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
        
        if isCardRotated {
          let rotationValue = simd_quatf(angle: isCardRotated ? .pi : -2 * .pi, axis: [0, 1, 0])
          card.rotateAnimation(with: rotationValue, duration: 2) { [weak self] in
            guard let self else { return }
//            deleteSameCards(content: content)
          }
        }
      }
    }
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      updatedMatrixData = nil
      isMyTurn = true
    }
  }

  func separateCardAndPhoto(from input: String) -> (card: String, photo: String)? {
    let pattern = "(card\\d+)(photo\\d+)"

    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return nil
    }

    let range = NSRange(input.startIndex..<input.endIndex, in: input)
    if let match = regex.firstMatch(in: input, options: [], range: range) {
      let cardRange = Range(match.range(at: 1), in: input)
      let photoRange = Range(match.range(at: 2), in: input)

      if let card = cardRange.map({ String(input[$0]) }),
        let photo = photoRange.map({ String(input[$0]) })
      {
        return (card, photo)
      }
    }
    return nil
  }

  private func drawGestures(content: RealityViewCameraContent, manager: MultipeerManager) {
    guard let point else {
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

      cardSelected(content: content, entity: entity, manager: manager)
    }
  }

  private func cardSelected(content: RealityViewCameraContent, entity: ModelEntity, manager: MultipeerManager) {
    if let index = threadSafeCardModels.firstIndex(where: {
      $0.card.name == entity.name
    }) {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if threadSafeCardModels.count(where: { $0.isRotated }) > 1 {
          isMyTurn.toggle()
        }
      }

      flipCardBack(content: content)
      threadSafeCardModels[index].isRotated.toggle()
      let isRotated = threadSafeCardModels[index].isRotated
      
      sendMatrixData(manager: manager)

      let rotationValue = simd_quatf(angle: isRotated ? .pi : -2 * .pi, axis: [0, 1, 0])
      entity.rotateAnimation(with: rotationValue, duration: 2) { [weak self] in
        guard let self else { return }
        deleteSameCards(content: content)
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
    guard threadSafeCardModels.count(where: { $0.isRotated }) > 1 else { return }

    for index in 0..<threadSafeCardModels.count {
      if threadSafeCardModels[index].isRotated {
        threadSafeCardModels[index].isRotated = false
        let name = threadSafeCardModels[index].card.name
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
    guard threadSafeCardModels.count(where: { $0.isRotated }) > 1 else { return }
    let cards = threadSafeCardModels.filter { $0.isRotated }.map { $0.card }
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

  private func getImageNames(for matrixType: MatrixType) -> [String] {
    let imageCount = matrixType.rawValue * matrixType.rawValue

    if imageCount <= 8 {
      return getAvailableImageNames(for: matrixType)
    } else {
      return getMoreThanAvailableImageNames(for: matrixType)
    }
  }

  private func getAvailableImageNames(for matrixType: MatrixType) -> [String] {
    let imageCount = matrixType.rawValue * matrixType.rawValue
    var imageNames: [String] = []

    for index in 1..<9 {
      let imageName = "photo\(index)"
      imageNames += [imageName, imageName]
      if imageNames.count == imageCount {
        return imageNames
      }
    }
    return []
  }

  private func getMoreThanAvailableImageNames(for matrixType: MatrixType) -> [String] {
    let imageCount = matrixType.rawValue * matrixType.rawValue
    var imageNames: [String] = []

    for index in 1..<9 {
      let imageName = "photo\(index)"
      imageNames += [imageName, imageName]
    }
    var index = 0

    while imageNames.count < imageCount {
      let imageName = imageNames[index]
      imageNames += [imageName, imageName]
      index += 1
    }
    return imageNames
  }

  func sendMatrixData(manager: MultipeerManager) {
//    updateCount += 1
    var cardInfoModels: [CardInfoModel] = []
    threadSafeCardModels.forEach { cardModel in // cardName in
      let cardName = cardModel.card.name
      let isRotated = cardModel.isRotated
//      let isRotated = threadSafeCardModels.first(where: { $0.card.name == cardName })?.isRotated ?? false
      
      let cardInfoModel = CardInfoModel(
        cardName: cardName,
        isRotated: isRotated,
        isDeleted: false
      )
      cardInfoModels.append(cardInfoModel)
    }

    let matrixData = MatrixModel(matrixType: matrixType, cardInfoModels: cardInfoModels)

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      guard let data = prepareUpdateData(matrixData: matrixData) else { return }
      do {
        try manager.session.send(data, toPeers: manager.connectedPeers, with: .reliable)
      } catch {
        print("Can't send data to connected device Error: \(error.localizedDescription)")
      }
      point = nil
    }
  }

  func prepareUpdateData(matrixData: MatrixModel) -> Data? {
    guard let data = try? JSONEncoder().encode(matrixData) else { return nil }
    updatedMatrixData = nil
    isMyTurn = false
    return data
  }

  func updateMatrixData(newValue: Data) {
    guard let matrixData = try? JSONDecoder().decode(MatrixModel.self, from: newValue) else {
      return
    }
    updatedMatrixData = matrixData
    isStarted = true
    //    matrixType = matrixData.matrixType
  }

}
