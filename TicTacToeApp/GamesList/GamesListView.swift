//
//  GamesListView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/24/24.
//

import SwiftUI

struct GamesListView: View {
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 30) {
        Text("Select a Game")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.bottom, 40)
        
        NavigationLink(destination: UserNameView()) {
          gameButton(label: "Tic Tac Toe", systemImage: "circle.grid.cross")
        }
        
        NavigationLink(destination: FlipCardGameView()) {
          gameButton(label: "Flip Card", systemImage: "rectangle.3.group.fill")
        }
        
        NavigationLink(destination: PuzzleView(viewModel: PuzzleViewModel())) {
          gameButton(label: "Puzzle", systemImage: "rectangle.3.group.fill")
        }
        
        Spacer()
      }
      .padding()
      .gradientBackground()
    }
  }
  
  private func gameButton(label: String, systemImage: String) -> some View {
    HStack {
      Image(systemName: systemImage)
        .foregroundColor(.white)
        .frame(width: 40, height: 40)
        .background(Color.blue.opacity(0.8))
        .clipShape(Circle())
      
      Text(label)
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
      
      Spacer()
    }
    .customButtonStyle()
  }
  
}

#Preview {
  GamesListView()
}
