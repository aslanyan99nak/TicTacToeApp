//
//  CustomButtonStyle.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/25/24.
//


import SwiftUI

struct CustomButtonStyle: ViewModifier {
  
  func body(content: Content) -> some View {
    content
      .font(.headline)
      .fontWeight(.bold)
      .padding()
      .frame(maxWidth: .infinity)
      .background(
        LinearGradient(
          gradient: Gradient(colors: [Color.green, Color.blue]),
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .foregroundColor(.white)
      .cornerRadius(12)
      .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
      .scaleEffect(1.05)
  }
  
}

struct GradientBackgroundModifier: ViewModifier {
  
  func body(content: Content) -> some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [Color.cyan.opacity(0.4), Color.indigo.opacity(0.6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
      
      content
    }
  }
  
}

extension View {
  
  func customButtonStyle() -> some View {
    self.modifier(CustomButtonStyle())
  }
  func gradientBackground() -> some View {
    self.modifier(GradientBackgroundModifier())
  }
  
}

