//
//  CarGameViewModel.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 19.12.24.
//

import SwiftUI

@Observable
class CarGameViewModel {

  var point: CGPoint? = nil
  var width: Float = 0.5
  var height: Float = 0.5
  var spacing: Float = 0.01
  var matrixType: CardGameView.MatrixType = .sixTeen
  var cardModels: [CardModel] = []
  
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
    matrixType: CardGameView.MatrixType,
    spacing: Float = 0.01,
    width: Float = 0.1,
    height: Float = 0.1
  ) -> SIMD3<Float> {
    let gridSize = Int(sqrt(Double(matrixType.rawValue)))
    let (row, column) = matrixRowColumn(
      for: index,
      in: gridSize
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

}
