//
//  Turn.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/19/24.
//

import Foundation

enum Turn: String {
  
  case X = "X"
  case O = "O"
  
  var other: Turn {
    switch self {
    case .X: return .O
    case .O: return .X
    }
  }
  
}
