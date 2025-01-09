//
//  FlipCardGameView.swift
//  TicTacToe
//
//  Created by Narek Aslanyan on 18.12.24.
//

import RealityKit
import SwiftUI

struct FlipCardGameView: View {

  @StateObject private var viewModel = FlipCardViewModel()
  @StateObject var manager: MultipeerManager

  var body: some View {
    content
  }

}

extension FlipCardGameView {

  private var content: some View {
    VStack(spacing: 0) {
//      winnerInfo
      RealityView { content in
        viewModel.content = content
        viewModel.drawMatrix(with: viewModel.matrixType)
        content.camera = .spatialTracking
      } update: { content in
//        if viewModel.isWin == nil {
        viewModel.contentUpdated(content: content, manager: manager)
//          DispatchQueue.main.async {
//            viewModel.checkForWinner()
//          }
//        }
      }
      .overlay {
        VStack(spacing: 0) {
          if !viewModel.isStarted {
            HStack(spacing: 0) {
              Spacer()
              startButton
                .padding(.trailing)
            }
            .frame(height: 50)
            .padding(.top, 100)
          }
          Spacer()
        }
      }
      .onTapGesture { point in
//        if viewModel.isMyTurn && manager.connectedPeers.count > 0 {
          viewModel.point = point
//        }
      }
      if !viewModel.isStarted {
        gameInfoView
      }
    }
    .edgesIgnoringSafeArea(.all)
  }
  
  private var gameInfoView: some View {
    VStack(spacing: 0) {
      peers
        .onChange(of: manager.receivedMessages) { _, newValue in
          viewModel.updateMatrixData(newValue: newValue)
        }
//        .onChange(of: manager.connectedPeers) { _, newValue in
//          if !newValue.isEmpty {
//            viewModel.sendMatrixData(manager: manager)
//          }
//        }
//        .onChange(of: viewModel.matrixType) { oldValue, newValue in
//          if oldValue != newValue {
//            viewModel.sendMatrixData(manager: manager)
//          }
//        }
      if !viewModel.isStarted {
        matrixView
      }
    }
    .gradientBackground()
    .frame(maxHeight: 200)
  }
  
  private var startButton: some View {
    Button {
      if !manager.connectedPeers.isEmpty {
        viewModel.isStarted = true
        viewModel.sendMatrixData(manager: manager)
      }
    } label: {
      Text("Start")
        .foregroundStyle(Color.white)
        .padding()
        .gradientBackground()
        .background(Color.secondary)
        .clipShape(Capsule())
        .frame(maxWidth: 100, idealHeight: 40)
    }
    .disabled(viewModel.isStarted || manager.connectedPeers.isEmpty)
  }

  private var matrixView: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Choose Size for Flip Card Game")
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal)

      Picker("", selection: $viewModel.matrixType) {
        ForEach(MatrixType.allCases, id: \.self) { matrixSize in
          Text("\(matrixSize.rawValue)x\(matrixSize.rawValue)")
            .tag(matrixSize)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding()
      Spacer()
    }
  }

}

#Preview {
  FlipCardGameView(manager: MultipeerManager(userName: "Test"))
}

extension FlipCardGameView {
  
//  @ViewBuilder
//  private var winnerInfo: some View {
//    if let isWin = viewModel.isWin {
//      HStack {
//        Spacer()
//        Text(isWin.rawValue)
//          .font(.title)
//          .foregroundColor(isWin == .win ? .green : viewModel.isWin == .draw ? .blue : .red)
//          .padding()
//        Spacer()
//        Button("Restart") {
//          // Restart
//        }
//        .padding(4)
//        .background(Color.yellow)
//        .padding(6)
//      }
//    }
//  }
  
  private var peers: some View {
    AvailablePeersView(peerManager: manager)
  }

}
