//
//  UserNameView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/23/24.
//

import SwiftUI

struct UserNameView: View {
  
  enum GameType {
    
    case ticTicToe
    case flipCard
    
  }
  
  @State var name: String = ""
  @State var canNavigate: Bool = false
  var gameType: GameType = .ticTicToe
  
  var body: some View {
    NavigationStack {
      VStack {
        Spacer()
        Text("Welcome!")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.white)
        Spacer()
        TextField("Enter your name", text: $name)
          .padding()
          .background(Color.white.opacity(0.2))
          .cornerRadius(10)
          .foregroundColor(.white)
          .padding(.horizontal, 20)
          .font(.system(size: 18))
        Spacer()
        Button(action: {
          canNavigate = true
        }) {
          Text("Start")
            .font(.headline)
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(name.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
        .disabled(name.isEmpty)
        .padding(.bottom, 40)
      }
      .padding(0)
      .background(LinearGradient(
        gradient: Gradient(colors: [Color.blue, Color.purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ))
      .navigationDestination(isPresented: $canNavigate) {
        switch gameType {
        case .ticTicToe: TicTacToeView(manager: MultipeerManager(userName: name))
        case .flipCard: FlipCardGameView(manager: MultipeerManager(userName: name))
        }
      }
    }
  }
  
}

#Preview {
  UserNameView()
}
