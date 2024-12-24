//
//  TicTacToeVisionApp.swift
//  TicTacToeVision
//
//  Created by Narek Aslanyan on 18.12.24.
//

import SwiftUI

@main
struct TicTacToeApp: App {

  @Environment(\.openImmersiveSpace) var openImmersiveSpace

  var body: some Scene {
    #if os(visionOS)
      ImmersiveSpace(id: "Immersive") {
        CardGameView()
      }
    #endif
  }

}
