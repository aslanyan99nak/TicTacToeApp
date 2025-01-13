//
//  FlipCardGameViewModel2.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 10.01.25.
//

import SwiftUI
import RealityKit

@MainActor
final class FlipCardGameViewModel2: ObservableObject, Sendable {

  @Synchronized var threadSafeCardModels: [CardModel] = []
  @Published var imageNames: [String] = []
  @Published var matrixType: MatrixType = .x4
  @Published var width: Float = 0.5
  @Published var height: Float = 0.5
  @Published var spacing: Float = 0.01
  @Published var updatedMatrixData: MatrixModel? = nil
  @Published var content: RealityViewCameraContent? = nil
  @Published var point: CGPoint? = nil

  func prepareUpdateData(matrixData: MatrixModel) -> Data? {
    guard let data = try? JSONEncoder().encode(matrixData) else { return nil }
    updatedMatrixData = nil
    return data
  }

  func randomImageName() -> String {
    let imageName = imageNames.randomElement() ?? "photo1"
    if let index = imageNames.firstIndex(of: imageName) {
      imageNames.remove(at: index)
    }
    return imageName
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

  private func matrixRowColumn(for index: Int, in gridSize: Int) -> (Int, Int) {
    guard index >= 0 && index < gridSize * gridSize else {
      fatalError("Index out of bounds for the given grid size")
    }
    let row = Int(index / gridSize)
    let column = Int(index - (row * gridSize))

    return (row, column)
  }

  private func calculatePosition(
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

  func getImageNames(for matrixType: MatrixType) -> [String] {
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

  func updateMatrixData(newValue: Data) {
    guard let matrixData = try? JSONDecoder().decode(MatrixModel.self, from: newValue) else {
      return
    }
    updatedMatrixData = matrixData
  }
  
  func sendMatrixData(manager: MultipeerManager) {
    var cardInfoModels: [CardInfoModel] = []
    threadSafeCardModels.forEach { cardModel in
      let cardName = cardModel.card.name
      let isRotated = cardModel.isRotated

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

  
}
