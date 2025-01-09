//
//  AvailablePeersView.swift
//  TicTacToe
//
//  Created by Mekhak Ghapantsyan on 12/18/24.
//

import SwiftUI

struct AvailablePeersView: View {

  @StateObject var peerManager: MultipeerManager

  var body: some View {
    ZStack {
      if peerManager.availablePeers.isEmpty {
        emptyState
      } else {
        if peerManager.connectedPeers.isEmpty {
          peersList
        } else {
          connectedState
        }
      }
    }
    .alert(
      "Received an invite from \($peerManager.invitationSender.wrappedValue?.displayName ?? "Device")!",
      isPresented: $peerManager.didReciveInvite
    ) {
      Button("Accept") {
        peerManager.invitationHandler?(true, peerManager.session)
      }
      .foregroundColor(.white)
      .padding()
      .background(Color.green)
      .cornerRadius(10)

      Button("Reject") {
        peerManager.invitationHandler?(false, nil)
      }
      .foregroundColor(.white)
      .padding()
      .background(Color.red)
      .cornerRadius(10)
    }
  }

}

extension AvailablePeersView {

  private var peersList: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        ForEach(peerManager.availablePeers, id: \.self) { peer in
          Button {
            peerManager.browser.invitePeer(
              peer, to: peerManager.session, withContext: nil, timeout: 30
            )
          } label: {
            HStack {
              Image(systemName: "person.fill")
                .foregroundColor(.blue)
              
              Text(peer.displayName)
                .font(.headline)
                .foregroundColor(.primary)
              
              Spacer()
              
              Image(systemName: "paperplane.fill")
                .foregroundColor(.green)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(8)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
    }
  }

  private var emptyState: some View {
    HStack(spacing: 4) {
      Image(systemName: "wave.3.left.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
        .foregroundColor(.blue.opacity(0.7))
        .padding()

      Text("No peers available")
        .font(.body)
        .foregroundColor(.secondary)
    }
  }

  private var connectedState: some View {
    HStack {
      Image(systemName: "checkmark.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
        .foregroundColor(.green)
        .padding()

      Text(
        "Successfully connected to \(peerManager.connectedPeers.first?.displayName ?? "a device")"
      )
      .font(.body)
      .foregroundColor(.primary)
      .padding(.trailing)

      Spacer()
    }
  }

}

#Preview {
  AvailablePeersView(peerManager: MultipeerManager(userName: "Test"))
}
