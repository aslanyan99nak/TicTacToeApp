//
//  WinnerInfoView.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 14.01.25.
//

import SwiftUI

struct WinnerInfoView: View {

  let title: String
  var restartAction: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      Text(title)
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .padding()

      Spacer()

      Button {
        restartAction()
      } label: {
        Text("Restart")
          .font(.title)
          .padding(.vertical, 8)
          .padding(.horizontal, 16)
          .background(Color.yellow)
          .clipShape(Capsule())
      }

      Spacer()
    }
    .padding()
    .gradientBackground()
    .background(.purple.opacity(0.5))
    .frame(height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 24)
  }

}
