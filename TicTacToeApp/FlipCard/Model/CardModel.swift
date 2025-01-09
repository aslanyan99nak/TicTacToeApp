//
//  CardModel.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 20.12.24.
//

import RealityKit
import SwiftUI

struct CardModel: Sendable {

  var card: ModelEntity
  var isRotated: Bool

}

extension ModelEntity: Sendable {}

extension Bool: Sendable {}

