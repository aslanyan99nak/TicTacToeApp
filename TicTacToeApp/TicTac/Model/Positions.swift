//
//  Positions.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/19/24.
//


enum Positions: String {
  
  case topLeft = "20"
  case topMiddle = "21"
  case topRight = "22"
  case middleLeft = "10"
  case middleMiddle = "11"
  case middleRight = "12"
  case bottomLeft = "00"
  case bottomMiddle = "01"
  case bottomRight = "02"
  
  static var winingPosition: [[Positions]] {
    [
      [.topLeft, .topMiddle, .topRight],
      [.middleLeft, .middleMiddle, .middleRight],
      [.bottomLeft, .bottomMiddle, .bottomRight],
      [.topLeft, .middleLeft, .bottomLeft],
      [.topMiddle, .middleMiddle, .bottomMiddle],
      [.topRight, .middleRight, .bottomRight],
      [.topRight, .middleMiddle, .bottomLeft],
      [.topLeft, .middleMiddle, .middleRight],
    ]
  }
  
}
