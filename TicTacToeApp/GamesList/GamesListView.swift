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
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [Color.cyan.opacity(0.4), Color.indigo.opacity(0.6)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 30) {
          Text("Select a Game")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.bottom, 40)
          
          NavigationLink(destination: UserNameView()) {
            gameButton(label: "Tic Tac Toe", systemImage: "circle.grid.cross")
          }
          
          NavigationLink(destination: CardGameView()) {
            gameButton(label: "Flip Card", systemImage: "rectangle.3.group.fill")
          }
          
          Spacer()
        }
        .padding()
      }
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
    .padding()
    .frame(maxWidth: .infinity)
    .background(LinearGradient(
      gradient: Gradient(colors: [Color.blue, Color.purple]),
      startPoint: .leading,
      endPoint: .trailing
    ))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
  }
}

#Preview {
  GamesListView()
}
