//
//  GameState.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//

import Foundation
import MultipeerConnectivity

struct GameState: Codable {
  
  let turnOwner: String
  let turn: String
  let boardState: [String : String]
  
}
