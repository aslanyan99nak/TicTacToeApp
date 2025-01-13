//
//  GameState.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//

import Foundation

struct GameState: Codable {

  let turn: String
  let boardState: [String: String]

}
