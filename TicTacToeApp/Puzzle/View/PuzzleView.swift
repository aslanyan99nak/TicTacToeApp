//
//  PuzzleView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/24/24.
//

import SwiftUI
import RealityKit
import PhotosUI

struct PuzzleView: View {
  
  @StateObject var viewModel: PuzzleViewModel
  
  var body: some View {
    VStack(spacing: 0) {
      realityView
      puzzle
        .frame(maxHeight: 250)
    }
  }
  
}

extension  PuzzleView {
  
  @ViewBuilder
  private var puzzle: some View {
    if viewModel.puzzleParts.isEmpty {
      pickersView
    } else {
      puzzlePartView
    }
  }
  
  private var puzzlePartView: some View {
    VStack {
      Text(viewModel.puzzleState)
      .customButtonStyle()
      .padding(.horizontal)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(0..<viewModel.puzzleParts.count, id: \.self) { index in
            Button {
              viewModel.adjustImage(uiImage: viewModel.puzzleParts[index],index: index)
            } label: {
              Image(uiImage: viewModel.puzzleParts[index])
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .padding(8)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
      }
      .padding(.horizontal, 10)
    }
    .gradientBackground()
  }
  
  private var pickersView : some View {
    VStack(spacing: 40) {
      PhotosPicker(selection: $viewModel.puzzleItem, matching: .images) {
        Text("Select Puzzle")
          .customButtonStyle()
      }
      
      VStack(alignment: .leading, spacing: 10) {
        Text("Choose Puzzle Size")
          .font(.headline)
          .foregroundColor(.white)
          .padding(.horizontal)
        
        Picker("", selection: $viewModel.skeletonSize) {
          ForEach(SkeletonSize.allCases, id: \.self) { skeletonSize in
            Text("\(skeletonSize.rawValue)x\(skeletonSize.rawValue)")
              .tag(skeletonSize)
          }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.2))
        )
        .padding(.horizontal)
      }
    }
    .padding()
    .gradientBackground()
  }
  
  private var realityView: some View {
    RealityView { content in
      viewModel.content = content
      viewModel.drawSkeleton(with: viewModel.skeletonSize)
      content.camera = .spatialTracking
    } update: { content in
      viewModel.selectPieceOn(content: content)
    }
    .onTapGesture { point in
      viewModel.point = point
    }
  }
  
}

#Preview {
  PuzzleView(viewModel: PuzzleViewModel())
}
