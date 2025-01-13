//
//  MatrixType.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 08.01.25.
//

import Foundation

enum MatrixType: Int, Codable, CaseIterable {

  case x2 = 2
  case x4 = 4
  case x6 = 6

}

struct MatrixModel: Codable, Equatable {
  
  static func == (lhs: MatrixModel, rhs: MatrixModel) -> Bool {
    lhs.matrixType == rhs.matrixType && lhs.cardInfoModels == rhs.cardInfoModels
  }
  
  var matrixType: MatrixType
  var cardInfoModels: [CardInfoModel]
  
}

struct CardInfoModel: Codable, Equatable {
  
  let cardName: String
  var isRotated: Bool
  var isDeleted: Bool
  
}
