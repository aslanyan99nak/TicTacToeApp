//
//  TictacToeViewModel.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/20/24.
//

import Foundation
import SwiftUI
import RealityKit

final class TictacToeViewModel: ObservableObject {
  
  @Published var turn: Turn = .X
  @Published var selectedCelles: [String] = []
  @Published var selectedPositions: [Positions : Turn] = [:]
  @Published var updatedState: GameState? = nil
  @Published var isMyTurn: Bool = true
  @Published var iswin: Winner? = nil
  
  func checkForWinner() {
    Positions.winingPosition.forEach { positions in
      if selectedPositions.keys.contains(positions[0]) &&
          selectedPositions.keys.contains(positions[1]) &&
          selectedPositions.keys.contains(positions[2]) {
        if selectedPositions[positions[0]] == selectedPositions[positions[1]] && selectedPositions[positions[1]] == selectedPositions[positions[2]] {
          if selectedPositions[positions[0]] == Turn.X {
            iswin = .win
          } else {
            iswin = .lose
          }
        }
      }
    }
    if selectedPositions.count == 9 && iswin == nil {
      iswin = .draw
    }
  }
  
  func update(ent: ModelEntity) {
    updatedState = nil
    selectedCelles.append("\(ent.name) \(turn.rawValue)")
    selectedPositions[(Positions(rawValue: ent.name)!)] = turn
    turn = turn.other
    isMyTurn = true
  }
  
  func reset() {
    selectedCelles.removeAll()
    selectedPositions.removeAll()
    iswin = nil
    updatedState = nil
  }
  
}