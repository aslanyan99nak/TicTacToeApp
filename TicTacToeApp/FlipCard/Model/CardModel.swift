//
//  CardModel.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 20.12.24.
//

import RealityKit
import SwiftUI

struct CardModel {

  var card: ModelEntity
  var isRotated: Bool = false
  var isDeleted: Bool = false

}

extension ModelEntity: Sendable {}

extension Bool: Sendable {}

